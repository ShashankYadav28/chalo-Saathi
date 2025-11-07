import SwiftUI
import MapKit

struct SearchRideView: View {
    
    @StateObject var locationManager: LocationManagerRideSearch
    @StateObject var viewModel = SearchRideViewModel()
    let currentUser: AppUser?
    
    @State private var fromAddress: String = ""
    @State private var toAddress: String = ""
    @State private var selectedDate = Date()
    @State private var selectedTime = Date()
    
    @State private var fromCoordinate: CLLocationCoordinate2D?
    @State private var toCoordinate: CLLocationCoordinate2D?
    
    @StateObject private var locationSearchCompleter = LocationsearchCompleter()
    @State private var showRideTrackingView = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: 16) {
                        
                        // FROM section
                        HStack(spacing: 12) {
                            Image(systemName: "mappin.circle")
                                .font(.system(size: 20))
                                .foregroundColor(.red)
                                .frame(width: 20)
                            
                            Text("FROM:")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.primary)
                                .fixedSize()
                              
                            TextField("Enter the Location",text: $fromAddress)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                        .padding(.horizontal)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        
                        // TO section
                        HStack(spacing: 12) {
                            Image(systemName: "flag")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            
                            Text("TO:")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.primary)
                                .fixedSize()
                            
                            TextField("Search Destinationn", text: $locationSearchCompleter.searchQuery)
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                            
                            
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        )
                        .padding(.horizontal, 20)
                        
                        
                        
                        // Time and Find Ride buttons section
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Image(systemName: "clock")
                                    .font(.system(size: 20))
                                    .foregroundColor(.primary)
                                
                                Text("TIME:")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                DatePicker("", selection: $selectedTime, displayedComponents: [.date, .hourAndMinute])
                                    .labelsHidden()
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal)
                            
                            Button(action: {
                                
                                // 🚀 TEST ONLY: Bypass search & use fixed coordinates
                                   /*fromCoordinate = CLLocationCoordinate2D(latitude: 12.9716, longitude: 77.5946) // Bangalore
                                   toCoordinate = CLLocationCoordinate2D(latitude: 12.9352, longitude: 77.6245)   // */
                                
                                
                                 
                                guard let gender = currentUser?.gender else {
                                    print("cuurent User not found ")
                                    return
                                }
                                
                                    viewModel.searchRides(
                                        
                                        from: fromAddress.isEmpty ? locationManager.currentAddress : fromAddress,
                                        to: locationSearchCompleter.searchQuery.isEmpty ? toAddress:locationSearchCompleter.searchQuery,
                                        date: selectedDate,
                                        currentUserGender: gender
                                        
                                    )
                                DispatchQueue.main.asyncAfter(deadline:.now()+2) {locationSearchCompleter.searchQuery = ""
                                    if let ride = viewModel.rides.first {
                                        //selectedRide = firstRide
                                        print("✅ Ride found, navigating to RideTrackingView")
                                        let toLat = Double(ride.toLat)
                                        let toLong = Double(ride.toLong)
                                        
                                        fromCoordinate = CLLocationCoordinate2D(latitude: 12.9716, longitude: 77.5946) // Bangalore
                                        toCoordinate = CLLocationCoordinate2D(latitude: 13.0827, longitude: 80.2707)
                                        showRideTrackingView = true
                                    }
                                    else {
                                        print(" Ride Not Found")
                                        
                                    }
                                }
                            }) {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                    Text("Find Rides")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(LinearGradient(
                                            colors: [Color.blue, Color.blue.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ))
                                )
                                .foregroundColor(.white)
                                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                            .disabled(toAddress.isEmpty)
                            .opacity(toAddress.isEmpty ? 0.6 : 1.0)
                            
                       
                            
                            
                            HStack(spacing: 12) {
                                QuickActionButton(icon: "star", title: "Saved Routes")
                                QuickActionButton(icon: "shield.checkered", title: "Safety Routes")
                                QuickActionButton(icon: "dollarsign.circle", title: "Earnings")
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 4)
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        
                    }
                }
                
                // ✅ Suggestions overlay (true floating layer)
                if !locationSearchCompleter.searchresult.isEmpty {
                    VStack {
                        Spacer()
                            .frame(height: 110) // align right below TO field
                        
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(Array(locationSearchCompleter.searchresult.enumerated()), id: \.offset) { index, result in
                                    Button {
                                        selectLocation(result)
                                    } label: {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(result.title)
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.primary)
                                            Text(result.subtitle)
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                    }
                                    
                                    if index != locationSearchCompleter.searchresult.count - 1 {
                                        Divider()
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 250)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                        .padding(.horizontal, 20)
                        .zIndex(1) // ensures it's on top
                        
                        Spacer()
                    }
                    .animation(.easeInOut(duration: 0.2), value: locationSearchCompleter.searchresult.count)
                }
            }
            .navigationDestination(isPresented: $showRideTrackingView) {
                if let fromCoord = fromCoordinate, let toCoord = toCoordinate {
                    RideTrackingView(fromCoordinate: fromCoord, toCoordinate: toCoord)
                } else {
                    EmptyView()
                }
            }

            .onAppear {
                fromCoordinate = locationManager.location
                fromAddress = locationManager.currentAddress
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
       
    }
    func selectLocation(_ completion: MKLocalSearchCompletion) {
        locationSearchCompleter.getCoordinate(for: completion) { coordinate, address in
            if let coordinate = coordinate, let address = address {
                toAddress = address
                toCoordinate = coordinate
                locationSearchCompleter.searchQuery = address
                
                locationSearchCompleter.searchresult.removeAll()
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            
        }
    }


}


struct QuickActionButton: View {
    let icon: String
    let title: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.gray)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
}

#Preview {
    SearchRideView(
        locationManager: LocationManagerRideSearch(),
        currentUser: AppUser(
            id: "1",
            name: "shashank",
            email: "shashankyadav2803@gmail.com",
            phone: "8447038783",
            gender: "male",
            vehicleType: "car",
            profilePicture: "abbsn.png",
            fcmToken: "2rs",
            createdAt: Date()
        )
    )
}
