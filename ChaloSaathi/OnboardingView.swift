//
//  OnboardingView.swift
//  ChaloSaathi
//
//  Created by Shashank Yadav on 02/10/25.
//

import SwiftUI
import CoreLocation

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var showLocationAlert = false
    
    let slides  = [("Connect with nearby office goers","Share your ride and save on your daily commute."),
                   ("Share rides, save petrol, save money","Find a travel partner for a sustainable and affordable journey.")]
    
    // here we have form the tuple for the nested data  we can get it one by one
    
    let slidesImage = ["chaloosaathi2","chaloosaathi45"]
    
    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                ForEach(0..<slides.count,id: \.self){ index in
                    VStack(spacing: 20){
                        ZStack{
                            Image(slidesImage[index])
                                .resizable()
                                .scaledToFill()
                                .frame(maxHeight:500)
                                .frame(maxWidth:.infinity)
                            //.padding(.top,40)
                                .ignoresSafeArea(edges:.top)
                            
                            HStack(spacing:8){
                                
                            }
                            
                            
                        }
                       
                    }
                    .tag(index)
                    .padding(.bottom,50)
                }
                
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            //.frame(height: 500)
            
            Text(slides[index].0)
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)
                //.padding()
            
            Text(slides[index].1)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
         
        
        
        Button {
            showLocationAlert = true
            
        } label: {
            Text("Get Started ")
                .foregroundColor(.black)
                .font(.headline)
                .frame(height: 50)
                .frame(maxWidth:.infinity)
                .background(Color.blue)
                .cornerRadius(8)
                .padding(.horizontal)
            
            
            
        }
        .alert(isPresented: $showLocationAlert) {
            Alert(title: Text("Location Required"),message: Text("please enable location in the settings"),dismissButton: .default(Text("ok")))
        }
        
    }
    
    func getlocationpermission() {
        let manager = CLLocationManager()
        manager.requestWhenInUseAuthorization()
        
        if CLLocationManager.authorizationStatus() == .denied {
            showLocationAlert = true
        }
        else {
            
        }
    }
}

#Preview {
    OnboardingView()
}

