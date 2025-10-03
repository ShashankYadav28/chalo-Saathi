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
   // @State private var showLocationAlert = false
    @StateObject private var showLocationManager = LocationManger()
    
    let slides  = [("Connect with nearby office goers","Share your ride and save on your daily commute."),
                   ("Share rides, save petrol, save money","Find a travel partner for a sustainable and affordable journey.")]
    
    // here we have form the tuple for the nested data  we can get it one by one
    
    let slidesImage = ["chaloosaathi2","chaloosaathi45"]
    
    var body: some View {
       
        
        VStack {
            TabView(selection: $currentPage) {
                ForEach(0..<slidesImage.count, id : \.self){ index in
                       // it stacks the content from the bottom to the front
                    ZStack(alignment: .bottom) {
                        Image(slidesImage[index])
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth:.infinity , maxHeight: 500)
                            //.clipped()
                            //.ignoresSafeArea(edges:.top)
                        
                        HStack {
                            ForEach(0..<slidesImage.count, id:\.self) { dotIndex in
                                Circle()
                                    .fill(dotIndex == currentPage ? Color.blue : Color.gray.opacity(0.5))
                                
                                    .frame( width: dotIndex == currentPage ? 10 : 8 , height: dotIndex == currentPage ? 10 : 8)
                                    .scaleEffect(dotIndex == currentPage ? 1.2 : 1)
                                    .animation(.easeInOut, value:currentPage)
                                
                                
                            }
                        }
                        .padding(.bottom,20)
                    }
                    .tag(index)
                    
                       
                        
                   
                    
                    
                }
               
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height:500)
            
            Spacer()
            
            Textlayout(headingText: slides[currentPage].0, subheadingText: slides[currentPage].1)
            
            Spacer()
            
            Button {
                showLocationManager.showLocationAlert = true
            } label: {
                Text("Get started")
                    .foregroundColor(.white)
                    .font(.headline)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(8)
                    .padding(.horizontal,30)
            }
            .padding(.bottom,25)
            .alert(isPresented: $showLocationManager.showLocationAlert) {
                Alert(title: Text("Location Required"),message: Text("Please enable your Location from the Setting"),dismissButton:.default(Text("ok")))
            }
            
        }
    }
}


#Preview {
    OnboardingView()
}



struct Textlayout:View {
    var headingText:String
    var subheadingText:String
    var body: some View {
        VStack(spacing:15){
            Text(headingText)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal,30)
            
            Text(subheadingText)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal,30)
            
        }
        
    }
}
/*

struct ImageLayout:View {
    var image:String
    var imageCount:Int
    @Binding var currentPageIndex:Int
    var body: some View {
        ZStack(alignment: .bottom) {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth:.infinity , maxHeight: 500)
            
            HStack {
                ForEach(0..<imageCount, id:\.self) { dotIndex in
                    Circle()
                        .fill(dotIndex == currentPageIndex ? Color.blue : Color.gray.opacity(0.5))
                    
                        .frame( width: dotIndex == currentPageIndex ? 10 : 8 , height: dotIndex == currentPageIndex ? 10 : 8)
                        .scaleEffect(dotIndex == currentPageIndex ? 1.2 : 1)
                        .animation(.easeInOut, value:currentPageIndex)
                    
                    
                }
            }
            .padding(.bottom,20)
        }
        
    }
    
}
 */


/*VStack {
 //  ZStack {
 TabView(selection: $currentPage) {
 ForEach(0..<slides.count,id: \.self){ index in
 VStack(spacing: 20){
 
 Image(slidesImage[index])
 .resizable()
 .scaledToFill()
 .frame(maxHeight:500)
 .frame(maxWidth:.infinity)
 //.padding(.top,40)
 .ignoresSafeArea(edges:.top)
 
 HStack(spacing:2){
 ForEach(0..<slidesImage.count, id: \.self){ dotIndex in
 Circle()
 .fill(dotIndex == currentPage ? Color.blue : Color.gray)
 // .scaleEffect(dotIndex == currentPage ? 1.15 : 1)
 .frame(width:dotIndex == currentPage ? 10 : 8, height:dotIndex == currentPage ? 10 : 8)
 .scaleEffect(dotIndex == currentPage ? 1.15 : 1)
 .animation(.easeInOut, Value = currentPage)
 }
 
 }
 
 
 
 }
 .tag(index)
 //.padding(.bottom,50)
 
 }
 
 //padding(.bottom,50)
 }
 
 }
 .tabViewStyle(.page(indexDisplayMode: .always))
 .indexViewStyle(.page(backgroundDisplayMode: .never))
 .padding(.vertical,30)
 //.frame(height: 500)*/


