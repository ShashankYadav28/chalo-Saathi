import SwiftUI
import MapKit
import FirebaseFirestore
import CoreLocation

struct DriverTrackingView: View {
    let ride: Ride
    let currentUser: AppUser?
    
    @StateObject private var viewModel = DriverTrackingViewModel()
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
                
                // Start location (pickup)
                Annotation("Start", coordinate: CLLocationCoordinate2D(latitude: ride.fromLat, longitude: ride.fromLong)) {
                    ZStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 30, height: 30)
                        Image(systemName: "figure.wave")
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
                
                // Your current location
                if let currentLocation = viewModel.currentLocation {
                    Annotation("You", coordinate: currentLocation) {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 50, height: 50)
                                .shadow(color: .blue.opacity(0.3), radius: 10)
                            Image(systemName: "car.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 22, weight: .bold))
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .ignoresSafeArea()
            
            // Bottom info card
            VStack(spacing: 0) {
                // Status banner
                HStack {
                    Circle()
                        .fill(viewModel.isTracking ? Color.green : Color.orange)
                        .frame(width: 12, height: 12)
                    
                    Text(viewModel.isTracking ? "Live Tracking Active" : "Tracking Paused")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(viewModel.isTracking ? .green : .orange)
                    
                    Spacer()
                    
                    Button(action: {
                        if viewModel.isTracking {
                            viewModel.stopTracking()
                        } else {
                            viewModel.startTracking(userId: currentUser?.id ?? "", ride: ride)
                        }
                    }) {
                        Text(viewModel.isTracking ? "Stop" : "Start")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(viewModel.isTracking ? Color.red : Color.green)
                            .cornerRadius(20)
                    }
                }
                .padding(16)
                .background(Color.blue.opacity(0.1))
                
                // Ride details
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("YOUR RIDE")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(ride.vehicleType) • \(ride.availableSeats) seats")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("FARE")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("₹\(ride.farePerKm)/km")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.green)
                        }
                    }
                    
                    Divider()
                    
                    // Route info
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 20))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("FROM")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(ride.fromAddress)
                                    .font(.system(size: 14, weight: .medium))
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                        }
                        
                        HStack(spacing: 12) {
                            Image(systemName: "flag.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 20))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("TO")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(ride.toAddress)
                                    .font(.system(size: 14, weight: .medium))
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                        }
                        
                        HStack(spacing: 12) {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 20))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("DEPARTURE")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                HStack(spacing: 4) {
                                    Text(ride.date, style: .date)
                                    Text("at")
                                        .foregroundColor(.secondary)
                                    Text(ride.date, style: .time)
                                }
                                .font(.system(size: 14, weight: .medium))
                            }
                            
                            Spacer()
                        }
                    }
                    
                    if let distance = viewModel.estimatedDistance {
                        Divider()
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("TOTAL DISTANCE")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.1f km", distance))
                                    .font(.system(size: 16, weight: .bold))
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("EST. EARNINGS")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                if let fare = Double(ride.farePerKm) {
                                    Text("₹\(String(format: "%.0f", distance * fare))")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                    
                    // Booking requests
                    if !viewModel.bookingRequests.isEmpty {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("BOOKING REQUESTS (\(viewModel.bookingRequests.count))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ForEach(viewModel.bookingRequests.prefix(3)) { booking in
                                HStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.2))
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Text(booking.passengerName.prefix(1).uppercased())
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.blue)
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(booking.passengerName)
                                            .font(.system(size: 14, weight: .semibold))
                                        Text(booking.passengerPhone)
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 8) {
                                        Button(action: {
                                            viewModel.respondToBooking(bookingId: booking.id ?? "", accept: false)
                                        }) {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.white)
                                                .frame(width: 32, height: 32)
                                                .background(Color.red)
                                                .cornerRadius(16)
                                        }
                                        
                                        Button(action: {
                                            viewModel.respondToBooking(bookingId: booking.id ?? "", accept: true)
                                        }) {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.white)
                                                .frame(width: 32, height: 32)
                                                .background(Color.green)
                                                .cornerRadius(16)
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                    
                    // End ride button
                    Button(action: {
                        viewModel.showEndRideConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("End Ride")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.red)
                        .cornerRadius(12)
                    }
                }
                .padding(20)
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
                Button(action: {
                    viewModel.stopTracking()
                    dismiss()
                }) {
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
            viewModel.startTracking(userId: currentUser?.id ?? "", ride: ride)
            viewModel.listenForBookings(rideId: ride.id ?? "")
        }
        .onDisappear {
            viewModel.stopTracking()
        }
        .alert("End Ride?", isPresented: $viewModel.showEndRideConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("End Ride", role: .destructive) {
                viewModel.endRide(rideId: ride.id ?? "")
                dismiss()
            }
        } message: {
            Text("Are you sure you want to end this ride?")
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
                    viewModel.estimatedDistance = first.distance / 1000.0
                }
            }
        } catch {
            print("❌ Route calculation failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Booking Model
struct BookingRequest: Identifiable, Codable {
    @DocumentID var id: String?
    let rideId: String
    let passengerId: String
    let passengerName: String
    let passengerPhone: String
    let status: String
}

// MARK: - ViewModel for Driver
class DriverTrackingViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var estimatedDistance: Double?
    @Published var isTracking = false
    @Published var bookingRequests: [BookingRequest] = []
    @Published var showEndRideConfirmation = false
    
    private var locationManager = CLLocationManager()
    private var bookingListener: ListenerRegistration?
    private var currentUserId: String?
    private var currentRide: Ride?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startTracking(userId: String, ride: Ride) {
        currentUserId = userId
        currentRide = ride
        isTracking = true
        locationManager.startUpdatingLocation()
        print("🚗 Started tracking driver location")
    }
    
    func stopTracking() {
        isTracking = false
        locationManager.stopUpdatingLocation()
        bookingListener?.remove()
        print("🛑 Stopped tracking driver location")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last,
              let userId = currentUserId else { return }
        
        currentLocation = location.coordinate
        
        // Update location in Firestore
        Firestore.firestore()
            .collection("users")
            .document(userId)
            .updateData([
                "currentLat": location.coordinate.latitude,
                "currentLong": location.coordinate.longitude,
                "lastLocationUpdate": Timestamp(date: Date())
            ]) { error in
                if let error = error {
                    print("❌ Failed to update location: \(error.localizedDescription)")
                } else {
                    print("📍 Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                }
            }
    }
    
    func listenForBookings(rideId: String) {
        bookingListener = Firestore.firestore()
            .collection("bookings")
            .whereField("rideId", isEqualTo: rideId)
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error listening to bookings: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self.bookingRequests = documents.compactMap { doc in
                    try? doc.data(as: BookingRequest.self)
                }
                
                print("📋 Booking requests updated: \(self.bookingRequests.count)")
            }
    }
    
    func respondToBooking(bookingId: String, accept: Bool) {
        Firestore.firestore()
            .collection("bookings")
            .document(bookingId)
            .updateData([
                "status": accept ? "accepted" : "rejected",
                "respondedAt": Timestamp(date: Date())
            ]) { error in
                if let error = error {
                    print("❌ Failed to respond to booking: \(error.localizedDescription)")
                } else {
                    print("✅ Booking \(accept ? "accepted" : "rejected")")
                }
            }
    }
    
    func endRide(rideId: String) {
        guard !rideId.isEmpty else { return }
        
        Firestore.firestore()
            .collection("rides")
            .document(rideId)
            .updateData([
                "status": "completed",
                "completedAt": Timestamp(date: Date())
            ]) { error in
                if let error = error {
                    print("❌ Failed to end ride: \(error.localizedDescription)")
                } else {
                    print("✅ Ride ended successfully")
                }
            }
        
        stopTracking()
    }
}

#Preview {
    DriverTrackingView(
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
