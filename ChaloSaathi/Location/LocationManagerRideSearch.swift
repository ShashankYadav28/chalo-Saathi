//
//  LocationManagerRideSearch.swift
//  ChaloSaathi
//
//  Created by Shashank Yadav on 09/10/25.
//

import Foundation
import CoreLocation
import MapKit

class LocationManagerRideSearch: NSObject , ObservableObject {
    
    let locationManager = CLLocationManager()
    
    @Published var location : CLLocationCoordinate2D?
    @Published var currentAddress: String  = "Current Location "
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    
    override init() {
        super.init()
        locationManager.delegate = self  // location manger delegate is used as it recieves the data about the changes , when tell these changes to this object that is CClocationMangerDelegate
        locationManager.desiredAccuracy = kCLLocationAccuracyBest  // it tell which accuracy i want better accuracy mean more battery drain
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        
        
    }
    func requestocation(){
        locationManager.requestLocation()
    }
    
    func getAddress(from location: CLLocationCoordinate2D, completion: @escaping(String) -> Void ){
        let geoCoder = CLGeocoder()
        let loc = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        geoCoder.reverseGeocodeLocation(loc) { placemark, error in
            if let error = error {
                print("reverse Geocoding Error \(error.localizedDescription)")
                completion("Unknown completion")
                return
                
            }
            
            if let placemark = placemark?.first {
                
                let address = self.formatAddress(from: placemark)
                completion(address)
            }
            else {
                print("unknown location ")
                completion("unknown string ")
            }
        }
    }
    
    func getCoordinates(from address: String , completion: @escaping(CLLocationCoordinate2D?) -> Void ){
        
        let geocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(address){ placemarks, error in
            
            if let error  =  error {
                print("geocodeAddress to string error is there \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            if let coordinate = placemarks?.first?.location?.coordinate {
                completion(coordinate)
                
            }
            else {
                completion(nil)
            }
            
        }
        
        
    }
    
    func calculatetheDistance(from:CLLocationCoordinate2D , to:CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        
        return fromLocation.distance(from: toLocation)/1000
    }
    
    private func formatAddress(from placemark: CLPlacemark) ->String {
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
        
        return components.joined(separator: ",")
    }
    
}


extension LocationManagerRideSearch: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let location = locations.last else {
            return
            
        }
        
        DispatchQueue.main.async{
            self.location = location.coordinate
        }
        
        getAddress(from: location.coordinate) { address in
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
        case .authorizedWhenInUse,.authorizedAlways:
            locationManager.startUpdatingLocation()
            
        case.denied,.restricted:
            print("location can  not be accessed ")
            
        case .notDetermined :
            locationManager.requestWhenInUseAuthorization()
        @unknown default :
            print(" Not able to detetermined the location ")
        }
    }
    
    
}
        
        

