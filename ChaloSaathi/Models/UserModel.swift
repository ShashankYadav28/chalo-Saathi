//
//  UserModel.swift
//  ChaloSaathi
//
//  Created by Shashank Yadav on 03/10/25.
//

import Foundation
import FirebaseFirestore

struct UserProfile: Identifiable,Codable  {
    @DocumentID var id:String?
    let  userId: String
    let  name: String
    let  email: String
    let  gender: String
    let  aadhaar: String?
    let  vehicleType: String?
    let  profilePicture: String?
    let  fcmToken: String?
    let  createdAt: Date
    
    enum CodingKeys: String , CodingKey {
        case id
        case userId
        case name
        case email
        case gender
        case aadhaar
        case vehicleType
        case profilePicture
        case fcmToken
        case createdAt
        
        
        
    }
    
    
}
