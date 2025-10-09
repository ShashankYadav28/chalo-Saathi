//
//  AppuserProfile .swift
//  ChaloSaathi
//
//  Created by Shashank Yadav on 08/10/25.
//

import SwiftUI
import Foundation
import FirebaseFirestore

struct AppUser: Codable,Identifiable {
    @DocumentID var id : String?
    let name: String
    let email: String
    let phone: String
    let gender: String
    let vehicleType: String?
    let profilePicture: String?
    let fcmToken: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case  id
        case  name
        case  email
        case  phone
        case  gender
        case  vehicleType
        case  profilePicture
        case  fcmToken
        case  createdAt
        
    }


}


