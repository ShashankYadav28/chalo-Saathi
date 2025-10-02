//
//  ChaloSaathiApp.swift
//  ChaloSaathi
//
//  Created by Shashank Yadav on 30/09/25.
//

import SwiftUI


@main
struct ChaloSaathiApp: App {
    @State private var isactive = true
    var body: some Scene {
        WindowGroup {
            
            if isactive {
                SplashScreen(splashShow:$isactive)
            }
            else {
                OnboardingView()
            }
        }
    }
}
