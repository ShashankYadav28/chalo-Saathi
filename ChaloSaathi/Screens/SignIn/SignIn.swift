//
//  SignIn.swift
//  ChaloSaathi
//
//  Created by Shashank Yadav on 04/10/25.
//

import SwiftUI
import FirebaseAuth

struct SignIn: View {
    
    /* @State private var email = ""
     @State private var password = ""
     @State private var phoneNumber = ""
     @State private var otpCode = ""
     
     @State private var isSigned = false
     @State private var isLoading = false
     @State private var errorMessage:String?
     
     @State private var isCodSent = false
     @State private var verificationId : String?*/
    
    @StateObject private var signInViewModel = SignInViewModel()
    @State private var isLogin = true
    
    var body: some View {
        ZStack(alignment: .top ) {
            
            
            if isLogin {
                
                VStack(alignment: .leading,spacing: 8 ){
                    Text("Go ahead Continue wih the Login")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Login into the Account.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal,30)
                .padding(.vertical,50)
                .frame(maxWidth: .infinity,alignment: .leading)
                .background(Color(red:0.15,green:0.25, blue:0.25))
            }
            else {
                VStack (alignment: .leading,spacing: 8) {
                    Text("Sign up now to acessss your personal account ")
                        .font(.system(size: 32,weight: .bold,design:.rounded))
                        .foregroundColor(.white)
                    
                    Text("sign up to access your own account and exclusive features")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 50)
                .frame(maxWidth: .infinity,alignment: .leading)
                .background(Color(red:0.15,green:0.25,blue: 0.25))
                .edgesIgnoringSafeArea(.all)
                
            }
            
            
            ScrollView(.vertical,showsIndicators: false){
                VStack(spacing: 20) {
                    
                    HStack(spacing:0){
                        Text("login")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical,12)
                            .background(isLogin ? Color.white : Color(.systemGray6))
                            .onTapGesture {
                                withAnimation {
                                    isLogin = true
                                    
                                }
                            }
                        
                        
                        Text("signUp")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical,12)
                            .background(isLogin ? Color(.systemGray6) : Color.white)
                            .onTapGesture {
                                withAnimation {
                                    isLogin = false
                                    
                                    
                                }
                            }
                    }
                    .padding(6)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    
                    
                    if isLogin {
                        SignInFormView()
                        
                        
                        
                        
                    }
                    else {
                        SignUpFormView(onSignUPSuccess: {
                            withAnimation {
                                isLogin = true
                            }
                            }
                        )
                    }
                }
                
            }
            .padding(.horizontal,30)
            .padding(.vertical, 30)
            .frame(maxWidth: .infinity)
            .background(.white)
            .cornerRadius(20)
            //.shadow(color: .black.opacity(0.1), radius:10, x:0, y:5 )
            .offset(y:170)
            
        }
        .alert(isPresented: .constant(signInViewModel.errorMessage != nil)) {
            Alert(title: Text("Error Message"),message: Text(signInViewModel.errorMessage ?? "something is the errro"),dismissButton:.default(Text("ok"),action:{
                signInViewModel.errorMessage = nil
            }))
        }
        
        
        
        
    }
    
    
}





#Preview {
    SignIn()
}
