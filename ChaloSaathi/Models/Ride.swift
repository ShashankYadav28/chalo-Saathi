import Foundation
import FirebaseFirestore
import FirebaseFirestoreCombineSwift

struct Ride: Identifiable, Codable {
    @DocumentID var id: String?
    let driverId: String
    let driverName: String
    let driverGender: String
    
    let fromAddress: String
    let fromLat: Double
    let fromLong: Double
    
    let toAddress: String
    let toLat: Double
    let toLong: Double
    
    // ⭐ FIXED: Use single date field to match Firestore
    let date: Date
    let availableSeats: Int
    let vehicleType: String
    
    let farePerKm: String
    let genderPreference: [String]
    
    let createdAt: Date?
    
    // Optional: If you want to keep time separate, add custom decoding
    enum CodingKeys: String, CodingKey {
        case id
        case driverId
        case driverName
        case driverGender
        case fromAddress
        case fromLat
        case fromLong
        case toAddress
        case toLat
        case toLong
        case date
        case availableSeats
        case vehicleType
        case farePerKm
        case genderPreference
        case createdAt
    }
}
