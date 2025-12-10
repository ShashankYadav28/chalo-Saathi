import SwiftUI
import MapKit
import FirebaseFirestore
import CoreLocation
import FirebaseAuth   // ✅ Added

struct PassengerTrackingView: View {
    let ride: Ride
    let currentUser: AppUser
    
    @StateObject private var viewModel = PassengerTrackingViewModel()
    @State private var mapPosition: MapCameraPosition
    @State private var route: MKRoute?
    @State private var showBookingConfirmation = false
    @State private var bookingStatus: BookingStatus = .none
    @Environment(\.dismiss) private var dismiss
    
    enum BookingStatus: Equatable {
        case none
        case requesting
        case success
        case failed(String)
    }
    
    init(ride: Ride, currentUser: AppUser) {
        self.ride = ride
        self.currentUser = currentUser
        
        let center = CLLocationCoordinate2D(
            latitude: ride.fromLat,
            longitude: ride.fromLong
        )
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let region = MKCoordinateRegion(center: center, span: span)
        
        _mapPosition = State(initialValue: .region(region))
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            mapView
            bottomInfoCard
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                backButton
            }
        }
        .task {
            await getRoute()
            viewModel.startTrackingDriver(driverId: ride.driverId)
        }
        .onDisappear {
            viewModel.stopTracking()
        }
        .alert("Booking Confirmed!", isPresented: $showBookingConfirmation) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your ride has been booked successfully. The driver will be notified.")
        }
        .overlay {
            errorOverlay
        }
    }
    
    // MARK: - Map View
    private var mapView: some View {
        Map(position: $mapPosition) {
            if let route {
                MapPolyline(route.polyline)
                    .stroke(Color.blue, lineWidth: 6)
            }
            
            pickupAnnotation
            destinationAnnotation
            
            if let driverLocation = viewModel.driverLocation {
                driverAnnotation(at: driverLocation)
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .ignoresSafeArea()
    }
    
    private var pickupAnnotation: some MapContent {
        Annotation("Pickup", coordinate: CLLocationCoordinate2D(latitude: ride.fromLat, longitude: ride.fromLong)) {
            ZStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 30, height: 30)
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .bold))
            }
        }
    }
    
    private var destinationAnnotation: some MapContent {
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
    }
    
    private func driverAnnotation(at location: CLLocationCoordinate2D) -> some MapContent {
        Annotation("Driver", coordinate: location) {
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
    
    // MARK: - Bottom Info Card
    private var bottomInfoCard: some View {
        VStack(spacing: 0) {
            cardHeader
            Divider()
            cardContent
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: -5)
        )
        .padding(.top, 20)
    }
    
    private var cardHeader: some View {
        HStack {
            Text("Available Ride")
                .font(.system(size: 18, weight: .bold))
            
            Spacer()
            
            seatsAvailableBadge
        }
        .padding(16)
        .background(Color.white)
    }
    
    private var seatsAvailableBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "person.fill")
                .font(.system(size: 12))
            Text("\(ride.availableSeats) seats")
                .font(.system(size: 14, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.green)
        .cornerRadius(20)
    }
    
    private var cardContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                driverInfo
                Divider()
                routeDetails
                
                if viewModel.estimatedDistance != nil {
                    Divider()
                    distanceAndFare
                }
                
                bookRideButton
            }
        }
        .frame(maxHeight: 400)
    }
    
    // MARK: - Driver Info
    private var driverInfo: some View {
        HStack(spacing: 16) {
            driverAvatar
            
            VStack(alignment: .leading, spacing: 4) {
                Text(ride.driverName)
                    .font(.system(size: 20, weight: .bold))
                
                vehicleInfo
            }
            
            Spacer()
            
            dateTimeInfo
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    private var driverAvatar: some View {
        Circle()
            .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 60, height: 60)
            .overlay(
                Text(ride.driverName.prefix(1).uppercased())
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            )
    }
    
    private var vehicleInfo: some View {
        HStack(spacing: 8) {
            Image(systemName: ride.vehicleType.lowercased() == "car" ? "car.fill" : "bicycle")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            Text(ride.vehicleType)
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
    }
    
    private var dateTimeInfo: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(ride.date, style: .date)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            Text(ride.date, style: .time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Route Details
    private var routeDetails: some View {
        VStack(spacing: 12) {
            routeRow(
                icon: "mappin.circle.fill",
                color: .green,
                label: "FROM",
                text: ride.fromAddress
            )
            
            routeRow(
                icon: "flag.fill",
                color: .red,
                label: "TO",
                text: ride.toAddress
            )
        }
        .padding(.horizontal, 20)
    }
    
    private func routeRow(icon: String, color: Color, label: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 20))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(text)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(2)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Distance and Fare
    private var distanceAndFare: some View {
        HStack {
            distanceSection
            Spacer()
            fareSection
        }
        .padding(.horizontal, 20)
    }
    
    private var distanceSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("DISTANCE")
                .font(.caption)
                .foregroundColor(.secondary)
            if let distance = viewModel.estimatedDistance {
                Text(String(format: "%.1f km", distance))
                    .font(.system(size: 16, weight: .bold))
            }
        }
    }
    
    private var fareSection: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("FARE")
                .font(.caption)
                .foregroundColor(.secondary)
            if let distance = viewModel.estimatedDistance,
               let fare = Double(ride.farePerKm) {
                Text("₹\(String(format: "%.0f", distance * fare))")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.green)
            }
        }
    }
    
    // MARK: - Book Ride Button
    private var bookRideButton: some View {
        Button(action: bookRide) {
            HStack(spacing: 10) {
                if case .requesting = bookingStatus {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                }
                Text("Book This Ride")
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [.green, .green.opacity(0.85)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(bookingStatus == .requesting)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    // MARK: - Other UI Components
    private var backButton: some View {
        Button(action: { dismiss() }) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                Text("Back")
            }
            .foregroundColor(.blue)
        }
    }
    
    @ViewBuilder
    private var errorOverlay: some View {
        if case .failed(let message) = bookingStatus {
            VStack {
                Spacer()
                
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.white)
                    Text(message)
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .medium))
                }
                .padding()
                .background(Color.red)
                .cornerRadius(12)
                .padding()
                .transition(.move(edge: .bottom))
            }
            .animation(.spring(), value: bookingStatus)
        }
    }
    
    // MARK: - Functions
    private func getRoute() async {
        let request = MKDirections.Request()
        let fromCoord = CLLocationCoordinate2D(latitude: ride.fromLat, longitude: ride.fromLong)
        let toCoord = CLLocationCoordinate2D(latitude: ride.toLat, longitude: ride.toLong)
        
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: fromCoord))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: toCoord))
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
    
    // MARK: - UPDATED bookRide()
    // MARK: - Updated bookRide()
    private func bookRide() {
        // 1) Make sure we have a valid ride document id
        guard let rideId = ride.id, !rideId.isEmpty else {
            print("❌ bookRide: ride.id is nil/empty – cannot create booking")
            bookingStatus = .failed("Ride reference is invalid. Please search and open this ride again.")
            
            // hide the error after a few seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                bookingStatus = .none
            }
            return
        }
        
        // 2) Resolve passengerId (Auth UID > AppUser id)
        let authId = Auth.auth().currentUser?.uid ?? ""
        let modelId = currentUser.id ?? ""
        let passengerId = authId.isEmpty ? modelId : authId
        
        guard !passengerId.isEmpty else {
            print("❌ bookRide: passengerId is empty (no Auth uid and no currentUser.id)")
            bookingStatus = .failed("Something went wrong with your account. Please re-login and try again.")
            return
        }
        
        bookingStatus = .requesting
        
        let db = Firestore.firestore()
        let bookingRef = db.collection("bookings").document()
        
        let bookingData: [String: Any] = [
            "id": bookingRef.documentID,
            "rideId": rideId,
            "driverId": ride.driverId,
            "driverName": ride.driverName,
            "driverPhone": "",                       // you can fill this later
            "passengerId": passengerId,
            "passengerName": currentUser.name,
            "passengerPhone": currentUser.phone ?? "",
            "fromAddress": ride.fromAddress,
            "toAddress": ride.toAddress,
            "date": Timestamp(date: ride.date),
            "status": "pending",
            "createdAt": Timestamp(date: Date())
        ]
        
        bookingRef.setData(bookingData) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Booking failed: \(error.localizedDescription)")
                    bookingStatus = .failed("Booking failed. Please try again.")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        bookingStatus = .none
                    }
                } else {
                    print("✅ Booking created successfully for rideId=\(rideId)")
                    
                    NotificationHelper.shared.notifyNewBooking(
                        driverId: ride.driverId,
                        passengerName: currentUser.name,
                        bookingId: bookingRef.documentID,
                        rideId: rideId
                    )
                    
                    bookingStatus = .success
                    showBookingConfirmation = true
                }
            }
        }
    }
    
    // MARK: - ViewModel
    class PassengerTrackingViewModel: ObservableObject {
        @Published var driverLocation: CLLocationCoordinate2D?
        @Published var estimatedDistance: Double?
        
        private var driverLocationListener: ListenerRegistration?
        
        func startTrackingDriver(driverId: String) {
            guard !driverId.isEmpty else {
                print("❌ Cannot track driver: driverId is empty")
                return
            }
            
            print("🔍 Starting to track driver: \(driverId)")
            
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
                        print("⚠️ Driver location not available yet")
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
            print("🛑 Stopped tracking driver")
        }
    }
    
    #Preview {
        PassengerTrackingView(
            ride: Ride(
                id: "ride123",
                driverId: "driver1",
                driverName: "John Doe",
                driverGender: "male",
                fromAddress: "Hospital Road, Nandivaram",
                fromLat: 12.9716,
                fromLong: 77.5946,
                toAddress: "Chennai Central",
                toLat: 13.0827,
                toLong: 80.2707,
                date: Date(),
                availableSeats: 3,
                vehicleType: "Car",
                farePerKm: "10",
                genderPreference: ["male", "female", "all"],
                createdAt: Date()
            ),
            currentUser: AppUser(
                id: "passenger1",
                name: "Jane Smith",
                email: "jane@test.com",
                phone: "9999999999",
                gender: "female",
                vehicleType: nil,
                profilePicture: "",
                fcmToken: "",
                createdAt: Date()
            )
        )
    }
}
