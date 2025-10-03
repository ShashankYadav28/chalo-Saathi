//
//  LocationManger.swift
//  ChaloSaathi
//
//  Created by Shashank Yadav on 03/10/25.
//

import SwiftUI
import CoreLocation

class LocationManger:NSObject , ObservableObject {
    
    private var manager = CLLocationManager()
    
    @Published  var showLocationAlert = false
    @Published  var alertMessage = ""
    
    override init(){            //
        super.init()
            manager.delegate = self
        
    }
    
    func checkLocationPermission() {
        
        if !CLLocationManager.locationServicesEnabled() {
            alertMessage = "please enable the location from the setting"
            showLocationAlert = true
            return
        }
        
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            
        case .restricted, .denied:
            alertMessage = " Location is denied. please enable from the settings "
            showLocationAlert = true
        
        case .authorizedAlways, .authorizedWhenInUse :
            print("location access is granted ")
            
        default:
            alertMessage = "unLnown Location status"
            showLocationAlert = true
            
            
            
        
        }
    }
}



extension LocationManger: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationPermission()
    }
    
}
