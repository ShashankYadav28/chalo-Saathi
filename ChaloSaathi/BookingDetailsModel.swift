import Foundation
import FirebaseFirestore

// MARK: - Booking Details Model
struct BookingDetails: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    let rideId: String
    let driverId: String
    let driverName: String
    let driverPhone: String
    let passengerId: String
    let passengerName: String
    let passengerPhone: String
    let fromAddress: String
    let toAddress: String
    @ServerTimestamp var date: Date?
    let status: String // pending, accepted, rejected, cancelled
    @ServerTimestamp var createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case rideId
        case driverId
        case driverName
        case driverPhone
        case passengerId
        case passengerName
        case passengerPhone
        case fromAddress
        case toAddress
        case date
        case status
        case createdAt
    }
}
