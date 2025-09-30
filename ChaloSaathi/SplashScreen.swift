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
    @State private var textOpacity = 0.0
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [.white,Color("lightBlue")]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
        }
        
    }
}

#Preview {
    SplashScreen()
}
