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
    
    var body: some View {
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
                        
                        Text(locationManager.currentAddress.isEmpty ? "Current Location" : locationManager.currentAddress)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if locationManager.location != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.green)
                                .frame(width: 18)
                        }
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
                        
                        TextField("Where are you going?", text: $locationSearchCompleter.searchQuery)
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                        
                        if toCoordinate != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.green)
                                .frame(width: 18)
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
                            if let gender = currentUser?.gender {
                                viewModel.searchRides(
                                    from: fromAddress.isEmpty ? locationManager.currentAddress : fromAddress,
                                    to: toAddress,
                                    date: selectedDate,
                                    currentUserGender: gender
                                )
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
                                        colors: [Color.blue, Color.blue.opacity(0.7)],
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
        .onAppear {
            fromCoordinate = locationManager.location
            fromAddress = locationManager.currentAddress
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
