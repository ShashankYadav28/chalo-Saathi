//
//  SignUpFormView.swift
//  ChaloSaathi
//
//  Created by Shashank Yadav on 06/10/25.
//

import SwiftUI

struct SignUpFormView: View {
    @StateObject var vm  = SignUPViewModel()
    
    var onSignUPSuccess: (() -> Void)?
    
    
    var body: some View {
        VStack(spacing: 18) {
            
            
            TextField("Full Name", text: $vm.name)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius:8).stroke(Color.gray, lineWidth: 0.5))
            
            
            TextField("Email",text: $vm.email)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius:8).stroke(Color.gray, lineWidth: 0.5))
            
            
            SecureField("Password",text: $vm.password)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius:8).stroke(Color.gray, lineWidth: 0.5))
            
            
            TextField("Gender (Male/Female/Other",text: $vm.gender)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius:8).stroke(Color.gray, lineWidth: 0.5))
            
            
            TextField("Vehicle Type (car/Bike/None",text: $vm.vehicleType)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius:8).stroke(Color.gray, lineWidth: 0.5))
            
            
            TextField("Aadhaar Number", text: $vm.aadhaar)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius:8).stroke(Color.gray, lineWidth: 0.5))
            
            
            Button {
                vm.signUpUser()
            } label:  {
                if vm.isLoading {
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
        .alert("SignUpstatus", isPresented: $vm.showAlert) {
            Button("ok"){
                if vm.signedUpSuccess {
                    
                    onSignUPSuccess?()
                    
                }
            }
            
            
        } message: {
            Text(vm.alertMessage)
        }
        
    }
}



#Preview {
    SignUpFormView()
}
