//
//  SearchRideView.swift
//  ChaloSaathi
//
//  Created by Shashank Yadav on 15/10/25.
//

import SwiftUI
import MapKit

struct SearchRideView: View {
    
    @StateObject var locationManager: LocationManagerRideSearch
    let currentUser:AppUser?
    
    @State private var fromAddress: String = ""
    @State private var toAddress: String  = ""
    @State private var selectedDate  = Date()
    @State private var selectedTime  = Date()
    @State private var showingdestinationSearch  = false
    
    @State private var fromCoordinate: CLLocationCoordinate2D?
    @State private var toCoordinate: CLLocationCoordinate2D?
    
    @StateObject private var locationSearchCompleter = LocationsearchCompleter()
    var body: some View {
        
        VStack(spacing: 16) {
            
            
            fromView(icon: "mappinCircle", locationManager:locationManager)
            
            
            Spacer()
            
            if locationManager.location != nil {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.green)
                    .allowsHitTesting(false)
                
            }
            
            
            ZStack(alignment: .topLeading) {
                VStack(spacing: 0) {
                    // 🟩 Search bar
                    HStack(spacing: 12) {
                        Image(systemName: "flag")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                        
                        Text("TO:")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.primary)
                        
                        TextField("Where are you going?", text: $locationSearchCompleter.searchQuery)
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                        
                        if locationManager.location != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    )
                    .padding(.horizontal, 20)
                }
                
                // 🟦 Overlay suggestions
                if !locationSearchCompleter.searchresult.isEmpty {
                    ScrollView {
                        ForEach(Array(locationSearchCompleter.searchresult.enumerated()), id: \.offset) { index, result in
                            Button {
                                selectLocation(result)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(result.title)
                                        .font(.headline)
                                    Text(result.subtitle)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                .padding(8)
                            }
                            if index != locationSearchCompleter.searchresult.count - 1 {
                                Divider()
                            }
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(radius: 5)
                    .frame(maxHeight: 200)
                    .padding(.horizontal, 40)
                    .padding(.top, 60) // Push below TextField
                    .zIndex(1)
                }
            }
            
            
            
            
            /*.onTapGesture {
             showingdestinationSearch = true
             }
             .onChange(of: locationSearchCompleter.searchQuery) { oldValue,newValue in
             print("🔍 User typing: \(newValue)")
             }*/
            
           
            
            /*if showingdestinationSearch {
             Divider()
             ScrollView {
             VStack(spacing: 0){
             
             searchSuggestion(completer: locationSearchCompleter, onSelect:{completion in  selectLocation(completion)
             showingdestinationSearch = false
             
             })
             }
             
             }
             .frame(maxHeight:200)
             // .background(Color.white)
             .background(
             RoundedRectangle(cornerRadius: 12)
             .fill(Color.white)
             .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
             )
             .padding(.horizontal, 20)
             }*/
            
            
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "clock")
                        .font(.system(size:20))
                        .foregroundColor(.primary)
                    
                    Text("TIME:")
                        .font(.system(size: 16,weight: .regular))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    DatePicker("", selection: $selectedTime, displayedComponents: [.date,.hourAndMinute])
                        .labelsHidden()
                }
                .padding(.vertical,12)
                .padding(.horizontal)
                
