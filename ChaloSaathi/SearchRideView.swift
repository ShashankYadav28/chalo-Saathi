import SwiftUI
import MapKit
import Combine

// MARK: - Keyboard helper
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

// MARK: - Anchor preference keys
private struct FromFieldAnchorKey: PreferenceKey {
    static var defaultValue: Anchor<CGRect>? = nil
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = nextValue() ?? value
    }
}
private struct ToFieldAnchorKey: PreferenceKey {
    static var defaultValue: Anchor<CGRect>? = nil
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = nextValue() ?? value
    }
}

// MARK: - SearchRideView (DROP-IN)
struct SearchRideView: View {
    
    @ObservedObject var locationManager: LocationManagerRideSearch
    @StateObject var viewModel = SearchRideViewModel()
    let currentUser: AppUser
    
    @State private var fromAddress: String = ""
    @State private var toAddress: String = ""
    @State private var selectedDateTime = Date()
    @State private var searchAnyDate = false
    
    @State private var fromCoordinate: CLLocationCoordinate2D?
    @State private var toCoordinate: CLLocationCoordinate2D?
    
    @StateObject private var fromLocationSearchCompleter = LocationsearchCompleter()
    @StateObject private var toLocationSearchCompleter = LocationsearchCompleter()
    @State private var showRideTrackingView = false
    @State private var showNoRideAlert = false
    @State private var foundRide: Ride?
    @State private var activeSearchField: SearchField? = nil
    
    // anchors provided via .anchorPreference and resolved via .onPreferenceChange
    @State private var fromAnchor: Anchor<CGRect>? = nil
    @State private var toAnchor: Anchor<CGRect>? = nil
    
    @StateObject private var keyboard = KeyboardHeightHelper()
    
