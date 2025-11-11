import SwiftUI
import FirebaseAuth

struct SignInFormView: View {
    @ObservedObject var vm: SignInViewModel
    @State private var selectedAuthMethod: AuthMethod = .email
    
    enum AuthMethod {
        case email
        case phone
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Auth Method Switcher
            HStack(spacing: 8) {
                AuthMethodButton(
                    title: "Email",
                    icon: "envelope.fill",
                    isSelected: selectedAuthMethod == .email
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedAuthMethod = .email
                        vm.resetForm()
                    }
                }
                
                AuthMethodButton(
                    title: "Phone",
                    icon: "phone.fill",
                    isSelected: selectedAuthMethod == .phone
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedAuthMethod = .phone
                        vm.resetForm()
                    }
                }
            }
            .padding(4)
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            
            // Content Based on Selection
            if selectedAuthMethod == .email {
                emailAuthSection
            } else {
                phoneAuthSection
            }
        }
        .fullScreenCover(isPresented: $vm.isSigned) {
            HomeScreen()
        }
    }
    
    // MARK: - Email Auth Section
    private var emailAuthSection: some View {
        VStack(spacing: 18) {
            // Email Field
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "envelope.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Email Address")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 4)
                
                TextField("Enter your email", text: $vm.email)
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Password")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 4)
                
                SecureField("Enter your password", text: $vm.password)
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
            
            // Sign In Button
            Button(action: {
                vm.loginWithEmail()
            }) {
                Group {
                    if vm.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title3)
                            Text("Sign In")
                                .font(.headline)
                        }
                    }
                }
                .foregroundColor(.white)
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
                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .disabled(vm.isLoading || vm.email.isEmpty || vm.password.isEmpty)
            .opacity((vm.isLoading || vm.email.isEmpty || vm.password.isEmpty) ? 0.6 : 1)
            .padding(.top, 8)
            
            // Forgot Password
            Button(action: {
                // Handle forgot password
            }) {
                Text("Forgot Password?")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            .padding(.top, 4)
        }
    }
    
    // MARK: - Phone Auth Section
    private var phoneAuthSection: some View {
        VStack(spacing: 18) {
            if !vm.isCodeSent {
                // Phone Number Input
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "phone.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Phone Number")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.leading, 4)
                    
                    HStack(spacing: 10) {
                        // Country Code
                        Text("+91")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 16)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        
                        // Phone Number Field
                        TextField("9876543210", text: $vm.phoneNumber)
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .keyboardType(.numberPad)
                    }
                }
                
                // Send OTP Button
                Button(action: {
                    vm.sendOTP()
                }) {
                    Group {
                        if vm.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            HStack(spacing: 8) {
                                Image(systemName: "message.fill")
                                    .font(.title3)
                                Text("Send OTP")
                                    .font(.headline)
                            }
                        }
                    }
                    .foregroundColor(.white)
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
                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .disabled(vm.isLoading || vm.phoneNumber.count < 10)
                .opacity((vm.isLoading || vm.phoneNumber.count < 10) ? 0.6 : 1)
                .padding(.top, 8)
                
                // Info Message
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text("We'll send you a 6-digit verification code")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 4)
                
            } else {
                // OTP Verification
                VStack(spacing: 16) {
                    // Success Icon
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.1))
                            .frame(width: 70, height: 70)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.green)
                    }
                    .padding(.bottom, 4)
                    
                    VStack(spacing: 6) {
                        Text("Verification Code Sent")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Text("Enter the 6-digit code sent to")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("+91 \(vm.phoneNumber)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    .padding(.bottom, 12)
                    
                    // OTP Input Field
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "lock.shield.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Verification Code")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 4)
                        
                        TextField("Enter 6-digit code", text: $vm.otpCode)
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 22, weight: .semibold))
                    }
                    
                    // Verify Button
                    Button(action: {
                        vm.verifyOtp()
                    }) {
                        Group {
                            if vm.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title3)
                                    Text("Verify & Sign In")
                                        .font(.headline)
                                }
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            LinearGradient(
                                colors: [.green, .green.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .disabled(vm.isLoading || vm.otpCode.count < 6)
                    .opacity((vm.isLoading || vm.otpCode.count < 6) ? 0.6 : 1)
                    .padding(.top, 8)
                    
                    // Resend OTP
                    HStack(spacing: 4) {
                        Text("Didn't receive the code?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            vm.sendOTP()
                        }) {
                            Text("Resend")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.top, 4)
                    
                    // Change Number
                    Button(action: {
                        vm.isCodeSent = false
                        vm.otpCode = ""
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.left.circle.fill")
                            Text("Change Number")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    }
                    .padding(.top, 2)
                }
            }
        }
    }
}

// MARK: - Auth Method Button
struct AuthMethodButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : .gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        Color.clear
                    }
                }
            )
            .cornerRadius(10)
        }
    }
}

// MARK: - SignIn ViewModel Extension
extension SignInViewModel {
    func resetForm() {
        email = ""
        password = ""
        phoneNumber = ""
        otpCode = ""
        isCodeSent = false
        errorMessage = nil
    }
}

#Preview {
    SignInFormView(vm: SignInViewModel())
}
