//
//  SignUPViewModel.swift
//  ChaloSaathi
//
//  Created by Shashank Yadav on 03/10/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class SignUPViewModel: ObservableObject {
    
    @Published  var name = ""
    @Published  var email = ""
    @Published  var password = ""
    @Published  var gender = ""
    @Published  var vehicleType = ""
    @Published  var aadhaar = ""
    @Published  var errorMessage = ""
    @Published  var isLoading = false
    @Published  var showAlert = false
    @Published  var alertMessage = ""
    @Published  var signedUpSuccess = false
    @Published  var goToSignIn = false
    
    
    func signUpUser() {
        guard !name.isEmpty, !email.isEmpty, !aadhaar.isEmpty, !vehicleType.isEmpty, !gender.isEmpty, !password.isEmpty else {
            alertMessage = "All fields are required to be filled "
            showAlert = true
            return
            
            
        }
        
        guard aadhaar.count == 12 else {
            alertMessage = "Aadhaar must be the 12 Digits "
            showAlert = true
            return
        }
        
        isLoading = true
        
        Auth.auth().createUser(withEmail: email, password: password) { result,error in
            
            DispatchQueue.main.async {
                
                
                self.isLoading  =  false
                if let error  =  error {
                    Task { @MainActor in
                        self.alertMessage = error.localizedDescription
                        self.showAlert = true
                        // self.isLoading = false
                        
                        
                    }
                    return
                }
                
                guard let uid  = result?.user.uid else {
                    return
                }
                
                let newUser = UserProfile(id: uid, name: self.name, email: self.email, gender: self.gender, aadhaar: self.aadhaar, vehicleType: self.vehicleType)
                
                do {
                    try Firestore.firestore().collection("users").document(uid).setData(from: newUser)
                    self.signedUpSuccess = true
                   
                    self.alertMessage = "SignedUPSuccessfully"
                    self.showAlert = true 
                    //self.signedUpSuccess = true
                    
                }
                catch {
                    self.alertMessage = error.localizedDescription
                    self.showAlert = true
                    
                    
                    
                }
            }
        }
        
        
    }
    
    
}




