//
//  ProfileView.swift
//  ChaloSaathi
//
//  Created by Shashank Yadav on 26/10/25.
//

import SwiftUI

struct ProfileView: View {
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
    ProfileView(showProfile: .constant(true))
}
