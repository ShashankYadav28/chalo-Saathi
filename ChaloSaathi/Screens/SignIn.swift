//
//  SignIn.swift
//  ChaloSaathi
//
//  Created by Shashank Yadav on 04/10/25.
//

import SwiftUI
import FirebaseAuth

struct SignIn: View {
    
    @State private var email = ""
    @State private var password = ""
    @State private var phoneNumber = ""
    @State private var otpCode = ""
    
    @State private var isSigned = false
    @State private var isLoading = false
    @State private var errorMessage:String?
    
    @State private var isCodSent = false
    @State private var verificationId : String?
    @State private var islogin = false
    
    var body: some View {
        ZStack(alignment: .top ) {
           
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
                
                
                ScrollView(.vertical,showsIndicators: false){
                    VStack(spacing: 20) {
                        
                        HStack(spacing:0){
                            Text("login")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical,12)
                                .background(islogin ? Color.white : Color(.systemGray6))
                                .onTapGesture {
                                    withAnimation {
                                        islogin = true
                                        //SignIn()
                                    }
                                }
                            
                            
                            Text("signUp")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical,12)
                                .background(islogin ? Color(.systemGray6) : Color.white)
                                .onTapGesture {
                                    withAnimation {
                                        islogin = false 
                                       // SignUP()
                                        
                                    }
                                }
                        }
                        .padding(6)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        
                        
                        
                        
                        VStack(spacing: 15){
                            TextField("Email", text: $email)
                                .padding()
                                .background(Color(.systemGray6))
                            // .textFieldStyle(.roundedBorder)
                                .cornerRadius(8)
                                .keyboardType(.emailAddress)
                            
                            SecureField("Password", text: $password)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            //.textFieldStyle(.roundedBorder)
                            
                            Button {
                                
                            } label: {
                                if isLoading {
                                    ProgressView()
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                }
                                else {
                                    Text("Sign in with Email")
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .cornerRadius(8)
                                        .shadow(radius: 10)
                                }
                            }
                            .shadow(color: .blue.opacity(0.3), radius: 10,x:0,y: 5)
                            
                            
                        }
                        
                        Text("Or")
                            .font(.title)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 15) {
                            if !isCodSent {
                                TextField("+91 9871311234",text:$phoneNumber )
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                // .textFieldStyle(.roundedBorder)
                                    .keyboardType(.numberPad)
                                
                                Button {
                                    Text("otp")
                                    
                                }label: {
                                    Text("Send OTP")
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .cornerRadius(8)
                                    
                                    
                                }
                                .shadow(color:.blue.opacity(0.3),radius: 10,x:0,y:5)
                            }
                            else {
                                TextField("enter the Otp",text: $otpCode)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                    .keyboardType(.numberPad)
                                
                                Button {
                                    Text("Verify Otp")
                                    
                                }label: {
                                    Text("Verify Otp")
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .cornerRadius(8)
                                    
                                    
                                }
                                .shadow(color: .blue.opacity(0.3), radius: 10,x:0,y:5)
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
             
                
                
                
                
            }
            .alert(isPresented: .constant(errorMessage != nil)) {
                Alert(title: Text("Error Message"),message: Text(errorMessage ?? "something is the errro"),dismissButton:.default(Text("ok"),action:{
                    errorMessage = nil
                }))
            }
            
        }
    }




#Preview {
    SignIn()
}
