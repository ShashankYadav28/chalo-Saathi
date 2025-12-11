import SwiftUI
import MapKit
import FirebaseFirestore
import FirebaseAuth
import Combine

// MARK: - Preference keys for anchors (Keep existing logic)
private struct FromAnchorKey: PreferenceKey {
    static var defaultValue: Anchor<CGRect>? = nil
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = nextValue() ?? value
    }
}
private struct ToAnchorKey: PreferenceKey {
    static var defaultValue: Anchor<CGRect>? = nil
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = nextValue() ?? value
    }
}

// MARK: - Reusable bordered card (Updated to match UI)
private struct FormCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
        // Soft border and shadow to match the clean look
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
}

//keyboard Helper
final class KeyboardHeightHelper: ObservableObject {
    @Published var keyboardHeight: CGFloat = 0
    private var cancellables = Set<AnyCancellable>()

    init() {
        let willShow = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect }
            .map { $0.height }

        let willHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }

        Publishers.Merge(willShow, willHide)
            .receive(on: RunLoop.main)
            .assign(to: \.keyboardHeight, on: self)
            .store(in: &cancellables)
    }
}

// MARK: - PublishRideView
struct PublishRideView: View {
    @ObservedObject var locationManager: LocationManagerRideSearch
    let currentUser: AppUser

    @State private var fromAddress: String = ""
    @State private var toAddress: String = ""
    @State private var selectedDateTime = Date()
    @State private var availableSeats = 1
    @State private var vehicleType: VehicleType = .car
    @State private var farePerKm: String = ""
    @State private var genderPreference: GenderPreference = .all
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isPublishing = false
    @State private var showDriverTracking = false
    @State private var publishedRide: Ride?
    @State private var fromCoordinate: CLLocationCoordinate2D?
    @State private var toCoordinate: CLLocationCoordinate2D?

    @StateObject private var fromCompleter = LocationsearchCompleter()
    @StateObject private var toCompleter = LocationsearchCompleter()

    @State private var activeField: SearchField? = nil
    @State private var hasEditedFrom = false
    @State private var showFromSuggestions = false
    @State private var showToSuggestions = false

    // Anchors for floating overlay
    @State private var fromAnchor: Anchor<CGRect>? = nil
    @State private var toAnchor: Anchor<CGRect>? = nil

    @StateObject private var keyboard = KeyboardHeightHelper()

    enum SearchField { case from, to }
    
    enum VehicleType: String, CaseIterable {
        case car = "Car", bike = "Bike"
    }
    
    enum GenderPreference: String, CaseIterable {
        case all = "All", male = "Male Only", female = "Female Only"
        var firestoreValue: [String] {
            switch self {
            case .all: return ["male","female","all"]
            case .male: return ["male","all"]
            case .female: return ["female","all"]
            }
        }
    }

    var isFormValid: Bool {
        !fromAddress.isEmpty && !toAddress.isEmpty && !farePerKm.isEmpty &&
        fromCoordinate != nil && toCoordinate != nil
    }

    // Clean Gray Background
    private var appBackground: Color {
        Color(red: 242/255, green: 242/255, blue: 247/255)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Header Title
                    Text("Publish a Ride")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.top, 10)

                    // MARK: - 1. ROUTE CARD
                    FormCard {
                        Text("Route")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)

