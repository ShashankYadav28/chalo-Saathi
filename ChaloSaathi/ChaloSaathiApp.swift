//
//  ChaloSaathiApp.swift
//  ChaloSaathi
//
//  Created by Shashank Yadav on 30/09/25.
//

import SwiftUI
import FirebaseCore

@main
struct ChaloSaathiApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

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

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}
