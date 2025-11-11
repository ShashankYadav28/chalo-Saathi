import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {
    let currentUser: AppUser
    @State private var showEditProfile = false
    @State private var showLogoutAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile Header
                VStack(spacing: 16) {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text(currentUser.name.prefix(1).uppercased())
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    VStack(spacing: 4) {
                        Text(currentUser.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(currentUser.email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 20)
                
                // Stats Card
                HStack(spacing: 0) {
                    StatItem(icon: "car.fill", title: "Rides", value: "0", color: .blue)
                    
                    Divider()
                        .frame(height: 60)
                    
                    StatItem(icon: "star.fill", title: "Rating", value: "5.0", color: .orange)
                    
                    Divider()
                        .frame(height: 60)
                    
                    StatItem(icon: "indianrupeesign.circle.fill", title: "Saved", value: "₹0", color: .green)
                }
                .padding(.vertical, 20)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                .padding(.horizontal)
                
                // Profile Details Card
                VStack(spacing: 0) {
                    Text("Personal Information")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.gray.opacity(0.05))
                    
                    VStack(spacing: 16) {
                        ProfileDetailRow(
                            icon: "phone.fill",
                            title: "Phone",
                            value: currentUser.phone,
                            color: .green
                        )
                        
                        Divider()
                            .padding(.leading, 50)
                        
                        ProfileDetailRow(
                            icon: "person.fill",
                            title: "Gender",
                            value: currentUser.gender.capitalized,
                            color: .purple
                        )
                        
                        Divider()
                            .padding(.leading, 50)
                        
                        ProfileDetailRow(
                            icon: "car.fill",
                            title: "Vehicle Type",
                            value: currentUser.vehicleType?.capitalized ?? "Not Set",
                            color: .blue
                        )
                    }
                    .padding()
                }
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                .padding(.horizontal)
                
                // Settings Section
                VStack(spacing: 12) {
                    SettingsButton(
                        icon: "bell.fill",
                        title: "Notifications",
                        color: .orange
                    ) {
                        // Handle notifications settings
                    }
                    
                    SettingsButton(
                        icon: "lock.fill",
                        title: "Privacy & Security",
                        color: .indigo
                    ) {
                        // Handle privacy settings
                    }
                    
                    SettingsButton(
                        icon: "questionmark.circle.fill",
                        title: "Help & Support",
                        color: .teal
                    ) {
                        // Handle help
                    }
                    
                    SettingsButton(
                        icon: "doc.fill",
                        title: "Terms & Conditions",
                        color: .cyan
                    ) {
                        // Handle terms
                    }
                }
                .padding(.horizontal)
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        showEditProfile = true
                    }) {
                        HStack {
                            Image(systemName: "pencil.circle.fill")
                                .font(.title3)
                            Text("Edit Profile")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    
                    Button(action: {
                        showLogoutAlert = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square.fill")
                                .font(.title3)
                            Text("Logout")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.red, .red.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showEditProfile) {
            EditProfileView(currentUser: currentUser, isPresented: $showEditProfile)
        }
        .alert("Logout", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                handleLogout()
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
    }
    
    private func handleLogout() {
        do {
            try Auth.auth().signOut()
            // Navigate to login screen
            print("✅ User logged out successfully")
        } catch {
            print("❌ Logout failed: \(error.localizedDescription)")
        }
    }
}

struct StatItem: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ProfileDetailRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(color)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
    }
}

struct SettingsButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 16))
                            .foregroundColor(color)
                    )
                
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    let currentUser: AppUser
    @Binding var isPresented: Bool
    
    @State private var name: String
    @State private var phone: String
    @State private var gender: String
    @State private var vehicleType: String
    @State private var isUpdating = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    init(currentUser: AppUser, isPresented: Binding<Bool>) {
        self.currentUser = currentUser
        self._isPresented = isPresented
        _name = State(initialValue: currentUser.name)
        _phone = State(initialValue: currentUser.phone)
        _gender = State(initialValue: currentUser.gender)
        _vehicleType = State(initialValue: currentUser.vehicleType ?? "car")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Information") {
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.blue)
                        TextField("Name", text: $name)
                    }
                    
                    HStack {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.green)
                        TextField("Phone", text: $phone)
                            .keyboardType(.phonePad)
                    }
                }
                
                Section("Preferences") {
                    Picker("Gender", selection: $gender) {
                        Text("Male").tag("male")
                        Text("Female").tag("female")
                        Text("Other").tag("other")
                    }
                    .pickerStyle(.menu)
                    
                    Picker("Vehicle Type", selection: $vehicleType) {
                        Text("Car").tag("car")
                        Text("Bike").tag("bike")
                        Text("Auto").tag("auto")
                    }
                    .pickerStyle(.menu)
                }
                
                Section {
                    Button(action: updateProfile) {
                        if isUpdating {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .tint(.white)
                                Spacer()
                            }
                        } else {
                            Text("Save Changes")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(isUpdating)
                    .listRowBackground(Color.blue)
                    .foregroundColor(.white)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .alert("Profile Update", isPresented: $showAlert) {
                Button("OK") {
                    if alertMessage.contains("successfully") {
                        isPresented = false
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func updateProfile() {
        guard !name.isEmpty, !phone.isEmpty else {
            alertMessage = "Please fill all fields"
            showAlert = true
            return
        }
        
        isUpdating = true
        
        let updates: [String: Any] = [
            "name": name,
            "phone": phone,
            "gender": gender,
            "vehicleType": vehicleType
        ]
        
        Firestore.firestore()
            .collection("users")
            .document(currentUser.id ?? "101")
            .updateData(updates) { error in
                isUpdating = false
                
                if let error = error {
                    alertMessage = "Failed to update profile: \(error.localizedDescription)"
                } else {
                    alertMessage = "Profile updated successfully!"
                }
                
                showAlert = true
            }
    }
}

#Preview {
    ProfileView(currentUser: AppUser(
        id: "1",
        name: "Shashank Yadav",
        email: "shashank@example.com",
        phone: "8447038783",
        gender: "male",
        vehicleType: "car",
        profilePicture: "",
        fcmToken: "",
        createdAt: Date()
    ))
}