    enum SearchField {
        case from, to
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // The main scrollable content; we name the coordinate space "root" so anchors resolve properly.
            GeometryReader { fullGeo in
                ScrollView {
                    VStack(spacing: 16) {
                        // FROM row
                        VStack(spacing: 0) {
                            HStack(spacing: 12) {
                                Image(systemName: "mappin.circle")
                                    .font(.system(size: 20))
                                    .foregroundColor(.red)
                                    .frame(width: 20)
                                
                                Text("FROM:")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.primary)
                                    .fixedSize()
                                
                                TextField("Enter the Location", text: $fromLocationSearchCompleter.searchQuery)
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .onTapGesture { activeSearchField = .from }
                                    .onChange(of: fromLocationSearchCompleter.searchQuery) { newValue in
                                        if !newValue.isEmpty { activeSearchField = .from }
                                    }
                                    // attach anchor preference for this field
                                    .anchorPreference(key: FromFieldAnchorKey.self, value: .bounds) { anchor in
                                        anchor
                                    }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal)
                            .background(RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white)
                                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2))
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .zIndex(activeSearchField == .from ? 100 : 0)
                        
                        // TO row
                        VStack(spacing: 0) {
                            HStack(spacing: 12) {
                                Image(systemName: "flag")
                                    .font(.system(size: 20))
                                    .foregroundColor(.blue)
                                    .frame(width: 20)
                                
                                Text("TO:")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.primary)
                                    .fixedSize()
                                
                                TextField("Search Destination", text: $toLocationSearchCompleter.searchQuery)
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity)
                                    .onTapGesture { activeSearchField = .to }
                                    .onChange(of: toLocationSearchCompleter.searchQuery) { newValue in
                                        if !newValue.isEmpty { activeSearchField = .to }
                                    }
                                    .anchorPreference(key: ToFieldAnchorKey.self, value: .bounds) { anchor in
                                        anchor
                                    }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal)
                            .background(RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white)
                                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2))
                        }
                        .padding(.horizontal, 20)
                        .zIndex(activeSearchField == .to ? 100 : 0)
                        
                        // TIME + FIND section (keeps your layout)
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Image(systemName: "clock")
                                    .font(.system(size: 20))
                                    .foregroundColor(.primary)
                                Text("TIME:")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.primary)
                                Spacer()
                                DatePicker("", selection: $selectedDateTime, displayedComponents: [.date, .hourAndMinute])
                                    .labelsHidden()
                                    .disabled(searchAnyDate)
                                    .opacity(searchAnyDate ? 0.5 : 1.0)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal)
                            
                            Toggle("Search rides on any date", isOn: $searchAnyDate)
                                .padding(.horizontal)
                                .padding(.bottom, 8)
                            
                            Button(action: {
                                dismissSuggestions()
                                performSearch()
                            }) {
                                HStack {
                                    if viewModel.isLoading {
                                        ProgressView().tint(.white)
                                    } else {
                                        Image(systemName: "magnifyingglass")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    Text("Find Rides").font(.system(size: 22, weight: .bold)).foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(RoundedRectangle(cornerRadius: 16).fill(LinearGradient(colors: [Color.blue, Color.blue.opacity(0.8)], startPoint: .leading, endPoint: .trailing)))
                                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                            .disabled(viewModel.isLoading || fromLocationSearchCompleter.searchQuery.isEmpty || toLocationSearchCompleter.searchQuery.isEmpty)
                            .opacity((viewModel.isLoading || fromLocationSearchCompleter.searchQuery.isEmpty || toLocationSearchCompleter.searchQuery.isEmpty) ? 0.6 : 1.0)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white).shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 4))
                        .padding(.horizontal, 20)
                        
                        // Recent Activity card
                        VStack(spacing: 16) {
                            Text("Recent Activity").font(.headline).frame(maxWidth: .infinity, alignment: .leading)
                            HStack(spacing: 16) {
                                StatCard(icon: "car.fill", title: "Rides", value: "0", color: .blue)
                                StatCard(icon: "star.fill", title: "Rating", value: "5.0", color: .orange)
                                StatCard(icon: "indianrupeesign.circle.fill", title: "Saved", value: "₹0", color: .green)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40) // space for keyboard/suggestions
                    } // VStack
                } // ScrollView
                .frame(width: fullGeo.size.width, height: fullGeo.size.height)
            } // GeometryReader (content)
            .coordinateSpace(name: "root")
            .background(Color(UIColor.systemGroupedBackground))
            .navigationDestination(isPresented: $showRideTrackingView) {
                if let ride = foundRide {
                    PassengerTrackingView(ride: ride, currentUser: currentUser)
                } else {
                    Text("Invalid ride data")
                }
            }
            .simultaneousGesture(TapGesture().onEnded { dismissSuggestions() })
            .alert("No Rides Found", isPresented: $showNoRideAlert) {
                Button("OK", role: .cancel) { }
            } message: { Text("No rides were found for your selected route and date.") }
            
            // Suggestion overlay for FROM - only shown when active and we have anchor
            Group {
                if activeSearchField == .from && !fromLocationSearchCompleter.searchresult.isEmpty, let anchor = fromAnchor {
                    // resolve and draw via GeometryReader
                    GeometryReader { proxy in
                        let rect = proxy[anchor]
                        suggestionCard(for: .from, completions: fromLocationSearchCompleter.searchresult, anchorRect: rect)
                            // center horizontally across the screen so it's wide
                            .position(x: UIScreen.main.bounds.width / 2,
                                      y: computeCardY(for: rect, proxy: proxy, completions: fromLocationSearchCompleter.searchresult))
                    }
                    .coordinateSpace(name: "root")
                } else {
                    EmptyView()
                }
            }
            .animation(.easeInOut, value: fromLocationSearchCompleter.searchresult)
            
            // Suggestion overlay for TO
            Group {
                if activeSearchField == .to && !toLocationSearchCompleter.searchresult.isEmpty, let anchor = toAnchor {
                    GeometryReader { proxy in
                        let rect = proxy[anchor]
                        suggestionCard(for: .to, completions: toLocationSearchCompleter.searchresult, anchorRect: rect)
                            .position(x: UIScreen.main.bounds.width / 2,
                                      y: computeCardY(for: rect, proxy: proxy, completions: toLocationSearchCompleter.searchresult))
                    }
                    .coordinateSpace(name: "root")
                } else {
                    EmptyView()
                }
            }
            .animation(.easeInOut, value: toLocationSearchCompleter.searchresult)
        } // ZStack
        // resolve anchors into state to use them
        .onPreferenceChange(FromFieldAnchorKey.self) { self.fromAnchor = $0 }
        .onPreferenceChange(ToFieldAnchorKey.self) { self.toAnchor = $0 }
        .onAppear {
            fromAddress = locationManager.currentAddress
            fromLocationSearchCompleter.searchQuery = locationManager.currentAddress
        }
    } // body
    
    // MARK: - Suggestion card builder (updated to be wider)
    private func suggestionCard(for field: SearchField, completions: [MKLocalSearchCompletion], anchorRect: CGRect) -> some View {
        let rowHeight: CGFloat = 52
        let count = min(completions.prefix(5).count, 5)
        let totalHeight = CGFloat(count) * rowHeight
        let sidePadding: CGFloat = 20

        // Use a wider card: full available screen width minus side padding
        let screen = UIScreen.main.bounds
        let cardWidth = screen.width - (sidePadding * 2)

        return VStack(spacing: 0) {
            ForEach(Array(completions.prefix(5).enumerated()), id: \.offset) { index, result in
                Button {
                    if field == .from { selectFromLocation(result) }
                    else { selectToLocation(result) }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: field == .from ? "mappin.circle.fill" : "flag.fill")
                            .foregroundColor(field == .from ? .red : .blue)
                            .font(.system(size: 18))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.title).font(.system(size: 15, weight: .medium)).foregroundColor(.primary)
                            Text(result.subtitle).font(.system(size: 13)).foregroundColor(.secondary).lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Image(systemName: "chevron.right").foregroundColor(.gray.opacity(0.5)).font(.system(size: 12))
                    }
                    .padding(.horizontal, 16)
                    .frame(height: rowHeight)
                    .background(Color.white)
                }
                .buttonStyle(PlainButtonStyle())
                
                if index != count - 1 { Divider().padding(.leading, 46) }
            }
        }
        .frame(width: cardWidth, height: totalHeight)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 6)
        .zIndex(1000)
    }
    
    // compute card center y (will put above if not enough room below)
    // small verticalOffset pushes the card a little lower when shown below the field
    private func computeCardY(for rect: CGRect, proxy: GeometryProxy, completions: [MKLocalSearchCompletion]) -> CGFloat {
        let screen = UIScreen.main.bounds
        let rowHeight: CGFloat = 52
        let count = min(completions.prefix(5).count, 5)
        let suggestedHeight = CGFloat(count) * rowHeight
        let safeAreaBottom = proxy.safeAreaInsets.bottom
        let availableBelow = screen.height - rect.maxY - keyboard.keyboardHeight - safeAreaBottom

        // tweak this value to move the suggestions more/less
        let verticalOffset: CGFloat = 9

        let placeAbove = availableBelow < (suggestedHeight + 12) && (rect.minY > (suggestedHeight + 12))
        if placeAbove {
            // move slightly further up when placing above
            return rect.minY - (suggestedHeight / 2) - 6 - verticalOffset
        } else {
            // move slightly down when placing below
            return rect.maxY + (suggestedHeight / 2) + 6 + verticalOffset
        }
    }

    // MARK: - Actions (outside body)
    private func dismissSuggestions() {
        activeSearchField = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func performSearch() {
        let searchFrom = fromLocationSearchCompleter.searchQuery.isEmpty ? locationManager.currentAddress : fromLocationSearchCompleter.searchQuery
        let searchTo = toLocationSearchCompleter.searchQuery
        viewModel.searchRides(from: searchFrom, to: searchTo, date: searchAnyDate ? Date.distantPast : selectedDateTime, currentUserGender: currentUser.gender) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let ride):
                    fromCoordinate = CLLocationCoordinate2D(latitude: ride.fromLat, longitude: ride.fromLong)
                    toCoordinate = CLLocationCoordinate2D(latitude: ride.toLat, longitude: ride.toLong)
                    foundRide = ride
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { showRideTrackingView = true }
                case .noResults:
                    showNoRideAlert = true
                case .failure(_):
                    showNoRideAlert = true
                }
            }
        }
    }
    
    private func selectFromLocation(_ completion: MKLocalSearchCompletion) {
        fromLocationSearchCompleter.getCoordinate(for: completion) { coordinate, address in
            DispatchQueue.main.async {
                if let coordinate = coordinate, let address = address {
                    fromAddress = address
                    fromCoordinate = coordinate
                    fromLocationSearchCompleter.searchQuery = address
                    fromLocationSearchCompleter.searchresult.removeAll()
                    dismissSuggestions()
                }
            }
        }
    }
    
    private func selectToLocation(_ completion: MKLocalSearchCompletion) {
        toLocationSearchCompleter.getCoordinate(for: completion) { coordinate, address in
            DispatchQueue.main.async {
                if let coordinate = coordinate, let address = address {
                    toAddress = address
                    toCoordinate = coordinate
                    toLocationSearchCompleter.searchQuery = address
                    toLocationSearchCompleter.searchresult.removeAll()
                    dismissSuggestions()
                }
            }
        }
    }
}

// Simple statcard view (unchanged)
struct StatCard: View {
    let icon: String; let title: String; let value: String; let color: Color
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 24)).foregroundColor(color)
            Text(value).font(.system(size: 18, weight: .bold)).foregroundColor(.primary)
            Text(title).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity).padding().background(color.opacity(0.1)).cornerRadius(12)
    }
}
#Preview {
    StatCard(icon: "person.2", title: "Followers", value: "120k", color: .blue)
}
