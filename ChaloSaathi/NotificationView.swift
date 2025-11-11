import SwiftUI
import FirebaseFirestore

// MARK: - Notifications View
struct NotificationsView: View {
    let currentUser: AppUser
    @StateObject private var viewModel = NotificationsViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notifications")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(viewModel.notifications.count) alerts")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !viewModel.notifications.isEmpty {
                    Button {
                        viewModel.markAllAsRead()
                    } label: {
                        Text("Mark All Read")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
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
                        Text("Loading notifications...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else if viewModel.notifications.isEmpty {
                    EmptyNotificationsView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.notifications) { notification in
                                NotificationCard(
                                    notification: notification,
                                    onTap: {
                                        viewModel.markAsRead(notificationId: notification.id ?? "")
                                    }
                                )
                            }
                        }
                        .padding(16)
                    }
                }
            }
        }
        .task {
            viewModel.fetchNotifications(userId: currentUser.id ?? "")
        }
    }
}

// MARK: - Empty Notifications View
struct EmptyNotificationsView: View {
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "bell.slash.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 8) {
                Text("No Notifications")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text("You're all caught up! Notifications about your rides will appear here.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Notification Card
struct NotificationCard: View {
    let notification: NotificationModel
    let onTap: () -> Void
    
    var iconName: String {
        switch notification.type {
        case "booking_accepted":
            return "checkmark.circle.fill"
        case "booking_rejected":
            return "xmark.circle.fill"
        case "booking_cancelled":
            return "trash.circle.fill"
        case "ride_reminder":
            return "clock.fill"
        case "new_booking":
            return "bell.fill"
        default:
            return "bell.fill"
        }
    }
    
    var iconColor: Color {
        switch notification.type {
        case "booking_accepted":
            return .green
        case "booking_rejected":
            return .red
        case "booking_cancelled":
            return .gray
        case "ride_reminder":
            return .orange
        case "new_booking":
            return .blue
        default:
            return .blue
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Icon
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: iconName)
                            .font(.system(size: 22))
                            .foregroundColor(iconColor)
                    )
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(notification.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text(notification.message)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                        Text(timeAgoString(from: notification.createdAt ?? Date()))
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.gray)
                }
                
                Spacer(minLength: 8)
                
                // Unread indicator
                if !notification.isRead {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 10, height: 10)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(notification.isRead ? Color.white : Color.blue.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(notification.isRead ? Color.clear : Color.blue.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func timeAgoString(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let day = components.day, day > 0 {
            return day == 1 ? "1 day ago" : "\(day) days ago"
        } else if let hour = components.hour, hour > 0 {
            return hour == 1 ? "1 hour ago" : "\(hour) hours ago"
        } else if let minute = components.minute, minute > 0 {
            return minute == 1 ? "1 minute ago" : "\(minute) minutes ago"
        } else {
            return "Just now"
        }
    }
}

// MARK: - Notification Model
struct NotificationModel: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let type: String
    let title: String
    let message: String
    var isRead: Bool
    let bookingId: String?
    let rideId: String?
    @ServerTimestamp var createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case type
        case title
        case message
        case isRead
        case bookingId
        case rideId
        case createdAt
    }
}

// MARK: - Notifications View Model
class NotificationsViewModel: ObservableObject {
    @Published var notifications: [NotificationModel] = []
    @Published var isLoading = false
    
    private var listener: ListenerRegistration?
    
    func fetchNotifications(userId: String) {
        guard !userId.isEmpty else {
            print("❌ Cannot fetch notifications: userId is empty")
            return
        }
        
        isLoading = true
        
        listener = Firestore.firestore()
            .collection("notifications")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error fetching notifications: \(error)")
                    self.isLoading = false
                    return
                }
                
                self.notifications = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: NotificationModel.self)
                } ?? []
                
                print("✅ Fetched \(self.notifications.count) notifications")
                self.isLoading = false
            }
    }
    
    func markAsRead(notificationId: String) {
        guard !notificationId.isEmpty else { return }
        
        Firestore.firestore()
            .collection("notifications")
            .document(notificationId)
            .updateData(["isRead": true]) { error in
                if let error = error {
                    print("❌ Error marking notification as read: \(error)")
                } else {
                    print("✅ Notification marked as read")
                }
            }
    }
    
    func markAllAsRead() {
        let unreadNotifications = notifications.filter { !$0.isRead }
        
        let batch = Firestore.firestore().batch()
        
        for notification in unreadNotifications {
            if let id = notification.id {
                let ref = Firestore.firestore().collection("notifications").document(id)
                batch.updateData(["isRead": true], forDocument: ref)
            }
        }
        
        batch.commit { error in
            if let error = error {
                print("❌ Error marking all as read: \(error)")
            } else {
                print("✅ All notifications marked as read")
            }
        }
    }
    
    deinit {
        listener?.remove()
    }
}

#Preview {
    NotificationsView(currentUser: AppUser(
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
