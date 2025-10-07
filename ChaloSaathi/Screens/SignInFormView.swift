//
//  SignInNewForm.swift
//  ChaloSaathi
//
//  Created by Shashank Yadav on 06/10/25.
//

import SwiftUI

struct SignInFormView: View {
    
    @StateObject var vm = SignInViewModel()
    @State private var goToHome = false
    var body: some View {
        NavigationStack {
            VStack(spacing: 15){
                TextField("Email", text: $vm.email)
                    .padding()
                    .background(Color(.systemGray6))
                // .textFieldStyle(.roundedBorder)
                    .cornerRadius(8)
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: $vm.password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                //.textFieldStyle(.roundedBorder)
                
                Button {
                    vm.loginWithEmail()
                    
                } label: {
                    if vm.isLoading {
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
                if !vm.isCodeSent {
                    TextField("+91 9871311234",text:$vm.phoneNumber )
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    // .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                    
                    Button {
                        vm.sendOTP()
                        
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
                    TextField("enter the Otp",text: $vm.otpCode)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .keyboardType(.numberPad)
                    
                    Button {
                        vm.verifyOtp()
                        
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
        .navigationDestination(isPresented: $vm.isSigned) {
            HomeView()
        }
    }
}






#Preview {
    SignInFormView()
}
