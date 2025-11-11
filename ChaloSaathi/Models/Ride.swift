import Foundation
import FirebaseFirestore

struct Ride: Identifiable, Codable {
    @DocumentID var id: String?
    let driverId: String
    let driverName: String
    let driverPhone: String?
    let driverGender: String
    
    let fromAddress: String
    let fromLat: Double
    let fromLong: Double
    
    let toAddress: String
    let toLat: Double
    let toLong: Double
    
    let date: Date
    let availableSeats: Int
    let vehicleType: String
    
    let farePerKm: String
    let genderPreference: [String]
    
    let status: String?
    let passengers: [String]?
    
    @ServerTimestamp var createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case driverId
        case driverName
        case driverPhone
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
        case status
        case passengers
        case createdAt
    }
    
    // Custom initializer
    init(
        id: String? = nil,
        driverId: String,
        driverName: String,
        driverPhone: String? = nil,
        driverGender: String,
        fromAddress: String,
        fromLat: Double,
        fromLong: Double,
        toAddress: String,
        toLat: Double,
        toLong: Double,
        date: Date,
        availableSeats: Int,
        vehicleType: String,
        farePerKm: String,
        genderPreference: [String],
        status: String? = "active",
        passengers: [String]? = [],
        createdAt: Date? = nil
    ) {
        self._id = DocumentID(wrappedValue: id)
        self.driverId = driverId
        self.driverName = driverName
        self.driverPhone = driverPhone
        self.driverGender = driverGender
        self.fromAddress = fromAddress
        self.fromLat = fromLat
        self.fromLong = fromLong
        self.toAddress = toAddress
        self.toLat = toLat
        self.toLong = toLong
        self.date = date
        self.availableSeats = availableSeats
        self.vehicleType = vehicleType
        self.farePerKm = farePerKm
        self.genderPreference = genderPreference
        self.status = status
        self.passengers = passengers
        self.createdAt = createdAt
    }
    
    // Custom decoder to handle missing optional fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields
        driverId = try container.decode(String.self, forKey: .driverId)
        driverName = try container.decode(String.self, forKey: .driverName)
        driverGender = try container.decode(String.self, forKey: .driverGender)
        fromAddress = try container.decode(String.self, forKey: .fromAddress)
        fromLat = try container.decode(Double.self, forKey: .fromLat)
        fromLong = try container.decode(Double.self, forKey: .fromLong)
        toAddress = try container.decode(String.self, forKey: .toAddress)
        toLat = try container.decode(Double.self, forKey: .toLat)
        toLong = try container.decode(Double.self, forKey: .toLong)
        date = try container.decode(Date.self, forKey: .date)
        availableSeats = try container.decode(Int.self, forKey: .availableSeats)
        vehicleType = try container.decode(String.self, forKey: .vehicleType)
        farePerKm = try container.decode(String.self, forKey: .farePerKm)
        genderPreference = try container.decode([String].self, forKey: .genderPreference)
        
        // Optional fields
        driverPhone = try? container.decode(String.self, forKey: .driverPhone)
        status = try? container.decode(String.self, forKey: .status)
        passengers = try? container.decode([String].self, forKey: .passengers)
        createdAt = try? container.decode(Date.self, forKey: .createdAt)
        
        // ID handled by @DocumentID
        _id = try container.decodeIfPresent(DocumentID<String>.self, forKey: .id) ?? DocumentID(wrappedValue: nil)
        _createdAt = try container.decodeIfPresent(ServerTimestamp<Date>.self, forKey: .createdAt) ?? ServerTimestamp(wrappedValue: nil)
    }
}
