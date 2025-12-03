import Foundation
import CoreLocation
import MapKit

class LocationsearchCompleter: NSObject, ObservableObject {
    
    private let completer = MKLocalSearchCompleter()
    @Published var searchresult: [MKLocalSearchCompletion] = []
    
    @Published var searchQuery = "" {
        didSet {
            print("🟡 searchQuery changed to: '\(searchQuery)'")
            if searchQuery.isEmpty {
                searchresult = []
                completer.queryFragment = "" // Clear the fragment
            } else {
                // Update the completer's query fragment
                completer.queryFragment = searchQuery
                print("🔵 completer.queryFragment set to: '\(completer.queryFragment)'")
            }
        }
    }
    
    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest] // Show both addresses and POIs
        
        // Set region to India for better results
        completer.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 28.4595, longitude: 77.0266), // Gurgaon
            span: MKCoordinateSpan(latitudeDelta: 5.0, longitudeDelta: 5.0)
        )
        
        print("✅ LocationsearchCompleter initialized")
    }
    
    // Manual update method if needed
    func update(queryFragment: String) {
        print("🔍 Manual update called with: '\(queryFragment)'")
        completer.queryFragment = queryFragment
    }
    
    func getCoordinate(for completion: MKLocalSearchCompletion, handler: @escaping (CLLocationCoordinate2D?, String?) -> Void) {
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { response, error in
            if let error = error {
                print("❌ Search error: \(error.localizedDescription)")
                handler(nil, nil)
                return
            }
            
            guard let item = response?.mapItems.first else {
                print("❌ No map items found")
                handler(nil, nil)
                return
            }
            
            let coordinate = item.placemark.coordinate
            let address = "\(completion.title), \(completion.subtitle)"
            print("✅ Found coordinate: \(coordinate.latitude), \(coordinate.longitude)")
            print("   Address: \(address)")
            handler(coordinate, address)
        }
    }
}

extension LocationsearchCompleter: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        print("✅ completerDidUpdateResults called with \(completer.results.count) results")
        completer.results.forEach { result in
            print("   - \(result.title), \(result.subtitle)")
        }
        DispatchQueue.main.async {
            self.searchresult = completer.results
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("❌ Completer Error: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.searchresult = []
        }
    }
}
