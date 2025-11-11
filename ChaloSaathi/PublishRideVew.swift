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
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    // From Location Field
                    locationField(
                        title: "From",
                        address: displayFromAddress,
                        icon: "mappin.circle.fill",
                        color: .green
                    )
                    
                    // To Location Field
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
                    
                    // Date & Time Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date & Time")
                            .font(.headline)
                        DatePicker("Select departure", selection: $selectedDateTime, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                    }
                    .padding(.horizontal)
                    
                    // Available Seats Stepper
                    VStack(alignment: .leading, spacing: 8) {
                        Stepper("Available Seats: \(availableSeats)", value: $availableSeats, in: 1...4)
                    }
                    .padding(.horizontal)
                    
                    // Fare Per Km Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Fare per km")
                            .font(.headline)
                        TextField("Enter fare (₹)", text: $farePerKm)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.horizontal)
                    
                    // Vehicle Type Picker
                    VStack(alignment: .leading, spacing: 8) {
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
                    
                    // Gender Preference Picker
                    VStack(alignment: .leading, spacing: 8) {
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
                    
                    // Publish Button
                    Button(action: publishRide) {
                        HStack(spacing: 10) {
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
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: isFormValid ? [.blue, .blue.opacity(0.85)] : [.gray, .gray.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: isFormValid ? .blue.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal)
                    .disabled(isPublishing || !isFormValid)
                    
                    // Validation Message
                    if !isFormValid {
                        Text("Please fill all fields and select destinations")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                }
                .padding(.top, 20) // Add top padding to separate from tab switcher
                .padding(.bottom, 100)
            }
            
            // Destination Suggestions Overlay
            if showDestinationSuggestions && !locationSearchCompleter.searchresult.isEmpty {
                VStack {
                    Spacer()
                        .frame(height: 180) // Adjusted for better positioning
                    
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
        .navigationDestination(isPresented: $showDriverTracking) {
            if let ride = publishedRide {
                DriverTrackingView(ride: ride, currentUser: currentUser)
                    .onAppear {
                        print("🚗 Navigating to DriverTrackingView")
                        print("   User ID: \(currentUser.id ?? "nil")")
                        print("   Ride ID: \(ride.id ?? "nil")")
                    }
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
    
    func locationField(title: String, address: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 20))
                
                Text(address)
                    .font(.subheadline)
                    .foregroundColor(address == "Fetching location..." ? .gray : .primary)
                
                Spacer()
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            .padding(.horizontal)
        }
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
        // Update fromAddress if empty
        if fromAddress.isEmpty && !locationManager.currentAddress.isEmpty {
            fromAddress = locationManager.currentAddress
            fromCoordinate = locationManager.location
        }
        
        // Validate all required fields
        guard let fromCoord = fromCoordinate,
              let toCoord = toCoordinate,
              !farePerKm.isEmpty else {
            alertMessage = "Please fill all required fields correctly"
            showingAlert = true
            return
        }
        
        isPublishing = true
        
        // Create ride document in Firestore
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
        
        rideRef.setData(rideData) { [self] error in
            DispatchQueue.main.async {
                self.isPublishing = false
                
                if let error = error {
                    print("❌ Error publishing ride: \(error.localizedDescription)")
                    self.alertMessage = "Failed to publish ride: \(error.localizedDescription)"
                    self.showingAlert = true
                } else {
                    print("✅ Ride published successfully with ID: \(rideRef.documentID)")
                    
                    // Create Ride object for navigation
                    self.publishedRide = Ride(
                        id: rideRef.documentID,
                        driverId: currentUser.id ?? "101",
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
                    
                    // Navigate to DriverTrackingView
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
            id: "preview123",
            name: "Test User",
            email: "test@example.com",
            phone: "1234567890",
            gender: "male"
        )
    )
}
