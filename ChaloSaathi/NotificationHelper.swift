import Foundation
import FirebaseFirestore

// MARK: - Notification Helper
class NotificationHelper {
    static let shared = NotificationHelper()
    
    private init() {}
    
    // MARK: - Create Notification
    func createNotification(
        userId: String,
        type: String,
        title: String,
        message: String,
        bookingId: String? = nil,
        rideId: String? = nil
    ) {
        guard !userId.isEmpty else {
            print("❌ Cannot create notification: userId is empty")
            return
        }
        
        let notificationRef = Firestore.firestore().collection("notifications").document()
        
        let notificationData: [String: Any] = [
            "id": notificationRef.documentID,
            "userId": userId,
            "type": type,
            "title": title,
            "message": message,
            "isRead": false,
            "bookingId": bookingId ?? "",
            "rideId": rideId ?? "",
            "createdAt": Timestamp(date: Date())
        ]
        
        notificationRef.setData(notificationData) { error in
            if let error = error {
                print("❌ Failed to create notification: \(error.localizedDescription)")
            } else {
                print("✅ Notification created successfully for user: \(userId)")
            }
        }
    }
    
    // MARK: - Booking Accepted
    func notifyBookingAccepted(
        passengerId: String,
        passengerName: String,
        driverName: String,
        bookingId: String,
        rideId: String
    ) {
        createNotification(
            userId: passengerId,
            type: "booking_accepted",
            title: "Ride Confirmed! 🎉",
            message: "\(driverName) has accepted your booking request. Get ready for your ride!",
            bookingId: bookingId,
            rideId: rideId
        )
    }
    
    // MARK: - Booking Rejected
    func notifyBookingRejected(
        passengerId: String,
        passengerName: String,
        driverName: String,
        bookingId: String,
        rideId: String
    ) {
        createNotification(
            userId: passengerId,
            type: "booking_rejected",
            title: "Booking Not Accepted",
            message: "\(driverName) couldn't accept your booking request. Please try another ride.",
            bookingId: bookingId,
            rideId: rideId
        )
    }
    
    // MARK: - New Booking Request
    func notifyNewBooking(
        driverId: String,
        passengerName: String,
        bookingId: String,
        rideId: String
    ) {
        createNotification(
            userId: driverId,
            type: "new_booking",
            title: "New Booking Request! 🚗",
            message: "\(passengerName) wants to book your ride. Check and respond!",
            bookingId: bookingId,
            rideId: rideId
        )
    }
    
    // MARK: - Booking Cancelled
    func notifyBookingCancelled(
        driverId: String,
        passengerName: String,
        bookingId: String,
        rideId: String
    ) {
        createNotification(
            userId: driverId,
            type: "booking_cancelled",
            title: "Booking Cancelled",
            message: "\(passengerName) has cancelled their booking.",
            bookingId: bookingId,
            rideId: rideId
        )
    }
    
    // MARK: - Ride Reminder
    func notifyRideReminder(
        userId: String,
        rideDetails: String,
        rideId: String
    ) {
        createNotification(
            userId: userId,
            type: "ride_reminder",
            title: "Ride Reminder ⏰",
            message: "Your ride \(rideDetails) is coming up soon!",
            rideId: rideId
        )
    }
}
