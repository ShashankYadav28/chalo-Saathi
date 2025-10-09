//
//  HomeView.swift
//  ChaloSaathi
//
//  Created by Shashank Yadav on 07/10/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject var vm = SignInViewModel()
    var body: some View {
        
        Button {
            vm.signOut()
            
        }
        label:{
            Text("signOut ")
                .foregroundColor(.white)
                //.padding()
                .frame(maxWidth:.infinity)
                .frame(height:100)
                .background(Color.blue)
            
                
        }
    }
}

#Preview {
    HomeView()
}
