//
//  LocationsearchCompleter.swift
//  ChaloSaathi
//
//  Created by Shashank Yadav on 11/10/25.
//

import Foundation
import CoreLocation
import MapKit

class LocationsearchCompleter: NSObject,ObservableObject{
    
    private let completer  =  MKLocalSearchCompleter()
    @Published var searchresult : [MKLocalSearchCompletion] = []  // mklLocal search completion is an object that contains title and subtile
    
    @Published var searchQuery = "" {
        didSet {
            print("🟡 searchQuery changed to: \(searchQuery)")
            if searchQuery.isEmpty {
                searchresult = []
                
            }
            else {
                completer.queryFragment = searchQuery  // search query , it is containg text that has been entered , complete query.fragement is used for the searching the text
                print("🔵 completer.queryFragment set to: \(completer.queryFragment)")
            }
        }
        
    }
    
    override init() {
        super.init()  // super init is used so that nsobject is properly setup before we add own setup
        
        completer.delegate  =  self // in this we are telling completer object that beliongs to the locationcomplter class that when you find any error , call some deleegate methods that belongs to the the the locationSearch clsas
        
        completer.resultTypes = .address   // .result types is used for showing what types of it should show and by doing it equal to the .address measns we want the address in the a=search bar
        
        
    }
    
    func getCoordinate( for completion:MKLocalSearchCompletion, handler: @escaping (CLLocationCoordinate2D?,String?) -> Void ){
        let searchRequest = MKLocalSearch.Request(completion: completion)  // here we are making the search request
        let search  =  MKLocalSearch(request: searchRequest) // it creates the object that will talk to the srevers
        
        search.start { response,error  in                        // this line start asynchronous background learnig and return response and error
            if let error  =  error {
                print("search error \(error.localizedDescription)")
                handler(nil,nil)
                return
                
            }
            
            guard let item = response?.mapItems.first else {   // response .items gives the list of places map kit found  and we used the first because it is the most accurate
                handler(nil,nil)
                return
            }
            
            let coordinate  = item.placemark.coordinate
            
            let address  =  "\(completion.title),\(completion.subtitle)"
            handler(coordinate, address)
        }
    }
}

extension LocationsearchCompleter:MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        print("✅ completerDidUpdateResults called with \(completer.results.count) results")
        DispatchQueue.main.async {
            self.searchresult = completer.results
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: any Error) {
        print("Complete Error \(error.localizedDescription)")
    }
}
