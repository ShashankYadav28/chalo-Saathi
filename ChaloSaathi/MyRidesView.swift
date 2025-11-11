import SwiftUI
import FirebaseFirestore

// MARK: - Comprehensive My Rides View
struct MyRidesView: View {
    let currentUser: AppUser
    @StateObject private var viewModel = MyRidesViewModel()
    @State private var selectedTab: RideTab = .asPassenger
    
    enum RideTab: String, CaseIterable {
        case asPassenger = "As Passenger"
        case asDriver = "As Driver"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("My Rides")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(selectedTab == .asPassenger ? "\(viewModel.passengerBookings.count) bookings" : "\(viewModel.driverRides.count) rides")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 12)
                    
                    // Tab Switcher
                    HStack(spacing: 8) {
                        ForEach(RideTab.allCases, id: \.self) { tab in
                            Button(action: {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedTab = tab
                                }
                            }) {
                                Text(tab.rawValue)
                                    .font(.system(size: 14, weight: selectedTab == tab ? .semibold : .medium))
                                    .foregroundColor(selectedTab == tab ? .white : .primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        selectedTab == tab ?
                                        LinearGradient(colors: [.blue, .blue.opacity(0.8)], startPoint: .leading, endPoint: .trailing) :
                                        LinearGradient(colors: [.gray.opacity(0.1), .gray.opacity(0.1)], startPoint: .leading, endPoint: .trailing)
                                    )
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
                .background(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                
                // Content
                ZStack {
                    Color(.systemGroupedBackground)
                        .ignoresSafeArea()
                    
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Group {
                            if selectedTab == .asPassenger {
                                passengerBookingsView
                            } else {
                                driverRidesView
                            }
                        }
                    }
                }
            }
            .task {
                await viewModel.fetchAllRides(userId: currentUser.id ?? "")
            }
        }
    }
    
    // MARK: - Passenger Bookings View
    private var passengerBookingsView: some View {
        ScrollView {
            if viewModel.passengerBookings.isEmpty {
                EmptyStateView(
                    icon: "car.fill",
                    title: "No Bookings Yet",
                    message: "Your ride bookings will appear here"
                )
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.passengerBookings) { booking in
                        PassengerBookingCard(booking: booking, currentUser: currentUser)
                    }
                }
                .padding(16)
            }
        }
    }
    
    // MARK: - Driver Rides View
    private var driverRidesView: some View {
        ScrollView {
            if viewModel.driverRides.isEmpty {
                EmptyStateView(
                    icon: "car.2.fill",
                    title: "No Published Rides",
                    message: "Rides you publish will appear here"
                )
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.driverRides) { ride in
                        DriverRideCard(ride: ride, currentUser: currentUser)
                    }
                }
                .padding(16)
            }
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.5))
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .padding(.top, 100)
    }
}

// MARK: - Enhanced Passenger Booking Card with Real-time Updates
struct PassengerBookingCard: View {
    let booking: BookingDetails
    let currentUser: AppUser
    @State private var showTrackingView = false
    @State private var currentStatus: String
    @State private var showStatusAlert = false
    @State private var statusAlertMessage = ""
    @State private var bookingListener: ListenerRegistration?
    
    init(booking: BookingDetails, currentUser: AppUser) {
        self.booking = booking
        self.currentUser = currentUser
        self._currentStatus = State(initialValue: booking.status)
    }
    
    var statusColor: Color {
        switch currentStatus {
        case "pending": return .orange
        case "accepted": return .green
        case "rejected": return .red
        case "cancelled": return .gray
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Status Badge
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: statusIcon)
                        .font(.system(size: 12))
                    Text(currentStatus.capitalized)
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(statusColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(statusColor.opacity(0.15))
                .cornerRadius(20)
                
                Spacer()
                
                Text(booking.date ?? Date(), style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Driver Info
            HStack(spacing: 12) {
                Circle()
                    .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(booking.driverName.prefix(1).uppercased())
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(booking.driverName)
                        .font(.system(size: 16, weight: .semibold))
                    Text("Driver")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
            
            // Route
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.green)
                    Text(booking.fromAddress)
                        .font(.system(size: 14))
                        .lineLimit(1)
                    Spacer()
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "flag.fill")
                        .foregroundColor(.red)
                    Text(booking.toAddress)
                        .font(.system(size: 14))
                        .lineLimit(1)
                    Spacer()
                }
            }
            
