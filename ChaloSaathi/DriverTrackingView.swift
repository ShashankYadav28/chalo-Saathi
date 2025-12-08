import SwiftUI
import MapKit
import FirebaseFirestore
import FirebaseAuth               // ✅ for Auth.auth().currentUser?.uid
import CoreLocation

// MARK: - Driver Tracking View
struct DriverTrackingView: View {
    let ride: Ride
    let currentUser: AppUser?      // can still be optional
    
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
    
    // ✅ Helper to always get a valid userId (Auth UID > model id)
    private var resolvedUserId: String {
        let authId = Auth.auth().currentUser?.uid ?? ""
        let modelId = currentUser?.id ?? ""
        return !authId.isEmpty ? authId : modelId
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // MARK: Map View
            Map(position: $mapPosition) {
                if let route {
                    MapPolyline(route.polyline)
                        .stroke(Color.blue, lineWidth: 6)
                }
                
                Annotation("Start", coordinate: CLLocationCoordinate2D(latitude: ride.fromLat, longitude: ride.fromLong)) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 28, height: 28)
                        .overlay(Image(systemName: "figure.wave").foregroundColor(.white))
                }
                
                Annotation("Destination", coordinate: CLLocationCoordinate2D(latitude: ride.toLat, longitude: ride.toLong)) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 28, height: 28)
                        .overlay(Image(systemName: "flag.fill").foregroundColor(.white))
                }
                
                if let current = viewModel.currentLocation {
                    Annotation("You", coordinate: current) {
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
            
            // MARK: Bottom Info Panel
            VStack(spacing: 0) {
                HStack {
                    Circle()
                        .fill(viewModel.isTracking ? .green : .orange)
                        .frame(width: 12, height: 12)
                    Text(viewModel.isTracking ? "Live Tracking Active" : "Tracking Paused")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(viewModel.isTracking ? .green : .orange)
                    
                    Spacer()
                    
                    Button {
                        if viewModel.isTracking {
                            print("🛑 Stop Tracking tapped")
                            viewModel.stopTracking()
                        } else {
                            print("🚗 Start Tracking tapped")
                            
                            let userId = resolvedUserId   // ✅ use helper
                            if !userId.isEmpty {
                                viewModel.startTracking(userId: userId, ride: ride)
                            } else {
                                print("❌ Missing userId, cannot start tracking (no Auth UID and no currentUser.id)")
                            }
                        }
                    } label: {
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
                
                // MARK: Ride Details
                ScrollView {
                    VStack(spacing: 16) {
                        // Ride Summary
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
                        
                        // Route Info
                        routeRow(icon: "mappin.circle.fill", color: .green, title: "FROM", value: ride.fromAddress)
                        routeRow(icon: "flag.fill", color: .red, title: "TO", value: ride.toAddress)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text("DEPARTURE")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                HStack {
                                    Text(ride.date, style: .date)
                                    Text("at")
                                        .foregroundColor(.secondary)
                                    Text(ride.date, style: .time)
                                }
                                .font(.system(size: 14, weight: .medium))
                            }
                            Spacer()
                        }
                        
                        // Distance + Earnings
                        if let dist = viewModel.estimatedDistance {
                            Divider()
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("TOTAL DISTANCE")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(String(format: "%.1f km", dist))
                                        .font(.system(size: 16, weight: .bold))
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text("EST. EARNINGS")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    if let fare = Double(ride.farePerKm) {
                                        Text("₹\(String(format: "%.0f", dist * fare))")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                        }
                        
                        // Booking Requests
                        if !viewModel.bookingRequests.isEmpty {
                            Divider()
                            VStack(alignment: .leading, spacing: 8) {
                                Text("BOOKING REQUESTS (\(viewModel.bookingRequests.count))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                ForEach(viewModel.bookingRequests.prefix(3)) { b in
                                    HStack {
                                        Circle()
                                            .fill(Color.blue.opacity(0.2))
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Text(b.passengerName.prefix(1).uppercased())
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundColor(.blue)
                                            )
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(b.passengerName)
                                                .font(.system(size: 14, weight: .semibold))
                                            Text(b.passengerPhone)
                                                .font(.system(size: 12))
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        HStack(spacing: 8) {
                                            Button {
                                                viewModel.respondToBooking(bookingId: b.id ?? "", accept: false)
                                            } label: {
                                                Image(systemName: "xmark")
                                                    .foregroundColor(.white)
                                                    .frame(width: 32, height: 32)
                                                    .background(Color.red)
                                                    .cornerRadius(16)
                                            }
                                            
                                            Button {
                                                viewModel.respondToBooking(bookingId: b.id ?? "", accept: true)
                                            } label: {
                                                Image(systemName: "checkmark")
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
                        
                        // End Ride Button
                        Button {
                            viewModel.showEndRideConfirmation = true
                        } label: {
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
                .frame(maxHeight: 400)
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: -5)
            )
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    viewModel.stopTracking()
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .task {
            await getRoute()
            
            let userId = resolvedUserId        // ✅ same logic here
            if !userId.isEmpty {
                viewModel.startTracking(userId: userId, ride: ride)
            } else {
                print("❌ DriverTrackingView .task: no userId available, not starting tracking")
            }
            
            if let rideId = ride.id, !rideId.isEmpty {
                viewModel.listenForBookings(rideId: rideId)
            }
        }
        .onDisappear {
            viewModel.stopTracking()
        }
        .alert("End Ride?", isPresented: $viewModel.showEndRideConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("End Ride", role: .destructive) {
                if let rideId = ride.id, !rideId.isEmpty {
                    viewModel.endRide(rideId: rideId)
                }
                dismiss()
            }
        } message: {
            Text("Are you sure you want to end this ride?")
        }
    }
    
    // MARK: - Helper UI
    func routeRow(icon: String, color: Color, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
            }
            Spacer()
        }
    }
    
    // MARK: - Fetch route
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

// MARK: - Booking Request Model
struct BookingRequest: Identifiable, Codable {
    @DocumentID var id: String?
    let rideId: String
    let passengerId: String
    let passengerName: String
    let passengerPhone: String
    let status: String
}

// MARK: - Driver Tracking ViewModel
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
        guard !userId.isEmpty else {
            print("❌ Cannot start tracking: userId is empty")
            return
        }
        currentUserId = userId
        currentRide = ride
        isTracking = true
        locationManager.startUpdatingLocation()
        print("🚗 Started tracking driver location for user: \(userId)")
    }
    
    func stopTracking() {
        isTracking = false
        locationManager.stopUpdatingLocation()
        bookingListener?.remove()
        print("🛑 Stopped tracking driver location")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("📍 didUpdateLocations called")
        guard let location = locations.last,
              let userId = currentUserId,
              !userId.isEmpty else {
            print("❌ Missing location or userId")
            return
        }
        currentLocation = location.coordinate
        print("✅ Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        Firestore.firestore().collection("users").document(userId)
            .updateData([
                "currentLat": location.coordinate.latitude,
                "currentLong": location.coordinate.longitude,
                "lastLocationUpdate": Timestamp(date: Date())
            ]) { error in
                if let error = error {
                    print("❌ Failed Firestore update: \(error.localizedDescription)")
                } else {
                    print("✅ Firestore driver location updated")
                }
            }
    }
    
    func listenForBookings(rideId: String) {
        guard !rideId.isEmpty else {
            print("❌ Cannot listen: rideId empty")
            return
        }
        bookingListener = Firestore.firestore().collection("bookings")
            .whereField("rideId", isEqualTo: rideId)
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { [weak self] snap, err in
                guard let self = self else { return }
                if let err = err {
                    print("❌ Booking listener error: \(err.localizedDescription)")
                    return
                }
                self.bookingRequests = snap?.documents.compactMap {
                    try? $0.data(as: BookingRequest.self)
                } ?? []
                print("📋 Booking requests updated: \(self.bookingRequests.count)")
            }
    }
    
    func respondToBooking(bookingId: String, accept: Bool) {
        guard !bookingId.isEmpty else { return }
        Firestore.firestore().collection("bookings").document(bookingId)
            .updateData([
                "status": accept ? "accepted" : "rejected",
                "respondedAt": Timestamp(date: Date())
            ]) { err in
                if let err = err {
                    print("❌ Respond failed: \(err.localizedDescription)")
                } else {
                    print("✅ Booking \(accept ? "accepted" : "rejected")")
                }
            }
    }
    
    func endRide(rideId: String) {
        guard !rideId.isEmpty else { return }
        Firestore.firestore().collection("rides").document(rideId)
            .updateData([
                "status": "completed",
                "completedAt": Timestamp(date: Date())
            ]) { err in
                if let err = err {
                    print("❌ End ride failed: \(err.localizedDescription)")
                } else {
                    print("✅ Ride ended successfully")
                }
            }
        stopTracking()
    }
}

