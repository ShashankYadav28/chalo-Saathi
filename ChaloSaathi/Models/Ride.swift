//
//  RiderModel.swift
//  ChaloSaathi
//
//  Created by Shashank Yadav on 08/10/25.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreCombineSwift

struct Ride: Identifiable, Codable {
    
    @DocumentID var id:String?
    let userId:String
    let userName: String
    let userGender: String
    let userProfile: String?
    
    
    let fromAddress: String
    let fromLat: Double
    let fromLong: Double
    
    let toAddress: String
    let toLat: String
    let toLong: String
    
    let date:Date
    let time: String
    let availableSeats:Int
    let vehicleType:String
    
    
    let farePerKm: Double?
    let TotalFare: Double?
    let estimatedDistance: Double?
    
    
    let allowGender:String
    
    let status: String
    let createdAt: Date
    
    
    enum CodingKeys:  String,CodingKey  {
        case id
        case userId
        case userName
        case userGender
        case userProfile
        case fromAddress
        case fromLat
        case fromLong
        
        case toAddress
        case toLat
        case toLong
        
        case date
        case time
        case availableSeats
        case vehicleType
        
        case farePerKm
        case TotalFare
        case estimatedDistance
        
        case allowGender
        
        case status
        case createdAt
        
       
        
        
    }
    
    
  
    
}


