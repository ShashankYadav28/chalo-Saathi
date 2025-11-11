//
//  AppUser.swift
//  ChaloSaathi
//
//  Unified user model - use this EVERYWHERE
//

import SwiftUI
import Foundation
import FirebaseFirestore

// ✅ MAIN USER MODEL - Use this everywhere in your app
struct AppUser: Codable, Identifiable {
    @DocumentID var id: String?
    let name: String
    let email: String
    let phone: String           // Required
    let gender: String          // Required
    let vehicleType: String?    // Optional - can be nil
    let aadhaar: String?        // Optional - for backward compatibility
    let profilePicture: String? // Optional
    let fcmToken: String?       // Optional
    let createdAt: Date?        // Optional - for backward compatibility
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case phone
        case gender
        case vehicleType
        case aadhaar
        case profilePicture
        case fcmToken
        case createdAt
    }
    
    // Custom decoder to handle missing fields gracefully
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields
        name = try container.decode(String.self, forKey: .name)
        email = try container.decode(String.self, forKey: .email)
        phone = try container.decode(String.self, forKey: .phone)
        gender = try container.decode(String.self, forKey: .gender)
        
        // Optional fields - won't crash if missing
        vehicleType = try? container.decode(String.self, forKey: .vehicleType)
        aadhaar = try? container.decode(String.self, forKey: .aadhaar)
        profilePicture = try? container.decode(String.self, forKey: .profilePicture)
        fcmToken = try? container.decode(String.self, forKey: .fcmToken)
        createdAt = try? container.decode(Date.self, forKey: .createdAt)
        
        // ID is handled by @DocumentID
        _id = try container.decodeIfPresent(DocumentID<String>.self, forKey: .id) ?? DocumentID(wrappedValue: nil)
    }
    
    // Standard initializer for creating new users
    init(
        id: String? = nil,
        name: String,
        email: String,
        phone: String,
        gender: String,
        vehicleType: String? = nil,
        aadhaar: String? = nil,
        profilePicture: String? = nil,
        fcmToken: String? = nil,
        createdAt: Date? = nil
    ) {
        self._id = DocumentID(wrappedValue: id)
        self.name = name
        self.email = email
        self.phone = phone
        self.gender = gender
        self.vehicleType = vehicleType
        self.aadhaar = aadhaar
        self.profilePicture = profilePicture
        self.fcmToken = fcmToken
        self.createdAt = createdAt ?? Date()
    }
}

// MARK: - Helper Extensions
extension AppUser {
    var initials: String {
        name.prefix(1).uppercased()
    }
    
    var hasVehicle: Bool {
        vehicleType != nil && !vehicleType!.isEmpty
    }
    
    var displayGender: String {
        gender.capitalized
    }
    
    var displayVehicle: String {
        vehicleType?.capitalized ?? "Not Set"
    }
}
