import SwiftUI
import MapKit

struct RideTrackingViewSimulation: View {
    let fromCoordinate: CLLocationCoordinate2D
    let toCoordinate: CLLocationCoordinate2D
    
    @State private var rideStatus: String = "Searching for drivers..."
    @State private var mapPosition: MapCameraPosition
    @State private var route:MKRoute?
    @State private var driverProgress:Double = 0.0
    
    init(fromCoordinate: CLLocationCoordinate2D, toCoordinate: CLLocationCoordinate2D) {
        self.fromCoordinate = fromCoordinate
        self.toCoordinate = toCoordinate
        _mapPosition = State(initialValue: .region(
            MKCoordinateRegion(
                center: fromCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        ))
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $mapPosition) {
                
                if let route {
                    MapPolyline(route.polyline)
                        .stroke(.blue,lineWidth: 5)
                }
                Marker("Pickup",systemImage: "mappin.circle.fill", coordinate: fromCoordinate)
                    .tint(.red)
                
                Marker("Destination",systemImage: "flag.fill",coordinate: toCoordinate)
                    .tint(.blue)
                
                if let route {
                    let driverCoord  = coordinate(at: driverProgress, on: route)
                    Marker("driver",systemImage: "car.fill",coordinate: driverCoord)
                    
                }
            }
            .ignoresSafeArea()
            .task {
                await getRoute()
                await simulatedRideProgress()
                
            }
            
            VStack(spacing: 10) {
                Text(rideStatus)
                    .font(.headline)
                if rideStatus == "Ride is on the way" {
                    Text("Estimated time is 7 mins")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color.white.opacity(0.95))
            .cornerRadius(20)
            .shadow(radius: 5)
            .padding()
        }
    }
    private func getRoute() async {
        let request = MKDirections.Request()
        // it create a new request object and we use it with the sourec destination and transport type
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: fromCoordinate))
        // source here  is the starting poiunt for the location
        
        // mk placemark represt specfic location which wrap the address
        // mk apItem wrap the placemark so that mapKIT can use it in routing
        
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: toCoordinate))
        
        // destination location
        
        request.transportType = .automobile
        
        do {
            let response  = try await MKDirections(request: request).calculate()
            if let first = response.routes.first {   // response of the routes usually pick the first route as it the best one
                
                route  =  first
                mapPosition = .region(MKCoordinateRegion(first.polyline.boundingMapRect))
                
            }
            
        }
        catch {
            print("error.localisedDescription")
        }
        
        
        
    }
    private func simulatedRideProgress() {
        Task {
            try?await Task.sleep(for: .seconds(2))
            await MainActor.run{ rideStatus = "Driver Found"}
            
            try?await Task.sleep(for: .seconds(3))
            await MainActor.run {
                rideStatus = "Ride on the way"
            }
            
            for i in 0...100 {
                try? await Task.sleep(for: .milliseconds(100))
                await MainActor.run {
                    driverProgress = Double (i)/100
                }
            }
            
            await MainActor.run {
                rideStatus = "Arrived at destination"
            }
            
        }
        
        
    }
    private func coordinate(at progress:Double,on route:MKRoute)->CLLocationCoordinate2D {
        
        let totalDistance = route.distance
        
        let target  = totalDistance * progress
        var travelled: CLLocationDistance = 0
        
        let points  = route.polyline.points()
        for i in 0..<route.polyline.pointCount - 1 {
            let start = points[i]
            let end  = points[i+1]
            let seg = start.distance(to: end)
            if travelled+seg > target {
                let ratio  = (target-travelled)/seg
                let lat  = start.coordinate.latitude + (end.coordinate.latitude - start.coordinate.latitude) * ratio
                
                let lon = start.coordinate.longitude + (end.coordinate.longitude - start.coordinate.longitude) * ratio
                
                return CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }
            travelled += seg
            
        }
        return toCoordinate
        
    }
}
#Preview {
    RideTrackingViewSimulation(
        fromCoordinate: CLLocationCoordinate2D(latitude: 12.9716, longitude: 77.5946),
        toCoordinate: CLLocationCoordinate2D(latitude: 12.9352, longitude: 77.6245)
    )
}

