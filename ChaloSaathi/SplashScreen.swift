//
//  SplashScreen.swift
//  ChaloSaathi
//
//  Created by Shashank Yadav on 30/09/25.
//

import SwiftUI

struct SplashScreen: View {
    @State private var isActve  = false
    @State private var logoOpacity = 0.0
    @State private var logoScale = 0.0
    @State private var textOpacity = 0.0
    @State private var circleScale = 0.0
    @State private var allOpacity = 1.0
    
    @Binding var splashShow:Bool
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [.white,Color("lightBlue")]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea(.all)
            
            
            VStack {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width:200,height: 200)
                        .scaleEffect(circleScale)
                        .blur(radius: 10)
                        .shadow(color: .black, radius: 10,x: 0,y:0)
                        
                    
                    Image("chalosaathi")
                        .resizable()
                        .scaledToFill()
                        .frame(width:165,height:165)
                        .clipShape(Circle())
                        .opacity(logoOpacity)
                        .scaleEffect(logoScale)
                }
    
                    Text("Chalo Saathi")
                        .font(.system(size: 36,weight: .bold,design: .rounded))
                        .opacity(textOpacity)
                    
                    Text("Find your ride Partner Today")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
                    .opacity(textOpacity)
                    
            }
            .padding(.bottom,110)
        }
        .onAppear {
            withAnimation (.easeIn(duration: 0.8)){
                self.circleScale = 1.0
                
            }
            
            withAnimation(.easeIn(duration: 0.8).delay(0.8)){
                logoOpacity = 1.0
                logoScale = 1.0
            }
            withAnimation(.easeIn(duration: 0.8).delay(1.6)) {
                textOpacity = 1
                
            }
            
            withAnimation(.easeOut(duration: 0.8).delay(2.4)){
                allOpacity = 0.0
                
            }
            DispatchQueue.main.asyncAfter(deadline:.now()+3.2){
                splashShow = false
                
            }
            
        }
    }
}

#Preview {
    SplashScreen(splashShow:.constant(true))
}
