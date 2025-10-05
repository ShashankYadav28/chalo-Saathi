//
//  SwiftUIView.swift
//  ChaloSaathi
//
//  Created by Shashank Yadav on 03/10/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignUP: View {
    
    @StateObject private var signUpViewModel = SignUPViewModel()
    @State private var isLogin = false
    
    var body: some View {
        
        ZStack(alignment: .top){
            
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
            
            
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    
                    
                    HStack(spacing: 0) {
                        Text("Login")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(isLogin ? .white : Color(.systemGray6))
                            .cornerRadius(8)
                            .onTapGesture { withAnimation { isLogin = true } }
                        
                        Text("Sign Up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(isLogin ? Color(.systemGray6) : .white)
                            .cornerRadius(8)
                            .onTapGesture { withAnimation { isLogin = false } }
                    }
                    .padding(6)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    
                    
                    VStack(spacing: 15) {
                        
                 
                            TextField("Full Name", text: $signUpViewModel.name)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius:8).stroke(Color.gray, lineWidth: 0.5))
                            
                            
                            TextField("Email",text: $signUpViewModel.email)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius:8).stroke(Color.gray, lineWidth: 0.5))
                            
                            
                            SecureField("Password",text: $signUpViewModel.password)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius:8).stroke(Color.gray, lineWidth: 0.5))
                            
                            
                            TextField("Gender (Male/Female/Other",text: $signUpViewModel.gender)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius:8).stroke(Color.gray, lineWidth: 0.5))
                            
                            
                            TextField("Vehicle Type (car/Bike/None",text: $signUpViewModel.vehicleType)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius:8).stroke(Color.gray, lineWidth: 0.5))
                            
                            
                            TextField("Aadhaar Number", text: $signUpViewModel.aadhaar)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius:8).stroke(Color.gray, lineWidth: 0.5))
                            
                            
                            Button {
                                signUpViewModel.signUpUser()
                            } label:  {
                                if signUpViewModel.isLoading {
                                    ProgressView()
                                        .frame(maxWidth: .infinity)
                                }
                                else{
                                    Text("Sign Up")
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        //.padding()
                                        .background(Color.blue)
                                        .cornerRadius(8)
                                    
                                }
                            }
                            .shadow(color:.blue.opacity(0.3),radius: 10,x:0,y:5)
                        }
                    }
                    .padding(.horizontal,30)
                    .padding(.vertical,30)
                    .frame(maxWidth:.infinity)
                    .background(.white)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.1),radius:10,x:0,y:5)
                    .offset(y: 170)
                    
                    
                
            }
        }
    }
}

#Preview {
    SignUP()
}
