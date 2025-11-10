import SwiftUI
import MapKit
import FirebaseFirestore

struct PassengerTrackingView: View {
    let ride: Ride
    let currentUser: AppUser?
    
    @StateObject private var viewModel = PassengerTrackingViewModel()
    @State private var mapPosition: MapCameraPosition
    @State private var route: MKRoute?
    @Environment(\.dismiss) private var dismiss
    
    init(ride: Ride, currentUser: AppUser?) {
        self.ride = ride
        self.currentUser = currentUser
        
        let center = CLLocationCoordinate2D(
            latitude: ride.fromLat,
            longitude: ride.fromLong
        )
        _mapPosition = State(initialValue: .region(
            MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        ))
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Map
            Map(position: $mapPosition) {
                // Route polyline
                if let route {
                    MapPolyline(route.polyline)
                        .stroke(Color.blue, lineWidth: 6)
                }
                
                // Pickup location
                Annotation("Pickup", coordinate: CLLocationCoordinate2D(latitude: ride.fromLat, longitude: ride.fromLong)) {
                    ZStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 30, height: 30)
                        Image(systemName: "figure.walk")
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .bold))
                    }
                }
                
                // Destination
                Annotation("Destination", coordinate: CLLocationCoordinate2D(latitude: ride.toLat, longitude: ride.toLong)) {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 30, height: 30)
                        Image(systemName: "flag.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .bold))
                    }
                }
                
                // Driver location (live or static)
                if let driverLocation = viewModel.driverLocation {
                    Annotation("Driver", coordinate: driverLocation) {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 40, height: 40)
                            Image(systemName: "car.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 18, weight: .bold))
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .ignoresSafeArea()
            
            // Bottom info card
            VStack(spacing: 0) {
                // Driver info
                HStack(spacing: 16) {
                    // Driver avatar
                    Circle()
                        .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(ride.driverName.prefix(1).uppercased())
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(ride.driverName)
                            .font(.system(size: 20, weight: .bold))
                        
                        HStack(spacing: 8) {
                            Image(systemName: ride.vehicleType.lowercased() == "car" ? "car.fill" : "bicycle")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            Text(ride.vehicleType)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            
                            Text("•")
                                .foregroundColor(.gray)
                            
                            Text("₹\(ride.farePerKm)/km")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.green)
                        }
                        
                        if let distance = viewModel.estimatedDistance {
                            Text("Distance: \(String(format: "%.1f", distance)) km")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding(20)
                
                Divider()
                
                // Route details
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("FROM")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(ride.fromAddress)
                                .font(.system(size: 14, weight: .medium))
                        }
                        Spacer()
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("TO")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(ride.toAddress)
                                .font(.system(size: 14, weight: .medium))
                        }
                        Spacer()
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("DEPARTURE")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(ride.date, style: .date)
                                .font(.system(size: 14, weight: .medium))
                            + Text(" at ")
                                .font(.system(size: 14))
                            + Text(ride.date, style: .time)
                                .font(.system(size: 14, weight: .medium))
                        }
                        Spacer()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                // Action buttons
                HStack(spacing: 12) {
                    Button(action: {
                        // Call driver action
                    }) {
                        HStack {
                            Image(systemName: "phone.fill")
                            Text("Call")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .font(.system(size: 16, weight: .semibold))
                    }
                    
                    Button(action: {
                        viewModel.bookRide(ride: ride, passenger: currentUser)
                    }) {
                        HStack {
                            if viewModel.isBooking {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Book Ride")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(colors: [.blue, .blue.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .font(.system(size: 16, weight: .semibold))
                    }
                    .disabled(viewModel.isBooking)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: -5)
            )
            .padding(.top, 20)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .task {
            await getRoute()
            viewModel.startTrackingDriver(driverId: ride.driverId, pickupLocation: CLLocationCoordinate2D(latitude: ride.fromLat, longitude: ride.fromLong))
        }
        .onDisappear {
            viewModel.stopTracking()
        }
        .alert("Booking Status", isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) {
                if viewModel.bookingSuccess {
                    dismiss()
                }
            }
        } message: {
            Text(viewModel.alertMessage)
        }
    }
    
    private func getRoute() async {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: ride.fromLat, longitude: ride.fromLong)))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: ride.toLat, longitude: ride.toLong)))
        request.transportType = .automobile
        
        do {
            let response = try await MKDirections(request: request).calculate()
            if let first = response.routes.first {
                await MainActor.run {
                    route = first
                    mapPosition = .region(MKCoordinateRegion(first.polyline.boundingMapRect))
                    viewModel.estimatedDistance = first.distance / 1000.0 // Convert to km
                }
            }
        } catch {
            print("❌ Route calculation failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - ViewModel for Passenger
class PassengerTrackingViewModel: ObservableObject {
    @Published var driverLocation: CLLocationCoordinate2D?
    @Published var estimatedDistance: Double?
    @Published var isBooking = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var bookingSuccess = false
    
    private var driverLocationListener: ListenerRegistration?
    
    func startTrackingDriver(driverId: String, pickupLocation: CLLocationCoordinate2D) {
        // Set initial driver location as pickup point
        driverLocation = pickupLocation
        
        // Listen to driver's live location from Firestore
        driverLocationListener = Firestore.firestore()
            .collection("users")
            .document(driverId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error listening to driver location: \(error.localizedDescription)")
                    return
                }
                
                guard let data = snapshot?.data(),
                      let lat = data["currentLat"] as? Double,
                      let long = data["currentLong"] as? Double else {
                    print("⚠️ Driver location not available, using pickup location")
                    return
                }
                
                DispatchQueue.main.async {
                    self.driverLocation = CLLocationCoordinate2D(latitude: lat, longitude: long)
                    print("📍 Driver location updated: \(lat), \(long)")
                }
            }
    }
    
    func stopTracking() {
        driverLocationListener?.remove()
        driverLocationListener = nil
    }
    
    func bookRide(ride: Ride, passenger: AppUser?) {
        guard let passenger = passenger else {
            alertMessage = "User not found"
            showAlert = true
            return
        }
        
        isBooking = true
        
        let bookingData: [String: Any] = [
            "rideId": ride.id ?? "",
            "driverId": ride.driverId,
            "driverName": ride.driverName,
            "passengerId": passenger.id,
            "passengerName": passenger.name,
            "passengerPhone": passenger.phone,
            "fromAddress": ride.fromAddress,
            "toAddress": ride.toAddress,
            "date": Timestamp(date: ride.date),
            "status": "pending",
            "createdAt": Timestamp(date: Date())
        ]
        
        Firestore.firestore().collection("bookings").addDocument(data: bookingData) { [weak self] error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isBooking = false
                
                if let error = error {
                    self.alertMessage = "Failed to book ride: \(error.localizedDescription)"
                    self.bookingSuccess = false
                } else {
                    self.alertMessage = "Ride booked successfully! The driver will contact you soon."
                    self.bookingSuccess = true
                }
                
                self.showAlert = true
            }
        }
    }
}

#Preview {
    PassengerTrackingView(
        ride: Ride(
            id: "1",
            driverId: "driver1",
            driverName: "John Doe",
            driverGender: "male",
            fromAddress: "Bangalore",
            fromLat: 12.9716,
            fromLong: 77.5946,
            toAddress: "Chennai",
            toLat: 13.0827,
            toLong: 80.2707,
            date: Date(),
            availableSeats: 2,
            vehicleType: "Car",
            farePerKm: "10",
            genderPreference: ["all"],
            createdAt: Date()
        ),
        currentUser: AppUser(
            id: "1",
            name: "Test User",
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
