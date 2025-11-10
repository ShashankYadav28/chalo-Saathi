import SwiftUI
import MapKit
import FirebaseFirestore

struct PublishRideView: View {
    @ObservedObject var locationManager: LocationManagerRideSearch
    let currentUser: AppUser?

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
    
    @StateObject private var locationSearchCompleter = LocationsearchCompleter()
    @State private var showDestinationSuggestions = false
    
    enum VehicleType: String, CaseIterable {
        case car = "Car"
        case bike = "Bike"
        
        var icon: String {
            switch self {
            case .car: return "car.fill"
            case .bike: return "bicycle"
            }
        }
    }
    
    enum GenderPreference: String, CaseIterable {
        case all = "All"
        case male = "Male Only"
        case female = "Female Only"
        
        var firestoreValue: [String] {
            switch self {
            case .all: return ["male", "female", "all"]
            case .male: return ["male", "all"]
            case .female: return ["female", "all"]
            }
        }
    }
    
    var isFormValid: Bool {
        !fromAddress.isEmpty &&
        !toAddress.isEmpty &&
        !farePerKm.isEmpty &&
        fromCoordinate != nil &&
        toCoordinate != nil
    }
    
    var displayFromAddress: String {
        if !fromAddress.isEmpty {
            return fromAddress
        } else if !locationManager.currentAddress.isEmpty {
            return locationManager.currentAddress
        } else {
            return "Fetching location..."
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        locationField(
                            title: "From",
                            address: displayFromAddress,
                            icon: "mappin.circle.fill",
                            color: .red
                        )
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("To")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            TextField("Enter destination (e.g., Chennai)", text: $locationSearchCompleter.searchQuery)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.horizontal)
                                .onChange(of: locationSearchCompleter.searchQuery) { newValue in
                                    showDestinationSuggestions = !newValue.isEmpty
                                }
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Date & Time")
                                .font(.headline)
                            DatePicker("Select departure", selection: $selectedDateTime, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                        }
                        .padding(.horizontal)
                        
                        Stepper("Available Seats: \(availableSeats)", value: $availableSeats, in: 1...4)
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading) {
                            Text("Fare per km")
                                .font(.headline)
                            TextField("Enter fare (₹)", text: $farePerKm)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        .padding(.horizontal)
                        
                        VStack(alignment: .leading) {
                            Text("Vehicle Type")
                                .font(.headline)
                            Picker("Vehicle Type", selection: $vehicleType) {
                                ForEach(VehicleType.allCases, id: \.self) {
                                    Text($0.rawValue)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        .padding(.horizontal)
                        
                        VStack(alignment: .leading) {
                            Text("Gender Preference")
                                .font(.headline)
                            Picker("Gender Preference", selection: $genderPreference) {
                                ForEach(GenderPreference.allCases, id: \.self) {
                                    Text($0.rawValue)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        .padding(.horizontal)
                        
                        Button(action: publishRide) {
                            HStack {
                                if isPublishing {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                }
                                Text("Publish Ride")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Color.blue : Color.gray)
                            .cornerRadius(10)
                        }
                        .padding()
                        .disabled(isPublishing || !isFormValid)
                        
                        if !isFormValid {
                            Text("Please fill all fields and select destinations")
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 100)
                }
                
                if showDestinationSuggestions && !locationSearchCompleter.searchresult.isEmpty {
                    VStack {
                        Spacer()
                            .frame(height: 160)
                        
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(Array(locationSearchCompleter.searchresult.enumerated()), id: \.offset) { index, result in
                                    Button {
                                        selectDestination(result)
                                    } label: {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(result.title)
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.primary)
                                            Text(result.subtitle)
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                    }
                                    
                                    if index != locationSearchCompleter.searchresult.count - 1 {
                                        Divider()
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 250)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                        .padding(.horizontal, 20)
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("Publish Ride")
            .navigationDestination(isPresented: $showDriverTracking) {
                if let ride = publishedRide {
                    DriverTrackingView(ride: ride, currentUser: currentUser)
                }
            }
            .alert(alertMessage, isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            }
            .onAppear {
                if fromAddress.isEmpty {
                    fromCoordinate = locationManager.location
                    fromAddress = locationManager.currentAddress
                    
                    print("📍 Initial location set in onAppear:")
                    print("   Address: '\(fromAddress)'")
                    print("   Coordinates: \(fromCoordinate?.latitude ?? 0), \(fromCoordinate?.longitude ?? 0)")
                }
            }
            .onChange(of: locationManager.currentAddress) { newAddress in
                if fromAddress.isEmpty && !newAddress.isEmpty {
                    fromAddress = newAddress
                    fromCoordinate = locationManager.location
                    
                    print("📍 Location updated via onChange:")
                    print("   Address: '\(fromAddress)'")
                    print("   Coordinates: \(fromCoordinate?.latitude ?? 0), \(fromCoordinate?.longitude ?? 0)")
                }
            }
            .onTapGesture {
                showDestinationSuggestions = false
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }
    
    func locationField(title: String, address: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(address)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
    
    func selectDestination(_ completion: MKLocalSearchCompletion) {
        locationSearchCompleter.getCoordinate(for: completion) { coordinate, address in
            if let coordinate = coordinate, let address = address {
                toAddress = address
                toCoordinate = coordinate
                locationSearchCompleter.searchQuery = address
                showDestinationSuggestions = false
                
                print("📍 Destination selected:")
                print("   Address: '\(address)'")
                print("   Coordinates: \(coordinate.latitude), \(coordinate.longitude)")
                
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }
    
    func publishRide() {
        guard let currentUser = currentUser else {
            alertMessage = "User not found."
            showingAlert = true
            return
        }
        
        if fromAddress.isEmpty && !locationManager.currentAddress.isEmpty {
            fromAddress = locationManager.currentAddress
            fromCoordinate = locationManager.location
        }
        
        guard let fromCoord = fromCoordinate, let toCoord = toCoordinate else {
            alertMessage = "Please wait for location to load or select valid locations."
            showingAlert = true
            return
        }
        
        guard !fromAddress.isEmpty else {
            alertMessage = "Please wait for location to load."
            showingAlert = true
            return
        }
        
        guard !farePerKm.isEmpty, Double(farePerKm) != nil else {
            alertMessage = "Please enter a valid fare amount."
            showingAlert = true
            return
        }
        
        isPublishing = true
        
        print("🚀 Publishing ride:")
        print("   From: '\(fromAddress)' (\(fromCoord.latitude), \(fromCoord.longitude))")
        print("   To: '\(toAddress)' (\(toCoord.latitude), \(toCoord.longitude))")
        print("   Date: \(selectedDateTime)")
        
        let rideData: [String: Any] = [
            "fromAddress": fromAddress.trimmingCharacters(in: .whitespacesAndNewlines),
            "toAddress": toAddress.trimmingCharacters(in: .whitespacesAndNewlines),
            "fromLat": fromCoord.latitude,
            "fromLong": fromCoord.longitude,
            "toLat": toCoord.latitude,
            "toLong": toCoord.longitude,
            "date": Timestamp(date: selectedDateTime),
            "availableSeats": availableSeats,
            "farePerKm": farePerKm,
            "vehicleType": vehicleType.rawValue,
            "genderPreference": genderPreference.firestoreValue,
            "driverId": currentUser.id,
            "driverName": currentUser.name,
            "driverGender": currentUser.gender,
            "createdAt": Timestamp(date: Date())
        ]
        
        Firestore.firestore().collection("rides").addDocument(data: rideData) { error in
            self.isPublishing = false
            
            if let error = error {
                self.alertMessage = "Failed to publish ride: \(error.localizedDescription)"
                self.showingAlert = true
                print("❌ Publish failed: \(error.localizedDescription)")
            } else {
                print("✅ Ride published successfully!")
                
                // Create Ride object and navigate to tracking
                let newRide = Ride(
                    id: nil,
                    driverId: currentUser.id ?? "101",
                    driverName: currentUser.name,
                    driverGender: currentUser.gender,
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
                
                self.publishedRide = newRide
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.showDriverTracking = true
                }
            }
        }
    }
}

#Preview {
    PublishRideView(
        locationManager: LocationManagerRideSearch(),
        currentUser: AppUser(
            id: "1",
            name: "Shashank",
            email: "test@test.com",
            phone: "9999999999",
            gender: "male",
            vehicleType: "car",
            profilePicture: "",
            fcmToken: "",
            createdAt: Date()
        )
    )
}