                Button( action: {}){
                    HStack {
                        Image(systemName: "magnyfyingglass")
                            .font(.system(size: 18,weight:.bold))
                            .foregroundColor(.white)
                        
                        Text("Find Rides")
                            .font(.system(size: 22,weight:.bold))
                            .foregroundColor(.white)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth:.infinity)
                    .padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient(colors: [Color.blue,Color.blue.opacity(0.3)], startPoint: .leading, endPoint: .trailing))
                    )
                    .shadow(color: .blue.opacity(0.3), radius: 10, x:0,y:5)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .disabled(true)
                // .opacity(toAddress.isEmpty ? 0.5 : 1)
                
                HStack {
                    QuickActionButton(icon: "star", title: "Saved Routes")
                    QuickActionButton(icon: "shield.checkered",title: "Safety Routes")
                    QuickActionButton(icon: "dollarsign.circle",title: "Earnings")
                }
                .padding(.horizontal)
                .padding(.vertical)
                Spacer()
            }
            .frame(maxWidth: .infinity , alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 4))
            .padding(.horizontal,20)
            
            
        }
        
        .onAppear {
            fromCoordinate = locationManager.location
            fromAddress = locationManager.currentAddress
            
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            
        }
    }
    private func searchRides(){
        print("searching Rides from \(fromAddress) to \(toAddress)")
        print("Selected Date \(selectedDate), Time: \(selectedTime) ")
    }
    
    func selectLocation(_ completion:MKLocalSearchCompletion) {
        locationSearchCompleter.getCoordinate(for: completion) { coordinate, address in
            if let Coordinate = coordinate, let address = address {
                toAddress = address
                toCoordinate = coordinate
                locationSearchCompleter.searchQuery = address
                
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }
}



struct fromView:View {
    var icon: String
    var locationManager:LocationManagerRideSearch
    var body: some View {
        HStack(spacing: 12){
            Image(systemName: "mappin.circle")
                .font(.system(size: 20))
                .foregroundColor(.red)
                .onAppear{
                    print("hello")
                }
            
            Text("FROM:")
                .font(.system(size:16, weight: .regular))
                .foregroundColor(.primary)
            
            Text(locationManager.currentAddress.isEmpty ? "Current Location" : locationManager.currentAddress)
                .font(.system(size: 16,weight: .regular))
                .foregroundColor(.secondary)
            
            Spacer()
            
            if locationManager.location != nil {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.green)
                
            }
        }
        .frame(maxWidth:.infinity , alignment: .leading)
        .padding(.vertical,12)
        .padding(.horizontal)
        .background(RoundedRectangle(cornerRadius: 12)
            .fill(Color.white)
            .shadow(color: Color.black.opacity(0.1), radius:4 , x: 0 , y:2 )
        )
        .padding(.horizontal,20)
    }
    
}


struct QuickActionButton:View {
    
    let icon: String
    let title: String
    
    var body: some View {
        VStack(spacing:8){
            Image(systemName:icon)
                .font(.system(size: 24))
                .foregroundColor(.gray)
            
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical,16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color:Color.black.opacity(0.05), radius: 5)
    }
}

struct searchSuggestion:View {
    @ObservedObject var completer:LocationsearchCompleter
    var onSelect: (MKLocalSearchCompletion) -> Void
    
    var body: some View {
        ForEach(Array(completer.searchresult.enumerated()), id: \.offset){ index , result    in  // .enumerated turn array into index eleement tupple and then here .offset refers to the index of the element in the array
            
            Button {
                onSelect(result)
            } label:{
                VStack(alignment:.leading , spacing:0){
                    Text(result.title)
                        .font(.system(size:16 , weight: .medium ))
                        .foregroundColor(.primary)
                    
                    Text(result.subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    
                }
                .frame(maxWidth:.infinity,alignment:.leading )
                .padding(.vertical,12)
                .padding(.horizontal)
            }
            if result != completer.searchresult.last {
                Divider()
                    .padding(.leading, 16)
            }
        }
    }
}

/*struct DestinationSearchiew: View {
    @Environment(\.presentationMode) var presentationMode  // @environment object is use to read the object and \.presentation mode is a static property that act as the key to access the current value that control the current view presentation state
    @StateObject private var searchCompleter = LocationsearchCompleter()
    @Binding var selectedAdreess:String
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search Destination ", text: $searchCompleter.searchQuery)
                    .textFieldStyle(.plain)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .padding()
            
            List(searchCompleter.searchresult, id : \.self) {result in
                Button(action:  {}){
                    VStack(alignment: .leading,spacing:4)
                    {
                        Text(result.title)
                            .font(.system(size:16,weight:.medium))
                            
                        Text(result.subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        
                    }
                }
            }
        }
    }
    
     func selectLocation(_ completion:MKLocalSearchCompletion){
        searchCompleter.getCoordinate(for: completion) { coordinate, address in
            if let coordinate  = coordinate, let address = address {
                selectedAdreess = address
                selectedCoordinate = coordinate
                presentationMode.wrappedValue.dismiss()
                
            }
        }
        
    }
    
}*/



#Preview {
    SearchRideView(locationManager: LocationManagerRideSearch(), currentUser: AppUser(id: "1", name: "shashank", email: "shashankyadav2803@gmail.com", phone: "8447038783", gender: "male", vehicleType: "car", profilePicture: "abbsn.png", fcmToken: "2rs", createdAt: Date()))
}
