import SwiftUI
import MapKit
import FirebaseFirestore

struct PublishRideView: View {
    @ObservedObject var locationManager: LocationManagerRideSearch
    let currentUser: AppUser

    @State private var fromAddress: String = ""
    @State private var toAddress: String = ""
    @State private var selectedDateTime = Date()
    @State private var availableSeats = 1
    @State private var vehicleType: VehicleType = .car
    @State private var farePerKm: String = ""
    @State private var genderPreference: GenderPreference = .all
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isPublishing = false
    @State private var showDriverTracking = false
    @State private var publishedRide: Ride?
    @State private var fromCoordinate: CLLocationCoordinate2D?
    @State private var toCoordinate: CLLocationCoordinate2D?
    
    @StateObject private var fromCompleter = LocationsearchCompleter()
    @StateObject private var toCompleter = LocationsearchCompleter()
    
    @State private var activeField: SearchField? = nil
    @State private var fromFieldFrame: CGRect = .zero
    @State private var toFieldFrame: CGRect = .zero
    @State private var hasEditedFrom = false

    enum SearchField {
        case from, to
    }

    enum VehicleType: String, CaseIterable {
        case car = "Car", bike = "Bike"
        var icon: String { self == .car ? "car.fill" : "bicycle" }
    }

    enum GenderPreference: String, CaseIterable {
        case all = "All", male = "Male Only", female = "Female Only"
        var firestoreValue: [String] {
            switch self {
            case .all: return ["male", "female", "all"]
            case .male: return ["male", "all"]
            case .female: return ["female", "all"]
            }
        }
    }

