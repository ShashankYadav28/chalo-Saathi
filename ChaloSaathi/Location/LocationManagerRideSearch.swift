import Foundation
import CoreLocation
import MapKit

class LocationManagerRideSearch: NSObject, ObservableObject {
    
    let locationManager = CLLocationManager()
    
    @Published var location: CLLocationCoordinate2D?
    @Published var currentLocation: CLLocationCoordinate2D?   // 👈 NEW
    @Published var currentAddress: String  = "Current Location "
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func requestocation() {
        locationManager.requestLocation()
    }
    
    func getAddress(from location: CLLocationCoordinate2D, completion: @escaping (String) -> Void) {
        let geoCoder = CLGeocoder()
        let loc = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        geoCoder.reverseGeocodeLocation(loc) { placemark, error in
            if let error = error {
                print("reverse Geocoding Error \(error.localizedDescription)")
                completion("Unknown location")
                return
            }
            
            if let placemark = placemark?.first {
                let address = self.formatAddress(from: placemark)
                completion(address)
            } else {
                print("unknown location")
                completion("Unknown location")
            }
        }
    }
    
    func getCoordinates(from address: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let geocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(address) { placemarks, error in
            if let error  = error {
                print("geocodeAddressString error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            if let coordinate = placemarks?.first?.location?.coordinate {
                completion(coordinate)
            } else {
                completion(nil)
            }
        }
    }
    
    func calculatetheDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation) / 1000
    }
    
    private func formatAddress(from placemark: CLPlacemark) -> String {
        var components: [String] = []
        
        if let name = placemark.name {
            components.append(name)
        }
        if let locality = placemark.locality {
            components.append(locality)
        }
        if let area = placemark.administrativeArea {
            components.append(area)
        }
        
        return components.joined(separator: ", ")
    }
}

extension LocationManagerRideSearch: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        let coord = location.coordinate
        
        DispatchQueue.main.async {
            self.location = coord
            self.currentLocation = coord       // 👈 keep in sync
        }
        
        getAddress(from: coord) { address in
            DispatchQueue.main.async {
                self.currentAddress = address
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        print("Location Error  \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.authorizationStatus  = manager.authorizationStatus
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            print("location can not be accessed")
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            print("Not able to determine the location")
        }
    }
}
