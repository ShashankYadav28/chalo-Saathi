//
//  ProfileView.swift
//  ChaloSaathi
//
//  Created by Shashank Yadav on 26/10/25.
//

import SwiftUI

struct ProfileLogOutView: View {
    @StateObject private var viewModel = SignInViewModel()
    @Binding  var showProfile:Bool
    var body: some View {
        Button{
            viewModel.signOut()
            showProfile = false
        }
        label: {
            Text("Sign Out")
                .frame(maxWidth:.infinity)
                .padding()
                
                .background(Color.blue)
                .foregroundColor(.white)
        }
        .cornerRadius(8)
        .padding()
        
    }
}

#Preview {
    ProfileLogOutView(showProfile: .constant(true))
}
