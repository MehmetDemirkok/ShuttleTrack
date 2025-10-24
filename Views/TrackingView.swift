import SwiftUI
import MapKit

struct TrackingView: View {
    @StateObject private var vehicleViewModel = VehicleViewModel()
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var locationService = LocationService()
    @State private var selectedVehicle: Vehicle?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784), // İstanbul
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    var body: some View {
        NavigationView {
            VStack {
                // Araç Listesi
                if !vehicleViewModel.vehicles.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(vehicleViewModel.vehicles) { vehicle in
                                VehicleCard(
                                    vehicle: vehicle,
                                    isSelected: selectedVehicle?.id == vehicle.id
                                ) {
                                    selectedVehicle = vehicle
                                    if let location = vehicle.currentLocation {
                                        region = MKCoordinateRegion(
                                            center: location.coordinate,
                                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 120)
                }
                
                // Harita
                Map(coordinateRegion: $region, annotationItems: mapAnnotations) { annotation in
                    MapAnnotation(coordinate: annotation.coordinate) {
                        VehicleAnnotation(vehicle: annotation.vehicle)
                    }
                }
                .onAppear {
                    locationService.requestLocationPermission()
                    loadVehicles()
                }
            }
            .navigationTitle("Araç Takibi")
            .navigationBarItems(
                trailing: Button("Konumumu Göster") {
                    if let location = locationService.currentLocation {
                        region = MKCoordinateRegion(
                            center: location.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                    }
                }
            )
        }
    }
    
    private var mapAnnotations: [VehicleAnnotation] {
        vehicleViewModel.vehicles.compactMap { vehicle in
            guard let location = vehicle.currentLocation else { return nil }
            return VehicleAnnotation(vehicle: vehicle, coordinate: location.coordinate)
        }
    }
    
    private func loadVehicles() {
        guard let companyId = appViewModel.currentCompany?.id else { return }
        Task {
            await vehicleViewModel.fetchVehicles(for: companyId)
        }
    }
}

struct VehicleCard: View {
    let vehicle: Vehicle
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "car.fill")
                    .foregroundColor(isSelected ? .white : .blue)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(vehicle.plateNumber)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(vehicle.vehicleType.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
            }
            
            if let location = vehicle.currentLocation {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        
                        Text("Aktif")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    Text(location.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
            } else {
                HStack {
                    Image(systemName: "location.slash")
                        .foregroundColor(.red)
                        .font(.caption)
                    
                    Text("Konum Yok")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .frame(width: 150, height: 100)
        .background(isSelected ? Color.blue : Color(.systemGray6))
        .cornerRadius(10)
        .onTapGesture {
            onTap()
        }
    }
}

struct VehicleAnnotation: Identifiable {
    let id = UUID()
    let vehicle: Vehicle
    let coordinate: CLLocationCoordinate2D
}

struct VehicleAnnotationView: View {
    let vehicle: Vehicle
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "car.fill")
                .foregroundColor(.white)
                .font(.title2)
                .padding(8)
                .background(Color.blue)
                .clipShape(Circle())
            
            Text(vehicle.plateNumber)
                .font(.caption)
                .fontWeight(.bold)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.white)
                .cornerRadius(4)
                .shadow(radius: 2)
        }
    }
}

struct TrackingView_Previews: PreviewProvider {
    static var previews: some View {
        TrackingView()
    }
}
