//
//  SignInViewModel.swift
//  ChaloSaathi
//
//  Created by Shashank Yadav on 06/10/25.
//

import Foundation
import FirebaseAuth

class SignInViewModel: ObservableObject {
    
    @Published  var email = ""
    @Published  var password = ""
    @Published  var phoneNumber = ""
    @Published  var otpCode = ""
    @Published  var isSigned = false
    @Published  var isLoading = false
    @Published  var errorMessage:String?
    @Published  var isCodeSent = false
    @Published  var verificationId : String?
  //  @Published  var islogin = false
    
    init() {
        if Auth.auth().currentUser != nil {
            isSigned = true
        }
    }
    
    func loginWithEmail(){
        isLoading = true
        Auth.auth().signIn(withEmail: email, password: password){ [weak self] result, error in
            guard let self = self else {
                return
            }
            DispatchQueue.main.async {
                self.isLoading = true
                
                if let error = error{
                    self.errorMessage = error.localizedDescription
                }
                else {
                    self.isSigned = true
                }
            }
            
            
        }
    }
    func signOut(){
        do {
            try Auth.auth().signOut()
            
            
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
    func sendOTP() {
        isLoading  = true
        
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { [weak self] verificationID, error in
            guard let self = self else {
                return
            }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error  = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                self.verificationId  = verificationID
                self.isCodeSent = true
                
                
            }
        }
    }
    
    func verifyOtp(){
        guard let verificationId  = verificationId else {
            errorMessage = "Otp is missing "
            return
            
        }
        
        let credential  = PhoneAuthProvider.provider().credential(withVerificationID: verificationId, verificationCode: otpCode)   // here verfication id id the id that is sent from the firebase and otp code is the code that is typed bu the user
        
        isLoading = true
        Auth.auth().signIn(with: credential){ [weak self] result, error in
            
            guard let self  = self else {   
                return
                
            }
            DispatchQueue.main.async {
                self.isLoading = false
                if let error  = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                self.isSigned = true
                
            }
            
        }
    }
    
    
    
}
