import Foundation
import FirebaseAuth
import FirebaseFirestore

class SignUPViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var phone: String = ""        // ⭐ ADDED
    @Published var password: String = ""
    @Published var gender: String = ""
    @Published var vehicleType: String = ""
    @Published var aadhaar: String = ""
    
    @Published var isLoading: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published var signedUpSuccess: Bool = false
    
    func signUpUser() {
        // Validation
        guard !name.isEmpty else {
            alertMessage = "Please enter your full name"
            showAlert = true
            return
        }
        
        guard !email.isEmpty, email.contains("@") else {
            alertMessage = "Please enter a valid email"
            showAlert = true
            return
        }
        
        guard !phone.isEmpty, phone.count >= 10 else {
            alertMessage = "Please enter a valid phone number"
            showAlert = true
            return
        }
        
        guard !password.isEmpty, password.count >= 6 else {
            alertMessage = "Password must be at least 6 characters"
            showAlert = true
            return
        }
        
        guard !gender.isEmpty else {
            alertMessage = "Please select your gender"
            showAlert = true
            return
        }
        
        guard !vehicleType.isEmpty else {
            alertMessage = "Please select your vehicle type"
            showAlert = true
            return
        }
        
        // Optional: Validate Aadhaar if provided
        if !aadhaar.isEmpty && aadhaar.count != 12 {
            alertMessage = "Aadhaar number must be 12 digits"
            showAlert = true
            return
        }
        
        isLoading = true
        
        // Create user with Firebase Auth
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.isLoading = false
                self.alertMessage = "Sign up failed: \(error.localizedDescription)"
                self.showAlert = true
                return
            }
            
            guard let userId = result?.user.uid else {
                self.isLoading = false
                self.alertMessage = "Failed to get user ID"
                self.showAlert = true
                return
            }
            
            // Create user document in Firestore
            self.createUserDocument(userId: userId)
        }
    }
    
    private func createUserDocument(userId: String) {
        // Handle optional vehicleType - send NSNull() if empty
        let vehicleTypeValue: Any = vehicleType.isEmpty ? NSNull() : vehicleType.lowercased()
        
        let userData: [String: Any] = [
            "name": name,
            "email": email,
            "phone": phone,
            "gender": gender.lowercased(),
            "vehicleType": vehicleTypeValue,
            "profilePicture": "",
            "fcmToken": "",
            "createdAt": Timestamp(date: Date())
        ]
        
        Firestore.firestore()
            .collection("users")
            .document(userId)
            .setData(userData as [String : Any]) { [weak self] error in
                guard let self = self else { return }
                
                self.isLoading = false
                
                if let error = error {
                    self.alertMessage = "Failed to create user profile: \(error.localizedDescription)"
                    self.showAlert = true
                    
                    // Delete auth user if Firestore fails
                    Auth.auth().currentUser?.delete()
                } else {
                    self.signedUpSuccess = true
                    self.alertMessage = "Account created successfully! 🎉"
                    self.showAlert = true
                }
            }
    }
}
