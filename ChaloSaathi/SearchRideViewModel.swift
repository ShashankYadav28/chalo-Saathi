import FirebaseFirestore
import FirebaseFirestoreCombineSwift

class SearchRideViewModel: ObservableObject {
    @Published var rides: [Ride] = []
    @Published var isLoading = false
    @Published var selectedRide: Ride? = nil
    @Published var errorMessage: String? = nil

    private var pendingSearchWorkItem: DispatchWorkItem?
    
    enum SearchResult {
        case success(Ride)
        case noResults
        case failure(String)
    }

    private let db = Firestore.firestore()
    
    func searchRides(
        from: String,
        to: String,
        date: Date,
        currentUserGender: String,
        completion: @escaping (SearchResult) -> Void
    ) {
        pendingSearchWorkItem?.cancel()
        isLoading = true
        rides.removeAll()
        errorMessage = nil
        selectedRide = nil
        
        let trimmedFrom = from.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTo = to.trimmingCharacters(in: .whitespacesAndNewlines)
        
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
                
                var fetchedRides = docs.compactMap { doc -> Ride? in
                    do {
                        let ride = try doc.data(as: Ride.self)
                        print("📄 Decoded ride: \(ride.fromAddress) → \(ride.toAddress)")
                        return ride
                    } catch {
                        print("❌ Failed to decode ride: \(error)")
                        return nil
                    }
                }
                
                print("📦 Firestore returned \(fetchedRides.count) rides total")
                
                // Normalize text for fuzzy matching
                func normalize(_ str: String) -> String {
                    return str
                        .lowercased()
                        .replacingOccurrences(of: " ", with: "")
                        .replacingOccurrences(of: ",", with: "")
                        .replacingOccurrences(of: ".", with: "")
                }
                
                let fromNorm = normalize(trimmedFrom)
                let toNorm = normalize(trimmedTo)
                
                print("🔍 Normalized search: '\(fromNorm)' → '\(toNorm)'")
                
                fetchedRides = fetchedRides.filter { ride in
                    let rideFrom = normalize(ride.fromAddress)
                    let rideTo = normalize(ride.toAddress)
                    
                    print("   Checking: '\(rideFrom)' → '\(rideTo)'")
                    
                    let fromMatch = rideFrom.contains(fromNorm) || fromNorm.contains(rideFrom)
                    let toMatch = rideTo.contains(toNorm) || toNorm.contains(rideTo)
                    
                    print("   From match: \(fromMatch), To match: \(toMatch)")
                    
                    // ⭐ FIXED: Proper gender filtering
                    let genderMatch: Bool
                    if currentUserGender.lowercased() == "male" {
                        // Males can only ride with male drivers
                        genderMatch = ride.driverGender.lowercased() == "male"
                    } else {
                        // Females can ride with any driver
                        genderMatch = true
                    }
                    
                    print("   Gender match: \(genderMatch) (user: \(currentUserGender), driver: \(ride.driverGender))")
                    
                    return fromMatch && toMatch && genderMatch
                }
                
                print("🎯 After location & gender filtering: \(fetchedRides.count) rides")
                
                // ⭐ FIXED: Date filtering
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
                        print("✅ Found ride from \(ride.fromAddress) → \(ride.toAddress)")
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
}
