// MARK: - HomeScreen.swift
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HomeScreen: View {
    @StateObject private var locationManager = LocationManagerRideSearch()
    @StateObject private var userViewModel = UserViewModel()
    
    @State private var selectedTopTab: TopTab = .search
    @State private var selectedBottomTab: BottomTab = .home
    @State private var showProfile = false
    @State private var showLogoutAlert = false
    
    enum TopTab {
        case search
        case publish
    }
    
    enum BottomTab: String, CaseIterable {
        case home = "Home"
        case rides = "Rides"
        case inbox = "Alerts"
        case profile = "Profile"
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .rides: return "car.fill"
            case .inbox: return "bell.fill"
            case .profile: return "person.fill"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header - Only show on home tab
                if selectedBottomTab == .home {
                    headerView
                }
                
                // Main Content
                ZStack {
                    Color(.systemGroupedBackground)
                        .ignoresSafeArea()
                    
                    if userViewModel.isLoading {
                        loadingView
                    } else if let user = userViewModel.currentUser {
                        Group {
                            switch selectedBottomTab {
                            case .home:
                                homeContent(user: user)
                            case .rides:
                                MyRidesView(currentUser: user)
                            case .inbox:
                                NotificationsView(currentUser: user)
                            case .profile:
                                ProfileView(currentUser: user)
                            }
                        }
                    } else if let errorMessage = userViewModel.errorMessage {
                        // Show error message
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)
                            
                            Text("Unable to Load User Data")
                                .font(.headline)
                            
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button {
                                Task {
                                    await userViewModel.fetchCurrentUser()
                                }
                            } label: {
                                Text("Retry")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(width: 120)
                                    .padding(.vertical, 12)
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                        }
                    } else {
                        // Fallback
                        VStack(spacing: 16) {
                            Image(systemName: "person.crop.circle.badge.exclamationmark")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            
                            Text("No User Data")
                                .font(.headline)
                            
                            Button {
                                Task {
                                    await userViewModel.fetchCurrentUser()
                                }
                            } label: {
                                Text("Reload")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(width: 120)
                                    .padding(.vertical, 12)
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                        }
                    }
                }
                
                // Bottom Navigation
                bottomNavigation
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(true)
        }
        .onAppear {
            print("🏠 HomeScreen appeared")
            print("   Current user: \(userViewModel.currentUser?.name ?? "nil")")
            print("   Is loading: \(userViewModel.isLoading)")
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white, Color.gray.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(Color.blue, lineWidth: 2)
                        )
                    
                    Image(systemName: "car.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 20, weight: .semibold))
                }
                .shadow(color: .blue.opacity(0.2), radius: 4, x: 0, y: 2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("ChalooSaathi")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Save Money, Share Ride")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Logout Button (Emergency)
            Button {
                showLogoutAlert = true
            } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.red)
                    .frame(width: 44, height: 44)
                    .background(Color.red.opacity(0.1))
                    .clipShape(Circle())
            }
            .padding(.trailing, 8)
            
            // User Profile Button
            Button {
                showProfile = true
            } label: {
                if let user = userViewModel.currentUser {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.orange, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text(user.name.prefix(1).uppercased())
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                                .font(.system(size: 20))
                        )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
        .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
        .sheet(isPresented: $showProfile) {
            if let user = userViewModel.currentUser {
                ProfileSheetView(showProfile: $showProfile, currentUser: user)
            }
        }
        .alert("Logout", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                handleLogout()
            }
        } message: {
            Text("Are you sure you want to logout? You'll need to sign in again.")
        }
    }
    
    // MARK: - Home Content
    private func homeContent(user: AppUser) -> some View {
        VStack(spacing: 0) {
            // Tab Switcher
            tabSwitcher
                .padding(.top, 12)
            
            // Content
            switch selectedTopTab {
            case .search:
                SearchRideView(
                    locationManager: locationManager,
                    currentUser: user
                )
                .transition(.opacity)
            case .publish:
                PublishRideView(
                    locationManager: locationManager,
                    currentUser: user
                )
                .transition(.opacity)
            }
        }
    }
    
    // MARK: - Tab Switcher
    private var tabSwitcher: some View {
        HStack(spacing: 8) {
            TabButton(
                title: "Search for Ride",
                icon: "magnifyingglass",
                isSelected: selectedTopTab == .search,
                action: {
                    withAnimation(.spring(response: 0.3)) {
                        selectedTopTab = .search
                    }
                }
            )
            
            TabButton(
                title: "Publish a Ride",
                icon: "plus.circle.fill",
                isSelected: selectedTopTab == .publish,
                action: {
                    withAnimation(.spring(response: 0.3)) {
                        selectedTopTab = .publish
                    }
                }
            )
        }
        .padding(6)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Bottom Navigation
    private var bottomNavigation: some View {
        HStack(spacing: 0) {
            ForEach(BottomTab.allCases, id: \.self) { tab in
                BottomNavItem(
                    icon: tab.icon,
                    title: tab.rawValue,
                    isSelected: selectedBottomTab == tab,
                    action: {
                        withAnimation(.spring(response: 0.3)) {
                            selectedBottomTab = tab
                        }
                    }
                )
            }
        }
        .padding(.vertical, 12)
        .padding(.bottom, 4)
        .background(
            Color.white
                .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
        )
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.3)
            Text("Loading your data...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Logout Handler
    private func handleLogout() {
        do {
            try Auth.auth().signOut()
            print("✅ User logged out successfully")
            // The app will automatically return to login screen
        } catch {
            print("❌ Logout failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Tab Button
struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : .gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        Color.clear
                    }
                }
            )
            .cornerRadius(12)
        }
    }
}