                        VStack(spacing: 12) {
                            // Pickup Field
                            HStack {
                                TextField("Pickup Location", text: $fromCompleter.searchQuery)
                                    .font(.system(size: 15))
                                    .onTapGesture {
                                        activeField = .from
                                        showFromSuggestions = true
                                        showToSuggestions = false
                                    }
                                    .onChange(of: fromCompleter.searchQuery) { newValue in
                                        hasEditedFrom = true
                                        fromAddress = newValue
                                        showFromSuggestions = !newValue.isEmpty
                                    }
                                
                                // Navigation Arrow Icon (Right side)
                                Button(action: useCurrentLocation) {
                                    Image(systemName: "location.north.circle.fill") // or paperplane.fill
                                        .foregroundColor(.blue)
                                        .font(.system(size: 20))
                                }
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray5), lineWidth: 1)
                            )
                            .anchorPreference(key: FromAnchorKey.self, value: .bounds) { $0 }

                            // Drop-off Field
                            HStack {
                                TextField("Drop-off Location", text: $toCompleter.searchQuery)
                                    .font(.system(size: 15))
                                    .onTapGesture {
                                        activeField = .to
                                        showToSuggestions = true
                                        showFromSuggestions = false
                                    }
                                    .onChange(of: toCompleter.searchQuery) { newValue in
                                        toAddress = newValue
                                        showToSuggestions = !newValue.isEmpty
                                    }
                                
                                // Pin Icon (Right side)
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundColor(.black.opacity(0.7))
                                    .font(.system(size: 20))
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray5), lineWidth: 1)
                            )
                            .anchorPreference(key: ToAnchorKey.self, value: .bounds) { $0 }
                        }
                    }

                    // MARK: - 2. SCHEDULE & SEATS CARD
                    FormCard {
                        Text("Schedule & Seats")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                        
                        // Date and Time Row
                        HStack(spacing: 12) {
                            // Date Box
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.gray)
                                DatePicker("", selection: $selectedDateTime, displayedComponents: .date)
                                    .labelsHidden()
                                    .accentColor(.blue)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            
                            // Time Box
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.gray)
                                DatePicker("", selection: $selectedDateTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .accentColor(.blue)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                        }

                        // Available Seats Row
                        HStack {
                            Text("Available seats")
                                .font(.system(size: 15))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            // Compact Stepper [ -  1  + ]
                            HStack(spacing: 0) {
                                Button(action: { if availableSeats > 1 { availableSeats -= 1 } }) {
                                    Text("−")
                                        .font(.system(size: 20, weight: .medium))
                                        .frame(width: 35, height: 35)
                                        .background(Color(.systemGray6))
                                        .foregroundColor(.black)
                                }
                                .disabled(availableSeats <= 1)
                                
                                Text("\(availableSeats)")
                                    .font(.system(size: 16, weight: .semibold))
                                    .frame(width: 40, height: 35)
                                    .background(Color(.systemGray6))
                                
                                Button(action: { if availableSeats < 8 { availableSeats += 1 } }) {
                                    Text("+")
                                        .font(.system(size: 20, weight: .medium))
                                        .frame(width: 35, height: 35)
                                        .background(Color(.systemGray6))
                                        .foregroundColor(.black)
                                }
                                .disabled(availableSeats >= 8)
                            }
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.systemGray5), lineWidth: 1))
                        }
                    }

                    // MARK: - 3. VEHICLE & FARE CARD
                    FormCard {
                        Text("Vehicle & Fare")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)

                        // Vehicle Type Toggle (Car | Bike)
                        HStack(spacing: 0) {
                            ForEach(VehicleType.allCases, id: \.self) { type in
                                Button(action: { vehicleType = type }) {
                                    Text(type.rawValue)
                                        .font(.system(size: 15, weight: .medium))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(vehicleType == type ? Color.blue : Color(.systemGray6).opacity(0.5))
                                        .foregroundColor(vehicleType == type ? .white : .black)
                                }
                            }
                        }
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.systemGray5), lineWidth: 1))
                        
                        // Fare Field
                        HStack {
                            Text("Fare per kilometer (₹)")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            
                            TextField("e.g. 5", text: $farePerKm)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray5), lineWidth: 1)
                        )
                    }

                    // MARK: - 4. PASSENGER PREFERENCE
                    FormCard {
                        Text("Passenger Preference")
                            .font(.system(size: 15, weight: .bold))
                        
                        // Horizontal Radio Buttons
                        HStack(spacing: 15) {
                            ForEach(GenderPreference.allCases, id: \.self) { pref in
                                Button(action: { genderPreference = pref }) {
                                    HStack(spacing: 6) {
                                        // Custom Radio Circle
                                        ZStack {
                                            Circle()
                                                .stroke(genderPreference == pref ? Color.blue : Color.gray, lineWidth: 1.5)
                                                .frame(width: 18, height: 18)
                                            
                                            if genderPreference == pref {
                                                Circle()
                                                    .fill(Color.blue)
                                                    .frame(width: 10, height: 10)
                                            }
                                        }
                                        
                                        Text(pref.rawValue)
                                            .font(.system(size: 14))
                                            .foregroundColor(.primary)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }

                    // MARK: - PUBLISH BUTTON
                    Button(action: publishRide) {
                        Text("Publish ride")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(isFormValid && !isPublishing ? Color.blue : Color.blue.opacity(0.6))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(!isFormValid || isPublishing)
                    .padding(.top, 10)
                    
                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 16)
            }
            .background(appBackground)
            .scrollIndicators(.hidden)
            .coordinateSpace(name: "root")
            .onPreferenceChange(FromAnchorKey.self) { self.fromAnchor = $0 }
            .onPreferenceChange(ToAnchorKey.self) { self.toAnchor = $0 }
            
            // Location Manager Listener
            .onChange(of: locationManager.currentAddress) { newAddr in
                if !hasEditedFrom && !newAddr.isEmpty {
                    fromAddress = newAddr
                    fromCoordinate = locationManager.location
                    fromCompleter.searchQuery = newAddr
                }
            }
            .onAppear {
                if fromAddress.isEmpty, !locationManager.currentAddress.isEmpty {
                    fromAddress = locationManager.currentAddress
                    fromCoordinate = locationManager.location
                    fromCompleter.searchQuery = fromAddress
                }
            }
            .onTapGesture { dismissSuggestions() }

            // MARK: - AUTOCOMPLETE OVERLAYS (Unchanged Logic)
            if showFromSuggestions, let anchor = fromAnchor, !fromCompleter.searchresult.isEmpty {
                GeometryReader { proxy in
                    let rect = proxy[anchor]
                    suggestionOverlay(proxy: proxy, anchorRect: rect, results: fromCompleter.searchresult, isFrom: true)
                }
                .coordinateSpace(name: "root")
                .zIndex(1000)
            }

            if showToSuggestions, let anchor = toAnchor, !toCompleter.searchresult.isEmpty {
                GeometryReader { proxy in
                    let rect = proxy[anchor]
                    suggestionOverlay(proxy: proxy, anchorRect: rect, results: toCompleter.searchresult, isFrom: false)
                }
                .coordinateSpace(name: "root")
                .zIndex(1000)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showDriverTracking) {
            if let ride = publishedRide {
                DriverTrackingView(ride: ride, currentUser: currentUser)
            }
        }
        .alert(alertMessage, isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        }
    }

    // MARK: - Suggestion overlay (Visual Tweak for consistency)
    @ViewBuilder
    private func suggestionOverlay(
        proxy: GeometryProxy,
        anchorRect: CGRect,
        results: [MKLocalSearchCompletion],
        isFrom: Bool
    ) -> some View {
        let rowHeight: CGFloat = 52
        let count = min(results.prefix(5).count, 5)
        let totalHeight = CGFloat(count) * rowHeight
        let sidePadding: CGFloat = 16
        let screen = UIScreen.main.bounds
        let cardWidth = screen.width - (sidePadding * 2)
        let centerX = screen.width / 2.0
        let verticalOffset: CGFloat = 6

        // Simple logic to place below field
        let yPos = anchorRect.maxY + (totalHeight / 2) + verticalOffset

        VStack(spacing: 0) {
            ForEach(Array(results.prefix(5).enumerated()), id: \.offset) { index, result in
                Button {
                    selectLocation(result, isFrom: isFrom)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 16))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(result.title)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            Text(result.subtitle)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .frame(height: rowHeight)
                    .background(Color.white)
                }
                .buttonStyle(PlainButtonStyle())

                if index != count - 1 {
                    Divider().padding(.leading, 40)
                }
            }
        }
        .frame(width: cardWidth, height: totalHeight)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        .position(x: centerX, y: yPos)
    }

    // MARK: - Helper functions (Kept exactly same)
    func useCurrentLocation() {
        hasEditedFrom = false
        if !locationManager.currentAddress.isEmpty {
            fromAddress = locationManager.currentAddress
            fromCoordinate = locationManager.location
            fromCompleter.searchQuery = fromAddress
        }
        fromCompleter.searchresult.removeAll()
        dismissSuggestions()
    }

    func dismissSuggestions() {
        activeField = nil
        showFromSuggestions = false
        showToSuggestions = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    func selectLocation(_ completion: MKLocalSearchCompletion, isFrom: Bool) {
        let completer = isFrom ? fromCompleter : toCompleter
        completer.getCoordinate(for: completion) { coordinate, address in
            DispatchQueue.main.async {
                if let coordinate = coordinate, let address = address {
                    if isFrom {
                        fromAddress = address
                        fromCoordinate = coordinate
                        hasEditedFrom = true
                        fromCompleter.searchQuery = address
                        showFromSuggestions = false
                    } else {
                        toAddress = address
                        toCoordinate = coordinate
                        toCompleter.searchQuery = address
                        showToSuggestions = false
                    }
                    completer.searchresult.removeAll()
                    dismissSuggestions()
                }
            }
        }
    }

    func publishRide() {
        // User must be logged in
        guard let uid = Auth.auth().currentUser?.uid else {
            alertMessage = "Please sign in again to publish a ride."
            showingAlert = true
            return
        }

        // Fallback to current location for pickup if needed
        if fromAddress.isEmpty, !locationManager.currentAddress.isEmpty {
            fromAddress = locationManager.currentAddress
            fromCoordinate = locationManager.location
        }

        guard let fromCoord = fromCoordinate,
              let toCoord = toCoordinate,
              !farePerKm.isEmpty else {
            alertMessage = "Please fill all required fields correctly"
            showingAlert = true
            return
        }

        isPublishing = true
        let db = Firestore.firestore()
        let rideRef = db.collection("rides").document()

        let rideData: [String: Any] = [
            "driverId": uid,                                   // 👈 use auth uid
            "driverName": currentUser.name,
            "driverPhone": currentUser.phone ?? "",
            "driverGender": currentUser.gender.lowercased() ?? "all",
            "fromAddress": fromAddress,
            "fromLat": fromCoord.latitude,
            "fromLong": fromCoord.longitude,
            "toAddress": toAddress,
            "toLat": toCoord.latitude,
            "toLong": toCoord.longitude,
            "date": Timestamp(date: selectedDateTime),
            "availableSeats": availableSeats,
            "vehicleType": vehicleType.rawValue.lowercased(),
            "farePerKm": farePerKm,
            "genderPreference": genderPreference.firestoreValue,
            "status": "active",
            "passengers": [],
            "createdAt": FieldValue.serverTimestamp()
        ]

        rideRef.setData(rideData) { error in
            DispatchQueue.main.async {
                isPublishing = false

                if let error = error {
                    alertMessage = "Failed to publish ride: \(error.localizedDescription)"
                    showingAlert = true
                } else {
                    publishedRide = Ride(
                        id: rideRef.documentID,
                        driverId: uid,                        // 👈 keep consistent
                        driverName: currentUser.name,
                        driverPhone: currentUser.phone,
                        driverGender: currentUser.gender.lowercased() ?? "all",
                        fromAddress: fromAddress,
                        fromLat: fromCoord.latitude,
                        fromLong: fromCoord.longitude,
                        toAddress: toAddress,
                        toLat: toCoord.latitude,
                        toLong: toCoord.longitude,
                        date: selectedDateTime,
                        availableSeats: availableSeats,
                        vehicleType: vehicleType.rawValue.lowercased(),
                        farePerKm: farePerKm,
                        genderPreference: genderPreference.firestoreValue,
                        status: "active",
                        passengers: []
                    )

                    showDriverTracking = true
                }
            }
        }
    }
}
