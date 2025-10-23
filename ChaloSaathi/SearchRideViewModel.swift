//
//  SearchRideViewModel.swift
//  ChaloSaathi
//
//  Created by Shashank Yadav on 22/10/25.
//

import FirebaseFirestore
import FirebaseFirestoreCombineSwift

class SearchRideViewModel: ObservableObject {
    @Published var rides:[Ride] = []
    @Published var isLoading = false
    
    private var db = Firestore.firestore()
    
    func searchRides(from: String , to:String , date:Date , currentUserGender:String ){
        isLoading  = true
        rides.removeAll()
        
        var query: Query = db.collection("rides")
            .whereField("fromAddress", isGreaterThanOrEqualTo: from.capitalized)
            .whereField("fromAddress", isLessThanOrEqualTo: from.capitalized+"\u{f8ff}")
        
        if currentUserGender.lowercased() == "male" {
            query = query.whereField("driverGender", isEqualTo: "male")
        }
        else {
            
        }
        
        query.getDocuments{ snapshot, error in
            DispatchQueue.main.async {
                self.isLoading = false
            }
            
            if let error  = error {
                print("Rrror in fetching the rides \(error.localizedDescription)")
                return
            }
            
            guard let docs  = snapshot?.documents else {
                return
            }
            var fetchedRides = docs.compactMap { try? $0.data(as: Ride.self)} // )$.data tries to convert firestore object into Ride object
            
            fetchedRides = fetchedRides.filter {
                $0.toAddress.lowercased().contains(to.lowercased())
            }
            
            let calendar = Calendar.current
            fetchedRides = fetchedRides.filter {
                calendar.isDate($0.date, inSameDayAs: date)
            }
            DispatchQueue.main.async {
                self.rides = fetchedRides
            }
            
            
        }
    }
}
