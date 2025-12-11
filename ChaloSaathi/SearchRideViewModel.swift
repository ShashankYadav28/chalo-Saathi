// SearchRideViewModel.swift
import Foundation
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import CoreLocation

class SearchRideViewModel: ObservableObject {
    @Published var rides: [Ride] = []
    @Published var isLoading = false
    @Published var selectedRide: Ride? = nil
    @Published var errorMessage: String? = nil

    private var pendingSearchWorkItem: DispatchWorkItem?
    enum SearchResult { case success(Ride); case noResults; case failure(String) }

    private let db = Firestore.firestore()

    /// Main search function
    func searchRides(
        from: String,
        to: String,
        date: Date,
        currentUserGender: String,
        fromCoord: CLLocationCoordinate2D?,
        toCoord: CLLocationCoordinate2D?,
        completion: @escaping (SearchResult) -> Void
    ) {
        pendingSearchWorkItem?.cancel()
        isLoading = true
        rides.removeAll()
        errorMessage = nil
        selectedRide = nil

        let trimmedFrom = from.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTo   = to.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedFrom.count >= 3, trimmedTo.count >= 3 else {
            DispatchQueue.main.async {
                self.isLoading = false
                completion(.noResults)
            }
            print("⏸️ Skipping search — input too short.")
            return
        }

        print("🚀 Searching rides for from: \(trimmedFrom), to: \(trimmedTo), gender: \(currentUserGender)")

        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }

