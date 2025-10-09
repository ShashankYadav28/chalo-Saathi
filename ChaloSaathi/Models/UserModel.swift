//
//  UserModel.swift
//  ChaloSaathi
//
//  Created by Shashank Yadav on 03/10/25.
//

struct UserProfile : Codable  {
    let id: String
    let name: String
    let email: String
    let gender: String
    let aadhaar: String?
    let vehicleType: String?
    
    
}
