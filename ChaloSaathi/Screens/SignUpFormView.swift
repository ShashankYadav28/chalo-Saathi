import SwiftUI

struct SignUpFormView: View {
    @ObservedObject var vm: SignUPViewModel
    var onSignUPSuccess: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 18) {
            // Full Name
            TextField("Full Name", text: $vm.name)
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
            
            // Email
            TextField("Email", text: $vm.email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
            
            // Phone Number
            TextField("Phone Number", text: $vm.phone)
                .keyboardType(.phonePad)
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
            
            // Password
            SecureField("Password", text: $vm.password)
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
            
            // Gender Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Gender")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
                
                Menu {
                    Button("Male") { vm.gender = "male" }
                    Button("Female") { vm.gender = "female" }
                    Button("Other") { vm.gender = "other" }
                } label: {
                    HStack {
                        Text(vm.gender.isEmpty ? "Select Gender" : vm.gender.capitalized)
                            .foregroundColor(vm.gender.isEmpty ? .secondary : .primary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                }
            }
            
            // Vehicle Type Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Vehicle Type (Optional)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
                
                Menu {
                    Button("None") { vm.vehicleType = "" }
                    Button("Car") { vm.vehicleType = "car" }
                    Button("Bike") { vm.vehicleType = "bike" }
                    Button("Auto") { vm.vehicleType = "auto" }
                } label: {
                    HStack {
                        Text(vm.vehicleType.isEmpty ? "Select Vehicle Type (Optional)" : vm.vehicleType.capitalized)
                            .foregroundColor(vm.vehicleType.isEmpty ? .secondary : .primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                }
            }
            
            // Aadhaar Number
            TextField("Aadhaar Number (Optional)", text: $vm.aadhaar)
                .keyboardType(.numberPad)
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
            
            // Sign Up Button
            Button {
                vm.signUpUser()
            } label: {
                if vm.isLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                } else {
                    Text("Sign Up")
                        .foregroundColor(.white)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
            }
            .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
            .disabled(vm.isLoading)
        }
        .alert("SignUp Status", isPresented: $vm.showAlert) {
            Button("OK") {
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
    SignUpFormView(vm: SignUPViewModel())
}