    var isFormValid: Bool {
        !fromAddress.isEmpty && !toAddress.isEmpty && !farePerKm.isEmpty &&
        fromCoordinate != nil && toCoordinate != nil
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Info Banner
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 22))
                        Text("Share your route and split costs with passengers going the same way!")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // FROM Field
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Pickup Location")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.horizontal)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 22))
                            
                            Button(action: useCurrentLocation) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(.blue)
                                    .padding(8)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            
                            TextField("Enter starting location", text: $fromAddress)
                                .font(.system(size: 15))
                                .onTapGesture {
                                    activeField = .from
                                    fromCompleter.searchQuery = fromAddress
                                }
                                .onChange(of: fromAddress) { newValue in
                                    hasEditedFrom = true
                                    if activeField == .from {
                                        fromCompleter.searchQuery = newValue
                                    }
                                }
                        }
                        .padding()
                        .background(
                            GeometryReader { geo in
                                Color.clear.preference(key: FromFrameKey.self, value: geo.frame(in: .global))
                            }
                        )
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(activeField == .from ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1.5)
                        )
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        .padding(.horizontal)
                        .onPreferenceChange(FromFrameKey.self) { frame in
                            fromFieldFrame = frame
                        }
                    }
                    
                    // TO Field
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Drop-off Location")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.horizontal)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "flag.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 22))
                            
                            TextField("Enter destination", text: $toAddress)
                                .font(.system(size: 15))
                                .onTapGesture {
                                    activeField = .to
                                    toCompleter.searchQuery = toAddress
                                }
                                .onChange(of: toAddress) { newValue in
                                    if activeField == .to {
                                        toCompleter.searchQuery = newValue
                                    }
                                }
                        }
                        .padding()
                        .background(
                            GeometryReader { geo in
                                Color.clear.preference(key: ToFrameKey.self, value: geo.frame(in: .global))
                            }
                        )
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(activeField == .to ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1.5)
                        )
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        .padding(.horizontal)
                        .onPreferenceChange(ToFrameKey.self) { frame in
                            toFieldFrame = frame
                        }
                    }
                    
                    // Date & Time
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Departure Time")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.horizontal)
                        
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.orange)
                                .font(.system(size: 22))
                            
                            DatePicker("", selection: $selectedDateTime, displayedComponents: [.date, .hourAndMinute])
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding()
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        .padding(.horizontal)
                    }
                    
                    // Seats and Fare Row
                    HStack(spacing: 15) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Seats")
                                .font(.system(size: 15, weight: .semibold))
                            
                            HStack(spacing: 15) {
                                Button(action: {
                                    if availableSeats > 1 { availableSeats -= 1 }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(availableSeats > 1 ? .blue : .gray.opacity(0.5))
                                        .font(.system(size: 30))
                                }
                                .disabled(availableSeats <= 1)
                                
                                Text("\(availableSeats)")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(.primary)
                                    .frame(minWidth: 35)
                                
                                Button(action: {
                                    if availableSeats < 4 { availableSeats += 1 }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(availableSeats < 4 ? .blue : .gray.opacity(0.5))
                                        .font(.system(size: 30))
                                }
                                .disabled(availableSeats >= 4)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Fare/km")
                                .font(.system(size: 15, weight: .semibold))
                            
                            HStack(spacing: 6) {
                                Text("₹")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(.green)
                                
                                TextField("0", text: $farePerKm)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                    .padding(.horizontal)
                    
                    // Vehicle Type
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Vehicle Type")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.horizontal)
                        
                        HStack(spacing: 12) {
                            ForEach(VehicleType.allCases, id: \.self) { type in
                                Button(action: { vehicleType = type }) {
                                    VStack(spacing: 10) {
                                        Image(systemName: type.icon)
                                            .font(.system(size: 26))
                                        Text(type.rawValue)
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(vehicleType == type ? .white : .blue)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .background(vehicleType == type ? Color.blue : Color.blue.opacity(0.08))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(vehicleType == type ? Color.blue : Color.blue.opacity(0.15),
                                                    lineWidth: vehicleType == type ? 2 : 1)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Gender Preference
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Passenger Preference")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.horizontal)
                        
                        HStack(spacing: 10) {
                            ForEach(GenderPreference.allCases, id: \.self) { pref in
                                Button(action: { genderPreference = pref }) {
                                    Text(pref.rawValue)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(genderPreference == pref ? .white : .purple)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(genderPreference == pref ? Color.purple : Color.purple.opacity(0.08))
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(genderPreference == pref ? Color.purple : Color.purple.opacity(0.15),
                                                        lineWidth: genderPreference == pref ? 2 : 1)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Publish Button
                    Button(action: publishRide) {
                        HStack(spacing: 12) {
                            if isPublishing {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 18))
                            }
                            Text(isPublishing ? "Publishing Ride..." : "Publish Ride")
                                .font(.system(size: 17, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: isFormValid ? [Color.blue, Color.blue.opacity(0.85)] :
                                        [Color.gray.opacity(0.6), Color.gray.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(14)
                        .shadow(color: isFormValid ? Color.blue.opacity(0.3) : Color.clear,
                                radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .disabled(isPublishing || !isFormValid)
                    
                    if !isFormValid {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 14))
                            Text("Complete all fields to publish")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer().frame(height: 120)
                }
                .padding(.top, 20)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .onChange(of: locationManager.currentAddress) { newAddr in
                if !hasEditedFrom && !newAddr.isEmpty {
                    fromAddress = newAddr
                    fromCoordinate = locationManager.location
                }
            }
            .onAppear {
                if fromAddress.isEmpty, !locationManager.currentAddress.isEmpty {
                    fromAddress = locationManager.currentAddress
                    fromCoordinate = locationManager.location
                }
            }
            
            // Suggestions Overlay
            if (activeField == .from && !fromCompleter.searchresult.isEmpty) ||
               (activeField == .to && !toCompleter.searchresult.isEmpty) {
                
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { dismissSuggestions() }
                
                VStack(spacing: 0) {
                    if activeField == .from && !fromCompleter.searchresult.isEmpty {
                        Spacer().frame(height: fromFieldFrame.maxY + 8)
                        suggestionsList(results: fromCompleter.searchresult, isFrom: true)
                            .frame(width: fromFieldFrame.width - 40)
                            .padding(.horizontal, 20)
                        Spacer()
                    } else if activeField == .to && !toCompleter.searchresult.isEmpty {
                        Spacer().frame(height: toFieldFrame.maxY + 8)
                        suggestionsList(results: toCompleter.searchresult, isFrom: false)
                            .frame(width: toFieldFrame.width - 40)
                            .padding(.horizontal, 20)
                        Spacer()
                    }
                }
            }
        }
        .navigationDestination(isPresented: $showDriverTracking) {
            if let ride = publishedRide {
                DriverTrackingView(ride: ride, currentUser: currentUser)
            }
        }
        .alert(alertMessage, isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        }
    }
    
    // MARK: - Suggestions List
    @ViewBuilder
    private func suggestionsList(results: [MKLocalSearchCompletion], isFrom: Bool) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(results.prefix(5).enumerated()), id: \.offset) { index, result in
                Button {
                    selectLocation(result, isFrom: isFrom)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: isFrom ? "mappin.circle.fill" : "flag.fill")
                            .foregroundColor(isFrom ? .green : .blue)
                            .font(.system(size: 20))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.title)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.primary)
                            Text(result.subtitle)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray.opacity(0.5))
                            .font(.system(size: 13))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color(UIColor.systemBackground))
                }
                .buttonStyle(PlainButtonStyle())
                
                if index != results.prefix(5).count - 1 {
                    Divider().padding(.leading, 52)
                }
            }
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
    }
    
    // MARK: - Helper Functions
    
    func useCurrentLocation() {
        hasEditedFrom = false
        if !locationManager.currentAddress.isEmpty {
            fromAddress = locationManager.currentAddress
            fromCoordinate = locationManager.location
        }
        fromCompleter.searchresult.removeAll()
        dismissSuggestions()
    }
    
    func dismissSuggestions() {
        activeField = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
    
    func selectLocation(_ completion: MKLocalSearchCompletion, isFrom: Bool) {
        let completer = isFrom ? fromCompleter : toCompleter
        completer.getCoordinate(for: completion) { coordinate, address in
            DispatchQueue.main.async {
                if let coordinate = coordinate, let address = address {
                    if isFrom {
                        fromAddress = address
                        fromCoordinate = coordinate
                        hasEditedFrom = true
                    } else {
                        toAddress = address
                        toCoordinate = coordinate
                    }
                    completer.searchresult.removeAll()
                    dismissSuggestions()
                }
            }
        }
    }
    
    func publishRide() {
        if fromAddress.isEmpty, !locationManager.currentAddress.isEmpty {
            fromAddress = locationManager.currentAddress
            fromCoordinate = locationManager.location
        }
        
        guard let fromCoord = fromCoordinate, let toCoord = toCoordinate, !farePerKm.isEmpty else {
            alertMessage = "Please fill all required fields"
            showingAlert = true
            return
        }
        
        isPublishing = true
        
        let db = Firestore.firestore()
        let rideRef = db.collection("rides").document()
        let rideData: [String: Any] = [
            "id": rideRef.documentID,
            "driverId": currentUser.id ?? "",
            "driverName": currentUser.name,
            "driverPhone": currentUser.phone ?? "",
            "driverGender": currentUser.gender ?? "all",
            "fromAddress": fromAddress,
            "toAddress": toAddress,
            "fromLat": fromCoord.latitude,
            "fromLong": fromCoord.longitude,
            "toLat": toCoord.latitude,
            "toLong": toCoord.longitude,
            "date": Timestamp(date: selectedDateTime),
            "availableSeats": availableSeats,
            "vehicleType": vehicleType.rawValue,
            "farePerKm": farePerKm,
            "genderPreference": genderPreference.firestoreValue,
            "status": "active",
            "passengers": [],
            "createdAt": Timestamp(date: Date())
        ]
        
        rideRef.setData(rideData) { error in
            DispatchQueue.main.async {
                self.isPublishing = false
                if let error = error {
                    self.alertMessage = "Failed to publish ride: \(error.localizedDescription)"
                    self.showingAlert = true
                } else {
                    self.publishedRide = Ride(
                        id: rideRef.documentID,
                        driverId: currentUser.id ?? "",
                        driverName: currentUser.name,
                        driverGender: currentUser.gender ?? "all",
                        fromAddress: fromAddress,
                        fromLat: fromCoord.latitude,
                        fromLong: fromCoord.longitude,
                        toAddress: toAddress,
                        toLat: toCoord.latitude,
                        toLong: toCoord.longitude,
                        date: selectedDateTime,
                        availableSeats: availableSeats,
                        vehicleType: vehicleType.rawValue,
                        farePerKm: farePerKm,
                        genderPreference: genderPreference.firestoreValue,
                        createdAt: Date()
                    )
                    self.showDriverTracking = true
                }
            }
        }
    }
}

// PreferenceKeys
private struct FromFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

private struct ToFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

#Preview {
    PublishRideView(
        locationManager: LocationManagerRideSearch(),
        currentUser: AppUser(
            id: "preview123", name: "Test User", email: "test@example.com",
            phone: "1234567890", gender: "male"
        )
    )
}
