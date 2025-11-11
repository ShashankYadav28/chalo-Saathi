import SwiftUI
import FirebaseAuth

struct SignIn: View {
    @StateObject private var signInViewModel = SignInViewModel()
    @StateObject private var signUpViewModel = SignUPViewModel()
    @State private var isLogin = true
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Background gradient
                Color(red: 0.15, green: 0.25, blue: 0.25)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header Section
                    VStack(alignment: .leading, spacing: 8) {
                        if isLogin {
                            Text("Go ahead Continue\nwith the Login")
                                .font(.system(size: min(32, geometry.size.width * 0.085), weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                            
                            Text("Login into the Account.")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        } else {
                            Text("Sign up now to access\nyour personal account")
                                .font(.system(size: min(32, geometry.size.width * 0.085), weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                            
                            Text("Sign up to access your own account and exclusive features")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, max(geometry.size.width * 0.08, 20))
                    .padding(.top, geometry.safeAreaInsets.top > 0 ?
                             max(geometry.safeAreaInsets.top + 10, 40) : 40)
                    .padding(.bottom, max(geometry.size.height * 0.025, 20))
                    .animation(.easeInOut(duration: 0.3), value: isLogin)
                    
                    // White Card Section with Forms
                    VStack(spacing: 0) {
                        // Tab Switcher
                        HStack(spacing: 0) {
                            Text("Login")
                                .font(.headline)
                                .foregroundColor(isLogin ? .primary : .secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(isLogin ? Color.white : Color(.systemGray6))
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3)) {
                                        isLogin = true
                                    }
                                }
                            
                            Text("Sign Up")
                                .font(.headline)
                                .foregroundColor(isLogin ? .secondary : .primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(isLogin ? Color(.systemGray6) : Color.white)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3)) {
                                        isLogin = false
                                    }
                                }
                        }
                        .padding(6)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .padding(.horizontal, max(geometry.size.width * 0.05, 16))
                        .padding(.top, max(geometry.size.height * 0.025, 20))
                        .padding(.bottom, max(geometry.size.height * 0.015, 12))
                        
                        // Scrollable Form Content
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack {
                                if isLogin {
                                    SignInFormView(vm: signInViewModel)
                                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                                } else {
                                    SignUpFormView(vm: signUpViewModel, onSignUPSuccess: {
                                        withAnimation {
                                            isLogin = true
                                        }
                                    })
                                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                                }
                            }
                            .padding(.horizontal, max(geometry.size.width * 0.05, 16))
                            .padding(.bottom, max(geometry.size.height * 0.03, 30))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        Color.white
                            .cornerRadius(20, corners: [.topLeft, .topRight])
                    )
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .alert(isPresented: .constant(signInViewModel.errorMessage != nil)) {
            Alert(
                title: Text("Error"),
                message: Text(signInViewModel.errorMessage ?? "Something went wrong"),
                dismissButton: .default(Text("OK"), action: {
                    signInViewModel.errorMessage = nil
                })
            )
        }
    }
}

// MARK: - Rounded Corner Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    SignIn()
}
