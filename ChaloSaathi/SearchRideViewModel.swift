import FirebaseFirestore
import FirebaseFirestoreCombineSwift

class SearchRideViewModel: ObservableObject {
    @Published var rides: [Ride] = []
    @Published var isLoading = false
    
    private var db = Firestore.firestore()
    
    func searchRides(
        from: String,
        to: String,
        date: Date,
        currentUserGender: String,
        completion: @escaping (Ride?) -> Void
    ) {
        isLoading = true
        rides.removeAll()
        
        
        var query: Query = db.collection("rides")
            .whereField("fromAddress", isGreaterThanOrEqualTo: from.capitalized)
            .whereField("fromAddress", isLessThanOrEqualTo: from.capitalized + "\u{f8ff}")
        
        
        if currentUserGender.lowercased() == "male" {
            query = query.whereField("driverGender", isEqualTo: "male")
        }
       
        query.getDocuments { snapshot, error in
            DispatchQueue.main.async {
                self.isLoading = false
            }
            
            if let error = error {
                print("❌ Error fetching rides: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            guard let docs = snapshot?.documents else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            var fetchedRides = docs.compactMap { try? $0.data(as: Ride.self) }
            
            // 🟨 Step 4: Filter by destination
            fetchedRides = fetchedRides.filter {
                $0.toAddress.lowercased().contains(to.lowercased())
            }
            
            // 🟧 Step 5: Filter by same day
            let calendar = Calendar.current
            fetchedRides = fetchedRides.filter {
                calendar.isDate($0.date, inSameDayAs: date)
            }
            
            DispatchQueue.main.async {
                self.rides = fetchedRides
                completion(fetchedRides.first)
            }
        }
    }
}

