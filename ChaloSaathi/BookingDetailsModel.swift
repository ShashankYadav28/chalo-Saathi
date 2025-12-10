import Foundation
import FirebaseFirestore


// MARK: - Booking Details Model
struct BookingDetails: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    
    var rideId: String           // ✅ make var so we can default it if needed
    let driverId: String
    let driverName: String
    let driverPhone: String
    let passengerId: String
    let passengerName: String
    let passengerPhone: String
    let fromAddress: String
    let toAddress: String
    
    @ServerTimestamp var date: Date?
    let status: String           // pending, accepted, rejected, cancelled
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
    
    // ✅ This makes sure decoding never crashes if rideId is missing,
    //    and logs so we can see the problem once.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id              = try c.decodeIfPresent(String.self, forKey: .id)
        rideId          = try c.decodeIfPresent(String.self, forKey: .rideId) ?? ""
        driverId        = try c.decode(String.self, forKey: .driverId)
        driverName      = try c.decode(String.self, forKey: .driverName)
        driverPhone     = try c.decode(String.self, forKey: .driverPhone)
        passengerId     = try c.decode(String.self, forKey: .passengerId)
        passengerName   = try c.decode(String.self, forKey: .passengerName)
        passengerPhone  = try c.decode(String.self, forKey: .passengerPhone)
        fromAddress     = try c.decode(String.self, forKey: .fromAddress)
        toAddress       = try c.decode(String.self, forKey: .toAddress)
        date            = try c.decodeIfPresent(Date.self, forKey: .date)
        status          = try c.decode(String.self, forKey: .status)
        createdAt       = try c.decodeIfPresent(Date.self, forKey: .createdAt)
        
        if rideId.isEmpty {
            print("⚠️ BookingDetails decoded with EMPTY rideId. bookingId=\(id ?? "nil")")
        }
    }
    
    // default memberwise init still auto-synthesised
}
