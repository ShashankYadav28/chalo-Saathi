//
//  LocationManger.swift
//  ChaloSaathi
//
//  Created by Shashank Yadav on 03/10/25.
//

import SwiftUI
import CoreLocation  // it is the framework that give access to the current position and geographic data like current latitude and longitude

class LocationManger:NSObject , ObservableObject {
    
     var manager = CLLocationManager()
    
    @Published  var showLocationAlert = false
    @Published  var alertMessage = ""
    @Published  var canProceed = false
    
    override init(){
        super.init()
            manager.delegate = self // it is setting my current class the the listener for the manager object 
        
    }
    
    func requestPermission() {
        
        if !CLLocationManager.locationServicesEnabled() {
            alertMessage = "please enable the location from the setting"
            showLocationAlert = true
            return
        
        
        }
        manager.requestWhenInUseAuthorization()
    }
}



extension LocationManger: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {   // it is called when the status is chanmge
        DispatchQueue.main.async {
            switch manager.authorizationStatus {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
                
            case .restricted, .denied:
                self.alertMessage = " Location is denied. please enable from the settings "
                self.showLocationAlert = true
                
            case .authorizedAlways, .authorizedWhenInUse :
                print("location access is granted ")
                self.canProceed = true
                
            default:
                self.alertMessage = "unLnown Location status"
                self.showLocationAlert = true
            }
        }
    }
    
}
