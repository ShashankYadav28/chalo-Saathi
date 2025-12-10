import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import UIKit      // ✅ For phone call

// MARK: - Comprehensive My Rides View
struct MyRidesView: View {
    let currentUser: AppUser
    @StateObject private var viewModel = MyRidesViewModel()
    @State private var selectedTab: RideTab = .asPassenger
    
    // ✅ Navigation state
    @State private var passengerTrackingBooking: BookingDetails?
    @State private var driverTrackingRide: Ride?
    @State private var isShowingPassengerTracking = false
    @State private var isShowingDriverTracking = false
    
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
                            
                            Text(selectedTab == .asPassenger
                                 ? "\(viewModel.passengerBookings.count) bookings"
                                 : "\(viewModel.driverRides.count) rides")
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
                                    .font(.system(size: 14,
                                                  weight: selectedTab == tab ? .semibold : .medium))
                                    .foregroundColor(selectedTab == tab ? .white : .primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        selectedTab == tab
                                        ? LinearGradient(
                                            colors: [.blue, .blue.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                          )
                                        : LinearGradient(
                                            colors: [.gray.opacity(0.1), .gray.opacity(0.1)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                          )
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
            // ✅ Central navigation
            .navigationDestination(isPresented: $isShowingPassengerTracking) {
                if let booking = passengerTrackingBooking {
                    PassengerTrackingViewWrapper(booking: booking, currentUser: currentUser)
                } else {
                    Text("No booking selected")
                }
            }
            .navigationDestination(isPresented: $isShowingDriverTracking) {
                if let ride = driverTrackingRide {
                    DriverTrackingView(ride: ride, currentUser: currentUser)
                } else {
                    Text("No ride selected")
                }
            }
            .task {
                // Prefer Auth UID, fallback to AppUser id
                let authId = Auth.auth().currentUser?.uid ?? ""
                let modelId = currentUser.id ?? ""
                let uid = authId.isEmpty ? modelId : authId
                
                if uid.isEmpty {
                    print("⚠️ MyRidesView: both Auth.uid and currentUser.id are empty, skipping fetchAllRides")
                } else {
                    print("🔍 MyRidesView using userId: \(uid)")
                    await viewModel.fetchAllRides(userId: uid)
                }
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
                    ForEach(viewModel.passengerBookings.indices, id: \.self) { index in
                        let booking = viewModel.passengerBookings[index]
                        PassengerBookingCard(
                            booking: booking,
                            currentUser: currentUser
                        ) {
                            passengerTrackingBooking = booking
                            isShowingPassengerTracking = true
                        }
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
                    ForEach(viewModel.driverRides.indices, id: \.self) { index in
                        let ride = viewModel.driverRides[index]
                        DriverRideCard(
                            ride: ride,
                            currentUser: currentUser
                        ) {
                            if ride.status != "completed" {
                                driverTrackingRide = ride
                                isShowingDriverTracking = true
                            }
                        }
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


// MARK: - Passenger Booking Card
struct PassengerBookingCard: View {
    let booking: BookingDetails
    let currentUser: AppUser
    let onTrackTapped: () -> Void
    
    @State private var currentStatus: String
    @State private var showStatusAlert = false
    @State private var statusAlertMessage = ""
    @State private var bookingListener: ListenerRegistration?
    
    init(booking: BookingDetails, currentUser: AppUser, onTrackTapped: @escaping () -> Void) {
        self.booking = booking
        self.currentUser = currentUser
        self.onTrackTapped = onTrackTapped
        _currentStatus = State(initialValue: booking.status)
    }
    
    private var statusColor: Color {
        switch currentStatus {
        case "pending":   return .orange
        case "accepted":  return .green
        case "rejected":  return .red
        case "cancelled": return .gray
        default:          return .gray
        }
    }
    
    private var statusIcon: String {
        switch currentStatus {
        case "pending":   return "clock.fill"
        case "accepted":  return "checkmark.circle.fill"
        case "rejected":  return "xmark.circle.fill"
        case "cancelled": return "trash.circle.fill"
        default:          return "circle.fill"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Status row
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
                
                if let date = booking.date {
                    Text(date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Date pending")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Driver info
            HStack(spacing: 12) {
                Circle()
                    .fill(
                        LinearGradient(colors: [.blue, .purple],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing)
                    )
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
                HStack(spacing: 12) {
                    Button {
                        callDriver()
                    } label: {
                        HStack {
                            Image(systemName: "phone.fill")
                            Text("Call Driver")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .cornerRadius(10)
                    }
                    
                    Button {
                        onTrackTapped()
                    } label: {
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
        .alert(statusAlertMessage, isPresented: $showStatusAlert) {
            Button("OK", role: .cancel) { }
        }
        .onAppear { startListeningToBookingStatus() }
        .onDisappear { stopListening() }
    }
    
    // MARK: - Call Helper
    private func callDriver() {
        let phone = booking.driverPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !phone.isEmpty else {
            print("❌ callDriver: empty driverPhone")
            return
        }
        
        guard let url = URL(string: "tel://\(phone)") else {
            print("❌ callDriver: invalid URL for \(phone)")
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            print("⚠️ Device cannot open tel:// (simulator or unsupported)")
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
                
                if newStatus != currentStatus {
                    let oldStatus = currentStatus
                    currentStatus = newStatus
                    
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
    let onStartRide: () -> Void
    
    @State private var bookingCount = 0
    
    private var isCompleted: Bool {
        ride.status == "completed"
    }
    
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
            
            // Start / Completed button
            Button(action: {
                if !isCompleted {
                    onStartRide()
                }
            }) {
                HStack {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "location.fill")
                    Text(isCompleted ? "Completed" : "Start Ride")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: isCompleted
                        ? [.gray, .gray.opacity(0.7)]
                        : [.blue, .blue.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(10)
            }
            .disabled(isCompleted)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
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
        
        setupPassengerBookingsListener()
        setupDriverRidesListener(driverId: userId)
        
        isLoading = false
    }
    
    private func setupPassengerBookingsListener() {
        bookingsListener?.remove()
        
        print("🔍 MyRidesView – listening to ALL bookings")
        
        bookingsListener = Firestore.firestore()
            .collection("bookings")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error fetching bookings: \(error)")
                    self.passengerBookings = []
                    return
                }
                
                let docs = snapshot?.documents ?? []
                print("📦 ALL bookings docs:", docs.count)
                
                self.passengerBookings = docs.compactMap { doc in
                    print("  • booking doc id:", doc.documentID)
                    print("    passengerId:", doc["passengerId"] ?? "nil")
                    print("    status:", doc["status"] ?? "nil")
                    print("    createdAt:", doc["createdAt"] ?? "nil")
                    return try? doc.data(as: BookingDetails.self)
                }
                
                print("✅ passengerBookings count:", self.passengerBookings.count)
            }
    }
    
    private func setupDriverRidesListener(driverId: String) {
        guard !driverId.isEmpty else {
            print("❌ Cannot fetch driver rides: driverId is empty")
            return
        }
        
        ridesListener?.remove()
        
        print("🔍 MyRidesView – listening rides for driverId:", driverId)
        
        ridesListener = Firestore.firestore()
            .collection("rides")
            .whereField("driverId", isEqualTo: driverId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error fetching driver rides: \(error)")
                    self.driverRides = []
                    return
                }
                
                let docs = snapshot?.documents ?? []
                print("📦 driver rides docs:", docs.count)
                
                self.driverRides = docs.compactMap { doc in
                    print("  • ride doc id:", doc.documentID)
                    print("    driverId:", doc["driverId"] ?? "nil")
                    print("    status:", doc["status"] ?? "nil")
                    return try? doc.data(as: Ride.self)
                }
                
                print("✅ Fetched \(self.driverRides.count) driver rides")
            }
    }
    
    deinit {
        bookingsListener?.remove()
        ridesListener?.remove()
    }
}


// MARK: - Preview
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
