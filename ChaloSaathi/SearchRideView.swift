import SwiftUI
import MapKit

struct SearchRideView: View {
    
    @ObservedObject var locationManager: LocationManagerRideSearch
    @StateObject var viewModel = SearchRideViewModel()
    let currentUser: AppUser
    
    @State private var fromAddress: String = ""
    @State private var toAddress: String = ""
    @State private var selectedDateTime = Date()
    @State private var searchAnyDate = false
    
    @State private var fromCoordinate: CLLocationCoordinate2D?
    @State private var toCoordinate: CLLocationCoordinate2D?
    
    @StateObject private var locationSearchCompleter = LocationsearchCompleter()
    @State private var showRideTrackingView = false
    @State private var showNoRideAlert = false
    @State private var foundRide: Ride?

    
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
                          
                        TextField("Enter the Location", text: $fromAddress)
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
                        
                        TextField("Search Destination", text: $locationSearchCompleter.searchQuery)
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
                            
                            DatePicker("", selection: $selectedDateTime, displayedComponents: [.date, .hourAndMinute])
                                .labelsHidden()
                                .disabled(searchAnyDate)
                                .opacity(searchAnyDate ? 0.5 : 1.0)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal)
                        
                        Toggle("Search rides on any date", isOn: $searchAnyDate)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        
                        Button(action: {
                            performSearch()
                        }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                }
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
                        .disabled(viewModel.isLoading || fromAddress.isEmpty || (locationSearchCompleter.searchQuery.isEmpty && toAddress.isEmpty))
                        .opacity((viewModel.isLoading || fromAddress.isEmpty || (locationSearchCompleter.searchQuery.isEmpty && toAddress.isEmpty)) ? 0.6 : 1.0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 4)
                    )
                    .padding(.horizontal, 20)
                    
                    // Quick Stats Card
                    VStack(spacing: 16) {
                        Text("Recent Activity")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 16) {
                            StatCard(icon: "car.fill", title: "Rides", value: "0", color: .blue)
                            StatCard(icon: "star.fill", title: "Rating", value: "5.0", color: .orange)
                            StatCard(icon: "indianrupeesign.circle.fill", title: "Saved", value: "₹0", color: .green)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            
            // Suggestions overlay
            if !locationSearchCompleter.searchresult.isEmpty {
                VStack {
                    Spacer()
                        .frame(height: 110)
                    
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
                    .zIndex(1)
                    
                    Spacer()
                }
                .animation(.easeInOut(duration: 0.2), value: locationSearchCompleter.searchresult.count)
            }
        }
        .navigationDestination(isPresented: $showRideTrackingView) {
            if let ride = foundRide {
                PassengerTrackingView(
                    ride: ride,
                    currentUser: currentUser
                )
            } else {
                Text("Invalid ride data")
            }
        }
        .onAppear {
            fromCoordinate = locationManager.location
            fromAddress = locationManager.currentAddress
            print("📍 SearchRideView appeared")
            print("   From: '\(fromAddress)'")
            print("   Coordinates: \(fromCoordinate?.latitude ?? 0), \(fromCoordinate?.longitude ?? 0)")
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .alert("No Rides Found", isPresented: $showNoRideAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("No rides were found for your selected route and date. Try adjusting your destination or time, or enable 'Search rides on any date'.")
        }
    }
    
    private func performSearch() {
        let searchFrom = fromAddress.isEmpty ? locationManager.currentAddress : fromAddress
        let searchTo = locationSearchCompleter.searchQuery.isEmpty ? toAddress : locationSearchCompleter.searchQuery
        
        print("🔍 Searching: '\(searchFrom)' → '\(searchTo)'")
        print("📅 Date filter: \(searchAnyDate ? "ANY DATE" : selectedDateTime.description)")
        print("👤 User gender: \(currentUser.gender)")
        
        viewModel.searchRides(
            from: searchFrom,
            to: searchTo,
            date: searchAnyDate ? Date.distantPast : selectedDateTime,
            currentUserGender: currentUser.gender
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let ride):
                    print("✅ Ride found: \(ride.fromAddress) → \(ride.toAddress)")

                    fromCoordinate = CLLocationCoordinate2D(
                        latitude: ride.fromLat,
                        longitude: ride.fromLong
                    )
                    toCoordinate = CLLocationCoordinate2D(
                        latitude: ride.toLat,
                        longitude: ride.toLong
                    )

                    foundRide = ride
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        print("🚀 Opening PassengerTrackingView")
                        showRideTrackingView = true
                    }

                case .noResults:
                    print("❌ No rides found.")
                    showNoRideAlert = true

                case .failure(let message):
                    print("❌ Search failed: \(message)")
                    showNoRideAlert = true
                }
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

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
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
