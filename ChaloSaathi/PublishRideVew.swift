//
//  PublishRideVew.swift
//  ChaloSaathi
//
//  Created by Shashank Yadav on 26/10/25.
//

import SwiftUI
import MapKit
import FirebaseFirestore

struct PublishRideView: View {
    @ObservedObject var locationManager: LocationManagerRideSearch
    let currentUser: AppUser?

    @State private var fromAddress: String = ""
    @State private var toAddress: String = ""
    @State private var selectedDate = Date()
    @State private var selectedTime = Date()
    @State private var availableSeats = 1
    @State private var vehicleType: VehicleType = .car
    @State private var farePerKm: String = ""
    @State private var genderPreference: GenderPreference = .all
    @State private var showingDestinationSearch = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isPublishing = false
    
    // Coordinates
    @State private var fromCoordinate: CLLocationCoordinate2D?
    @State private var toCoordinate: CLLocationCoordinate2D?
    
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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // From Location
                    locationField(
                        title: "From",
                        address: locationManager.currentAddress.isEmpty ? "Fetching location..." : locationManager.currentAddress,
                        icon: "mappin.circle.fill",
                        color: .red
                    )
                    
                    // To Location (manual entry for now)
                    VStack(alignment: .leading) {
                        Text("To")
                            .font(.headline)
                        TextField("Enter destination (e.g., Chennai)", text: $toAddress)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.horizontal)
                    
                    // Date & Time
                    HStack(spacing: 16) {
                        DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                        DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    }
                    .padding(.horizontal)
                    
                    // Seats
                    Stepper("Available Seats: \(availableSeats)", value: $availableSeats, in: 1...4)
                        .padding(.horizontal)
                    
                    // Fare
                    TextField("Fare per km (₹)", text: $farePerKm)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    // Vehicle Type Picker
                    Picker("Vehicle Type", selection: $vehicleType) {
                        ForEach(VehicleType.allCases, id: \.self) {
                            Text($0.rawValue)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Gender Preference Picker
                    Picker("Gender Preference", selection: $genderPreference) {
                        ForEach(GenderPreference.allCases, id: \.self) {
                            Text($0.rawValue)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    Button(action: publishRide) {
                        HStack {
                            if isPublishing {
                                ProgressView()
                            } else {
                                Image(systemName: "paperplane.fill")
                            }
                            Text("Publish Ride")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    .padding()
                    .disabled(isPublishing)
                }
            }
            .navigationTitle("Publish Ride")
            .alert("Status", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                // Simulate from location
                fromCoordinate = CLLocationCoordinate2D(latitude: 12.9716, longitude: 77.5946) // Bangalore
                fromAddress = "Bangalore"
            }
        }
    }
    
    // MARK: - Helper Views
    
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
    
    // MARK: - Firestore Publish Logic
    
    func publishRide() {
        guard let currentUser = currentUser else {
            alertMessage = "User not found."
            showingAlert = true
            return
        }
        
        isPublishing = true
        
        // Assign manual coordinates for test
        fromCoordinate = CLLocationCoordinate2D(latitude: 12.9716, longitude: 77.5946) // Bangalore
        toCoordinate = CLLocationCoordinate2D(latitude: 13.0827, longitude: 80.2707) // Chennai
        
        let rideData: [String: Any] = [
            "from": fromAddress,
            "to": toAddress,
            "fromLat": fromCoordinate?.latitude ?? 0.0,
            "fromLong": fromCoordinate?.longitude ?? 0.0,
            "toLat": toCoordinate?.latitude ?? 0.0,
            "toLong": toCoordinate?.longitude ?? 0.0,
            "date": Timestamp(date: selectedDate),
            "time": Timestamp(date: selectedTime),
            "availableSeats": availableSeats,
            "farePerKm": farePerKm,
            "vehicleType": vehicleType.rawValue,
            "genderPreference": genderPreference.firestoreValue,
            "driverId": currentUser.id,
            "driverName": currentUser.name,
            "driverGender": currentUser.gender
        ]
        
        Firestore.firestore().collection("rides").addDocument(data: rideData) { error in
            isPublishing = false
            if let error = error {
                alertMessage = "Failed to publish ride: \(error.localizedDescription)"
            } else {
                alertMessage = "Ride successfully published!"
                toAddress = ""
                farePerKm = ""
            }
            showingAlert = true
        }
    }
}

#Preview {
    PublishRideView(locationManager: LocationManagerRideSearch(),
                    currentUser: AppUser(id: "1", name: "Shashank", email: "test@test.com",
                                         phone: "9999999999", gender: "male", vehicleType: "car",
                                         profilePicture: "", fcmToken: "", createdAt: Date()))
}

