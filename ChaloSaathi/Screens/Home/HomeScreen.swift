//
//  HomeScreen.swift
//  ChaloSaathi
//
//  Created by Shashank Yadav on 13/10/25.
//

import SwiftUI

struct HomeScreen:View {
    
    @StateObject private var locationManager = LocationManagerRideSearch()
    @State private var selectedTab: Tab = .search
    
    @State private var showProfile  = false
    @State private var currentUser : AppUser?
    
    enum Tab {
        case search
        case publish
    }
    var body: some View {
        
        NavigationStack {
            VStack(spacing: 0){
                HeaderView
                
                tabswitcher
                
                Group {
                    switch selectedTab {
                    case .search:
                        SearchRideView(
                            locationManager: locationManager,
                            currentUser: AppUser(
                                id: "1",
                                name: "Test User",
                                email: "test@test.com",
                                phone: "9999999999",
                                gender: "male",
                                vehicleType: "car",
                                profilePicture: "",
                                fcmToken: "",
                                createdAt: Date()
                            )
                        )
                        .transition(.opacity)
                    case .publish:
                        PublishRideView(
                               locationManager: locationManager,
                               currentUser: AppUser(
                                   id: "1",
                                   name: "Test User",
                                   email: "test@test.com",
                                   phone: "9999999999",
                                   gender: "male",
                                   vehicleType: "car",
                                   profilePicture: "",
                                   fcmToken: "",
                                   createdAt: Date()
                               )
                           )
                           .transition(.opacity)
                        
                    }
                    
                    
                }
                //.background(Color(UIColor.systemGroupedBackground))
                
                bottomNavigation
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(true)
        }
        
    }
    
    private var HeaderView: some View {
        HStack{
            HStack(spacing: 12){
                ZStack{
                    Circle()
                        .fill(Color.blue)
                        .frame(width:40,height: 40)
                    
                    Image(systemName: "car.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 18))
                }
                VStack(alignment: .leading, spacing: 2){
                    Text("ChalooSaathi")
                        .font(.system(size: 20,weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Save Money , Share Ride")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                
            }
            
            Spacer()
            
            Button {
                showProfile = true
                
                
            }
            label:{
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40,height: 40)
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 18))
                    }
                
            }
            
        }
        .sheet(isPresented: $showProfile, content: {
            ProfileView(showProfile: $showProfile)
        })
        .padding()
        .background(Color.white).shadow(color: .black.opacity(0.3), radius: 5,y: 2)
        
        
    }
    
    private var tabswitcher: some View {
        HStack(spacing: 8){
            TabButton(title: "Search for Ride ", icon: "magnifyingglass", isSelected: selectedTab == .search, action: {selectedTab = .search})
            
            TabButton(title: "Publish a Ride ", icon: "plus.circle.fill", isSelected: selectedTab == .publish) {
                selectedTab = .publish
            }
        }
        .padding(8)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2),radius: 10)
        .padding()
    }
    
    private var bottomNavigation: some View {
        HStack {
            BottomNavItem(icon: "house.fill", title: "Home", isSelected: true)
            BottomNavItem(icon: "car", title: "Rides", isSelected: false)
            BottomNavItem(icon: "message", title: "Inbox", isSelected: false)
            BottomNavItem(icon: "person", title: "Profile", isSelected: false)
            
        }
        .padding(.vertical,12)
        .background(Color.white)
        .shadow(color:.black.opacity(0.1),radius: 10 , y: -5)
    }
    
}

struct TabButton: View {
    
    let title: String
    let icon: String
    let isSelected: Bool
    let action : () -> Void
    
    var body: some View {
        Button(action: action){
            HStack(spacing: 8){
                Image(systemName: icon)
                    .font(.system(size: 18,weight: .semibold))
                
                Text(title)
                    .font(.system(size: 18,weight: .semibold))
                
            }
            .foregroundColor(isSelected ? .white : .gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical,12)
            .background(isSelected ? Color.blue : Color.clear)
            .cornerRadius(8)
            
        }
    }
}

struct BottomNavItem: View {
    let icon: String
    let title: String
    let isSelected:Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(isSelected ? .blue : .gray )
            
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(isSelected ? .blue : .gray)
        }
        .frame(maxWidth: .infinity)
    }
}
    

#Preview {
    HomeScreen()
}