            // Actions
            if currentStatus == "accepted" {
                Button(action: { showTrackingView = true }) {
                    HStack {
                        Image(systemName: "location.fill")
                        Text("Track Ride")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
            } else if currentStatus == "pending" {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Waiting for driver response...")
                        .font(.system(size: 13))
                        .foregroundColor(.orange)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        .navigationDestination(isPresented: $showTrackingView) {
            PassengerTrackingViewWrapper(booking: booking, currentUser: currentUser)
        }
        .alert(statusAlertMessage, isPresented: $showStatusAlert) {
            Button("OK", role: .cancel) { }
        }
        .onAppear {
            startListeningToBookingStatus()
        }
        .onDisappear {
            stopListening()
        }
    }
    
    private var statusIcon: String {
        switch currentStatus {
        case "pending": return "clock.fill"
        case "accepted": return "checkmark.circle.fill"
        case "rejected": return "xmark.circle.fill"
        case "cancelled": return "trash.circle.fill"
        default: return "circle.fill"
        }
    }
    
    // MARK: - Real-time Booking Status Listener
    private func startListeningToBookingStatus() {
        guard let bookingId = booking.id, !bookingId.isEmpty else {
            print("❌ Cannot listen to booking: bookingId is empty")
            return
        }
        
        bookingListener = Firestore.firestore()
            .collection("bookings")
            .document(bookingId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ Error listening to booking status: \(error)")
                    return
                }
                
                guard let data = snapshot?.data(),
                      let newStatus = data["status"] as? String else {
                    return
                }
                
                // Only update if status changed
                if newStatus != currentStatus {
                    let oldStatus = currentStatus
                    currentStatus = newStatus
                    
                    // Show alert for status changes
                    if oldStatus == "pending" && newStatus == "accepted" {
                        statusAlertMessage = "🎉 Your ride has been accepted! The driver will pick you up soon."
                        showStatusAlert = true
                    } else if oldStatus == "pending" && newStatus == "rejected" {
                        statusAlertMessage = "❌ Your booking was not accepted. Please try another ride."
                        showStatusAlert = true
                    }
                    
                    print("✅ Booking status updated: \(oldStatus) → \(newStatus)")
                }
            }
    }
    
    private func stopListening() {
        bookingListener?.remove()
        bookingListener = nil
        print("🛑 Stopped listening to booking status")
    }
}

// MARK: - Driver Ride Card
struct DriverRideCard: View {
    let ride: Ride
    let currentUser: AppUser
    @State private var showTrackingView = false
    @State private var bookingCount = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "car.fill")
                        .font(.system(size: 12))
                    Text("\(ride.availableSeats) seats")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green)
                .cornerRadius(20)
                
                Spacer()
                
                Text(ride.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Route
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.green)
                    Text(ride.fromAddress)
                        .font(.system(size: 14))
                        .lineLimit(1)
                    Spacer()
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "flag.fill")
                        .foregroundColor(.red)
                    Text(ride.toAddress)
                        .font(.system(size: 14))
                        .lineLimit(1)
                    Spacer()
                }
            }
            
            Divider()
            
            // Stats
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("FARE")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("₹\(ride.farePerKm)/km")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("BOOKINGS")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(bookingCount)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.blue)
                }
            }
            
            // Action Button
            Button(action: { showTrackingView = true }) {
                HStack {
                    Image(systemName: "location.fill")
                    Text("Start Ride")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(colors: [.blue, .blue.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(10)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        .navigationDestination(isPresented: $showTrackingView) {
            DriverTrackingView(ride: ride, currentUser: currentUser)
        }
        .task {
            await fetchBookingCount()
        }
    }
    
    private func fetchBookingCount() async {
        guard let rideId = ride.id else { return }
        
        do {
            let snapshot = try await Firestore.firestore()
                .collection("bookings")
                .whereField("rideId", isEqualTo: rideId)
                .whereField("status", in: ["pending", "accepted"])
                .getDocuments()
            
            await MainActor.run {
                bookingCount = snapshot.documents.count
            }
        } catch {
            print("❌ Error fetching booking count: \(error)")
        }
    }
}

// MARK: - My Rides View Model
class MyRidesViewModel: ObservableObject {
    @Published var passengerBookings: [BookingDetails] = []
    @Published var driverRides: [Ride] = []
    @Published var isLoading = false
    
    private var bookingsListener: ListenerRegistration?
    private var ridesListener: ListenerRegistration?
    
    @MainActor
    func fetchAllRides(userId: String) async {
        guard !userId.isEmpty else {
            print("❌ Cannot fetch rides: userId is empty")
            return
        }
        
        isLoading = true
        
        // Fetch passenger bookings
        fetchPassengerBookings(userId: userId)
        
        // Fetch driver rides
        fetchDriverRides(userId: userId)
        
        isLoading = false
    }
    
    private func fetchPassengerBookings(userId: String) {
        bookingsListener = Firestore.firestore()
            .collection("bookings")
            .whereField("passengerId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error fetching bookings: \(error)")
                    return
                }
                
                self.passengerBookings = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: BookingDetails.self)
                } ?? []
                
                print("✅ Fetched \(self.passengerBookings.count) passenger bookings")
            }
    }
    
    private func fetchDriverRides(userId: String) {
        ridesListener = Firestore.firestore()
            .collection("rides")
            .whereField("driverId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error fetching driver rides: \(error)")
                    return
                }
                
                self.driverRides = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: Ride.self)
                } ?? []
                
                print("✅ Fetched \(self.driverRides.count) driver rides")
            }
    }
    
    deinit {
        bookingsListener?.remove()
        ridesListener?.remove()
    }
}

#Preview {
    MyRidesView(currentUser: AppUser(
        id: "1",
        name: "Test User",
        email: "test@test.com",
        phone: "9999999999",
        gender: "male",
        vehicleType: "car",
        profilePicture: "",
        fcmToken: "",
        createdAt: Date()
    ))
}
