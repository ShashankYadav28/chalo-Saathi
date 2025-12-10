import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import UIKit   // ✅ For UIApplication

// MARK: - My Bookings View
struct MyBookingsView: View {
    let currentUser: AppUser
    @StateObject private var viewModel = BookingsViewModel()
    @State private var selectedFilter: BookingFilter = .all
    @State private var selectedBooking: BookingDetails?
    
    enum BookingFilter: String, CaseIterable {
        case all = "All"
        case pending = "Pending"
        case accepted = "Accepted"
        case rejected = "Rejected"
        case cancelled = "Cancelled"
        
        var color: Color {
            switch self {
            case .all: return .blue
            case .pending: return .orange
            case .accepted: return .green
            case .rejected: return .red
            case .cancelled: return .gray
            }
        }
    }
    
    var filteredBookings: [BookingDetails] {
        switch selectedFilter {
        case .all:
            return viewModel.bookings
        case .pending:
            return viewModel.bookings.filter { $0.status == "pending" }
        case .accepted:
            return viewModel.bookings.filter { $0.status == "accepted" }
        case .rejected:
            return viewModel.bookings.filter { $0.status == "rejected" }
        case .cancelled:
            return viewModel.bookings.filter { $0.status == "cancelled" }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("My Bookings")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("\(viewModel.bookings.count) total rides")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 12)
                    
                    // Filter Tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(BookingFilter.allCases, id: \.self) { filter in
                                FilterChip(
                                    title: filter.rawValue,
                                    isSelected: selectedFilter == filter,
                                    count: countForFilter(filter),
                                    color: filter.color
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedFilter = filter
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    }
                }
                .background(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                
                // Content
                ZStack {
                    Color(.systemGroupedBackground)
                        .ignoresSafeArea()
                    
                    if viewModel.isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.3)
                            Text("Loading bookings...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    } else if filteredBookings.isEmpty {
                        EmptyBookingsView(filter: selectedFilter)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredBookings) { booking in
                                    BookingCard(
                                        booking: booking,
                                        onCancel: {
                                            // ✅ Only cancel if id exists
                                            if let id = booking.id {
                                                viewModel.cancelBooking(bookingId: id)
                                            } else {
                                                print("❌ Booking has no id, cannot cancel")
                                            }
                                        },
                                        onTrack: {
                                            // ✅ Avoid navigating if rideId is empty
                                            if booking.rideId.isEmpty {
                                                print("❌ Cannot track booking: empty rideId")
                                            } else {
                                                selectedBooking = booking
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(16)
                        }
                    }
                }
            }
            .navigationDestination(item: $selectedBooking) { booking in
                PassengerTrackingViewWrapper(booking: booking, currentUser: currentUser)
            }
            .task {
                // ✅ Use the SAME uid logic as MyRidesView
                let authId = Auth.auth().currentUser?.uid ?? ""
                let modelId = currentUser.id ?? ""
                let uid = authId.isEmpty ? modelId : authId
                
                if uid.isEmpty {
                    print("⚠️ MyBookingsView: both Auth.uid and currentUser.id are empty, skipping fetchBookings")
                } else {
                    print("🔍 MyBookingsView using passengerId: \(uid)")
                    viewModel.fetchBookings(passengerId: uid)
                }
            }
        }
    }
    
    func countForFilter(_ filter: BookingFilter) -> Int {
        switch filter {
        case .all:
            return viewModel.bookings.count
        case .pending:
            return viewModel.bookings.filter { $0.status == "pending" }.count
        case .accepted:
            return viewModel.bookings.filter { $0.status == "accepted" }.count
        case .rejected:
            return viewModel.bookings.filter { $0.status == "rejected" }.count
        case .cancelled:
            return viewModel.bookings.filter { $0.status == "cancelled" }.count
        }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let count: Int
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(isSelected ? color : .white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.3) : color)
                        )
                }
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? color : Color.gray.opacity(0.1))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : color.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Empty Bookings View
struct EmptyBookingsView: View {
    let filter: MyBookingsView.BookingFilter
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(filter.color.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: emptyIcon)
                    .font(.system(size: 50))
                    .foregroundColor(filter.color)
            }
            
            VStack(spacing: 8) {
                Text("No \(filter.rawValue) Bookings")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text(emptyMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    var emptyIcon: String {
        switch filter {
        case .all: return "calendar.badge.exclamationmark"
        case .pending: return "clock.fill"
        case .accepted: return "checkmark.circle.fill"
        case .rejected: return "xmark.circle.fill"
        case .cancelled: return "trash.circle.fill"
        }
    }
    
    var emptyMessage: String {
        switch filter {
        case .all:
            return "Your ride bookings will appear here. Start by searching for available rides."
        case .pending:
            return "No pending booking requests at the moment."
        case .accepted:
            return "No accepted bookings yet. Keep searching!"
        case .rejected:
            return "No rejected bookings."
        case .cancelled:
            return "No cancelled bookings."
        }
    }
}

// MARK: - Booking Card
struct BookingCard: View {
    let booking: BookingDetails
    let onCancel: () -> Void
    let onTrack: () -> Void
    @State private var showCancelAlert = false
    
    var statusColor: Color {
        switch booking.status {
        case "pending": return .orange
        case "accepted": return .green
        case "rejected": return .red
        case "cancelled": return .gray
        default: return .gray
        }
    }
    
    var statusIcon: String {
        switch booking.status {
        case "pending": return "clock.fill"
        case "accepted": return "checkmark.circle.fill"
        case "rejected": return "xmark.circle.fill"
        case "cancelled": return "trash.circle.fill"
        default: return "circle.fill"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with Driver Info
            HStack(spacing: 12) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 54, height: 54)
                    .overlay(
                        Text(booking.driverName.prefix(1).uppercased())
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .shadow(color: .blue.opacity(0.2), radius: 6, x: 0, y: 3)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(booking.driverName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 6) {
                        Image(systemName: statusIcon)
                            .font(.system(size: 12))
                        Text(booking.status.capitalized)
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if let date = booking.date {
                        Text(date, style: .date)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        Text(date, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("No date")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(16)
            
            Divider()
                .padding(.horizontal, 16)
            
            // Route Details
            VStack(spacing: 14) {
                RouteRow(
                    icon: "mappin.circle.fill",
                    iconColor: .green,
                    label: "FROM",
                    address: booking.fromAddress
                )
                
                RouteRow(
                    icon: "flag.fill",
                    iconColor: .red,
                    label: "TO",
                    address: booking.toAddress
                )
            }
            .padding(16)
            
            // Action Buttons
            if booking.status == "accepted" {
                Divider()
                    .padding(.horizontal, 16)
                
                HStack(spacing: 12) {
                    ActionButton(
                        icon: "phone.fill",
                        title: "Call",
                        color: .green
                    ) {
                        let phone = booking.driverPhone
                        if !phone.isEmpty,
                           let url = URL(string: "tel://\(phone)"),
                           UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        } else {
                            print("❌ Cannot call, invalid number or device cannot open tel://")
                        }
                    }
                    
                    ActionButton(
                        icon: "location.fill",
                        title: "Track Driver",
                        color: .blue
                    ) {
                        onTrack()
                    }
                }
                .padding(16)
                
            } else if booking.status == "pending" {
                Divider()
                    .padding(.horizontal, 16)
                
                Button(action: {
                    showCancelAlert = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                        Text("Cancel Booking")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.red, .red.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                }
                .padding(16)
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
        .alert("Cancel Booking?", isPresented: $showCancelAlert) {
            Button("Keep Booking", role: .cancel) { }
            Button("Cancel Booking", role: .destructive) {
                onCancel()
            }
        } message: {
            Text("Are you sure you want to cancel this booking? This action cannot be undone.")
        }
    }
}

// MARK: - Route Row
struct RouteRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let address: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .tracking(0.5)
                
                Text(address)
                    .font(.system(size: 15))
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [color, color.opacity(0.85)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(10)
        }
    }
}

// MARK: - Passenger Tracking View Wrapper
struct PassengerTrackingViewWrapper: View {
    let booking: BookingDetails
    let currentUser: AppUser
    
    @State private var ride: Ride?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Group {
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.3)
                    Text("Loading ride details...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else if let ride = ride {
                PassengerTrackingView(ride: ride, currentUser: currentUser)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    VStack(spacing: 8) {
                        Text("Unable to Load Ride")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    }
                    
                    Button(action: { dismiss() }) {
                        Text("Go Back")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
        }
        .task {
            await fetchRideDetails()
        }
    }
    
    private func fetchRideDetails() async {
        print("🔍 PassengerTrackingViewWrapper – bookingId=\(booking.id ?? "nil"), rideId='\(booking.rideId)'")

        if booking.rideId.isEmpty {
            await MainActor.run {
                errorMessage = "Invalid ride information"
                isLoading = false
            }
            return
        }

        do {
            let snapshot = try await Firestore.firestore()
                .collection("rides")
                .document(booking.rideId)
                .getDocument()

            if let rideData = try? snapshot.data(as: Ride.self) {
                await MainActor.run {
                    self.ride = rideData
                    self.isLoading = false
                }
                print("✅ Successfully loaded ride details for: \(booking.rideId)")
            } else {
                await MainActor.run {
                    self.errorMessage = "Ride details not found"
                    self.isLoading = false
                }
                print("❌ Ride not found in Firestore for id \(booking.rideId)")
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load ride: \(error.localizedDescription)"
                self.isLoading = false
            }
            print("❌ Error fetching ride: \(error)")
        }
    }
}

// MARK: - ViewModel
class BookingsViewModel: ObservableObject {
    @Published var bookings: [BookingDetails] = []
    @Published var isLoading = false
    
    private var listener: ListenerRegistration?
    
    func fetchBookings(passengerId: String) {
        guard !passengerId.isEmpty else {
            print("❌ Cannot fetch bookings: passengerId is empty")
            return
        }
        
        print("👀 Setting up bookings listener for passengerId:", passengerId)
        isLoading = true
        
        listener = Firestore.firestore()
            .collection("bookings")
            .whereField("passengerId", isEqualTo: passengerId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error fetching bookings: \(error)")
                    self.isLoading = false
                    return
                }
                
                let docs = snapshot?.documents ?? []
                print("📦 Bookings snapshot docs count:", docs.count)
                
                self.bookings = docs.compactMap { doc in
                    print("  • booking doc id:", doc.documentID)
                    print("    passengerId:", doc["passengerId"] ?? "nil")
                    print("    createdAt:", doc["createdAt"] ?? "nil")
                    return try? doc.data(as: BookingDetails.self)
                }
                
                print("✅ Fetched \(self.bookings.count) bookings")
                self.isLoading = false
            }
    }
    
    func cancelBooking(bookingId: String) {
        guard !bookingId.isEmpty else {
            print("❌ Cannot cancel booking: bookingId is empty")
            return
        }
        
        Firestore.firestore()
            .collection("bookings")
            .document(bookingId)
            .getDocument { snapshot, error in
                if let error = error {
                    print("❌ Failed to fetch booking details: \(error.localizedDescription)")
                    return
                }
                
                guard let data = snapshot?.data(),
                      let driverId = data["driverId"] as? String,
                      let passengerName = data["passengerName"] as? String,
                      let rideId = data["rideId"] as? String else {
                    print("❌ Missing booking data")
                    return
                }
                
                Firestore.firestore()
                    .collection("bookings")
                    .document(bookingId)
                    .updateData([
                        "status": "cancelled",
                        "cancelledAt": Timestamp(date: Date())
                    ]) { error in
                        if let error = error {
                            print("❌ Error cancelling booking: \(error)")
                        } else {
                            print("✅ Booking cancelled successfully")
                            
                            NotificationHelper.shared.notifyBookingCancelled(
                                driverId: driverId,
                                passengerName: passengerName,
                                bookingId: bookingId,
                                rideId: rideId
                            )
                        }
                    }
            }
    }
    
    deinit {
        listener?.remove()
    }
}

// MARK: - Preview
#Preview {
    MyBookingsView(
        currentUser: AppUser(
            id: "preview123",
            name: "John Doe",
            email: "john@example.com",
            phone: "+1234567890",
            gender: "male",
            createdAt: Date()
        )
    )
}
