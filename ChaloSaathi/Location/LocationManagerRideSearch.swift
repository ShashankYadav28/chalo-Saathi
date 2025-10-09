//
//  LocationManagerRideSearch.swift
//  ChaloSaathi
//
//  Created by Shashank Yadav on 09/10/25.
//

import Foundation
import CoreLocation
import MapKit

class LocationManagerRideSearch: NSObject , ObservableObject, CLLocationManagerDelegate {
    
    let locationManager = CLLocationManager()
    
    @Published var location : CLLocationCoordinate2D?
    @Published var currentAddress: String  = "Current Address "
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest  // it tell which accuracy i want better accuracy mean more battery drain
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        
        
    }
    func requestocation(){
        locationManager.requestLocation()
    }
    
    func getAddress(from location: CLLocationCoordinate2D, completion: (String) -> Void ){
        let geoCoder = CLGeocoder()
        let loc = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        geoCoder.reverseGeocodeLocation(loc) { placemark, error in
            if let error = error {
                print("reverse Geocoding Error \(error.localizedDescription)")
                return
                
            }
            
            if let placemark = placemark?.first {
                
                
            }
            else {
                print("unknown location ")
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


extens