            self.db.collection("rides").getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Firestore query failed: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.errorMessage = error.localizedDescription
                        completion(.failure(error.localizedDescription))
                    }
                    return
                }

                guard let docs = snapshot?.documents else {
                    print("⚠️ No documents found in 'rides'")
                    DispatchQueue.main.async {
                        self.isLoading = false
                        completion(.noResults)
                    }
                    return
                }

                // decode and ensure id is present
                var fetchedRides: [Ride] = docs.compactMap { doc in
                    do {
                        var ride = try doc.data(as: Ride.self)
                        if ride.id == nil || ride.id?.isEmpty == true {
                            ride.id = doc.documentID
                        }
                        return ride
                    } catch {
                        print("❌ Failed to decode ride doc \(doc.documentID): \(error)")
                        return nil
                    }
                }

                print("📦 Firestore returned \(fetchedRides.count) rides total")

                // gender helper
                func genderMatches(_ ride: Ride) -> Bool {
                    let user   = currentUserGender.lowercased()
                    let driver = ride.driverGender.lowercased()
                    let prefs  = ride.genderPreference.map { $0.lowercased() }

                    let preferenceAllows = prefs.contains("all") || prefs.contains(user)

                    // Extra rule: if user is male, require male driver (as you previously used)
                    if user == "male" {
                        return driver == "male" && preferenceAllows
                    } else {
                        return preferenceAllows
                    }
                }

                // normalize helper for fallback text matching
                func normalize(_ str: String) -> String {
                    return str
                        .lowercased()
                        .replacingOccurrences(of: " ", with: "")
                        .replacingOccurrences(of: ",", with: "")
                        .replacingOccurrences(of: ".", with: "")
                }

                // 1) If we have coordinates → do radius + gender filtering
                if let userFromCoord = fromCoord, let userToCoord = toCoord {
                    let radii = self.dynamicRadii(from: userFromCoord, to: userToCoord)
                    let pickupRadiusKm = radii.pickupKm
                    let dropRadiusKm   = radii.dropKm

                    print("📏 User trip-based radii → pickup=\(pickupRadiusKm) km, drop=\(dropRadiusKm) km")

                    fetchedRides = fetchedRides.filter { ride in
                        let gMatch = genderMatches(ride)
                        let radiusMatch = self.isRideWithinRadius(
                            ride: ride,
                            from: userFromCoord,
                            to: userToCoord,
                            pickupRadiusKm: pickupRadiusKm,
                            dropRadiusKm: dropRadiusKm
                        )
                        print("   ▶︎ ride \(ride.id ?? "nil"): gender=\(gMatch), radius=\(radiusMatch)")
                        return gMatch && radiusMatch
                    }

                    print("📍 After gender + radius filtering: \(fetchedRides.count) rides")
                } else {
                    // 2) Fallback: looser text-based match + gender
                    let fromNorm = normalize(trimmedFrom)
                    let toNorm   = normalize(trimmedTo)
                    print("🔍 Normalized search: '\(fromNorm)' → '\(toNorm)'")

                    fetchedRides = fetchedRides.filter { ride in
                        let rideFrom = normalize(ride.fromAddress)
                        let rideTo   = normalize(ride.toAddress)

                        let fromMatch = rideFrom.contains(fromNorm) || fromNorm.contains(rideFrom)
                        let toMatch   = rideTo.contains(toNorm) || toNorm.contains(rideTo)

                        let gMatch = genderMatches(ride)
                        print("   From match: \(fromMatch), To match: \(toMatch), gender: \(gMatch)")
                        return fromMatch && toMatch && gMatch
                    }

                    print("🎯 After text + gender filtering: \(fetchedRides.count) rides")
                }

                // Date filter (if requested)
                if date != Date.distantPast {
                    let calendar = Calendar.current
                    fetchedRides = fetchedRides.filter { ride in
                        let match = calendar.isDate(ride.date, inSameDayAs: date)
                        print("📅 Date check: ride \(ride.date) vs search \(date) = \(match)")
                        return match
                    }
                    print("📅 After date filtering: \(fetchedRides.count) rides")
                }

                DispatchQueue.main.async {
                    self.isLoading = false
                    self.rides = fetchedRides

                    if let ride = fetchedRides.first {
                        print("✅ Found ride from \(ride.fromAddress) → \(ride.toAddress) (id: \(ride.id ?? "nil"))")
                        self.selectedRide = ride
                        completion(.success(ride))
                    } else {
                        print("❌ No rides match all filters")
                        self.selectedRide = nil
                        completion(.noResults)
                    }
                }
            }
        }

        pendingSearchWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: workItem)
    }

    // dynamic radii: tuned for carpooling
    private func dynamicRadii(
        from userFrom: CLLocationCoordinate2D,
        to userTo: CLLocationCoordinate2D
    ) -> (pickupKm: Double, dropKm: Double) {
        let fromLoc = CLLocation(latitude: userFrom.latitude, longitude: userFrom.longitude)
        let toLoc   = CLLocation(latitude: userTo.latitude, longitude: userTo.longitude)
        let distanceKm = fromLoc.distance(from: toLoc) / 1000.0
        print("📏 User trip distance ≈ \(String(format: "%.1f", distanceKm)) km")

        switch distanceKm {
        case 0..<5: return (pickupKm: 1.0, dropKm: 3.0)
        case 5..<20: return (pickupKm: 2.0, dropKm: 4.0)
        case 20..<80: return (pickupKm: 3.0, dropKm: 6.0) // <-- fixed label here
        default: return (pickupKm: 5.0, dropKm: 10.0)
        }
    }

    // radius check
    private func isRideWithinRadius(
        ride: Ride,
        from userFrom: CLLocationCoordinate2D,
        to userTo: CLLocationCoordinate2D,
        pickupRadiusKm: Double,
        dropRadiusKm: Double
    ) -> Bool {
        let rideFrom = CLLocation(latitude: ride.fromLat, longitude: ride.fromLong)
        let rideTo   = CLLocation(latitude: ride.toLat,   longitude: ride.toLong)

        let userFromLoc = CLLocation(latitude: userFrom.latitude, longitude: userFrom.longitude)
        let userToLoc   = CLLocation(latitude: userTo.latitude,   longitude: userTo.longitude)

        let fromDistance = rideFrom.distance(from: userFromLoc)
        let toDistance   = rideTo.distance(from: userToLoc)

        print("   ▸ distances: from=\(Int(fromDistance)) m, to=\(Int(toDistance)) m")
        print("   ▸ allowed: pickup ≤ \(pickupRadiusKm) km, drop ≤ \(dropRadiusKm) km")

        return fromDistance <= pickupRadiusKm * 1000 &&
               toDistance   <= dropRadiusKm   * 1000
    }
}