// MARK: - Bottom Nav Item
struct BottomNavItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 40, height: 40)
                    }
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .blue : .gray)
                }
                
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
    }
}

// MARK: - User View Model
@MainActor
class UserViewModel: ObservableObject {
    @Published var currentUser: AppUser?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        print("🔄 UserViewModel initialized")
        // Fetch user immediately on init
        Task {
            await fetchCurrentUser()
        }
    }
    
    func fetchCurrentUser() async {
        print("🔄 Starting user fetch...")
        
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user found")
            errorMessage = "No authenticated user. Please log in again."
            isLoading = false
            return
        }
        
        print("👤 User ID: \(userId)")
        isLoading = true
        errorMessage = nil
        
        do {
            print("📡 Fetching from Firestore...")
            let document = try await Firestore.firestore()
                .collection("users")
                .document(userId)
                .getDocument()
            
            print("📄 Document exists: \(document.exists)")
            
            if document.exists {
                if let user = try? document.data(as: AppUser.self) {
                    self.currentUser = user
                    print("✅ User loaded successfully: \(user.name)")
                    print("   Email: \(user.email)")
                    print("   Phone: \(user.phone)")
                } else {
                    print("❌ Failed to decode user data")
                    print("   Document data: \(document.data() ?? [:])")
                    errorMessage = "Failed to decode user data. Please contact support."
                }
            } else {
                print("❌ User document does not exist in Firestore")
                errorMessage = "User profile not found. Please complete registration."
            }
            
            self.isLoading = false
            
        } catch {
            print("❌ Error fetching user: \(error.localizedDescription)")
            print("   Error details: \(error)")
            self.errorMessage = "Network error: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
}

// MARK: - Profile Sheet View
struct ProfileSheetView: View {
    @Binding var showProfile: Bool
    let currentUser: AppUser
    @State private var showEditProfile = false
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text(currentUser.name.prefix(1).uppercased())
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        VStack(spacing: 4) {
                            Text(currentUser.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(currentUser.email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Profile Details Card
                    VStack(spacing: 0) {
                        ProfileSheetDetailRow(
                            icon: "phone.fill",
                            title: "Phone",
                            value: currentUser.phone,
                            color: .green
                        )
                        
                        Divider()
                            .padding(.leading, 60)
                        
                        ProfileSheetDetailRow(
                            icon: "person.fill",
                            title: "Gender",
                            value: currentUser.gender.capitalized,
                            color: .blue
                        )
                        
                        Divider()
                            .padding(.leading, 60)
                        
                        ProfileSheetDetailRow(
                            icon: "car.fill",
                            title: "Vehicle",
                            value: currentUser.vehicleType?.capitalized ?? "Not Set",
                            color: .blue
                        )
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .padding(.horizontal)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            showEditProfile = true
                        }) {
                            HStack(spacing: 8) {
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
                            HStack(spacing: 8) {
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
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showProfile = false
                    }
                    .fontWeight(.semibold)
                }
            }
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
    }
    
    private func handleLogout() {
        do {
            try Auth.auth().signOut()
            showProfile = false
            print("✅ User logged out successfully")
        } catch {
            print("❌ Logout failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Profile Sheet Detail Row
struct ProfileSheetDetailRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(color)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    HomeScreen()
}
