import SwiftUI

struct TrackingView: View {
    @StateObject private var vehicleViewModel = VehicleViewModel()
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var locationService = LocationService()
    @State private var selectedVehicle: Vehicle?
    
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
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 120)
                }
                
                // Basit Takip Görünümü
                VStack(spacing: 20) {
                    if let vehicle = selectedVehicle {
                        VStack(spacing: 15) {
                            Text("Seçili Araç: \(vehicle.plateNumber)")
                                .font(.headline)
                                .foregroundColor(.blue)
                            
                            if let location = vehicle.currentLocation {
                                VStack(spacing: 8) {
                                    Text("Son Konum")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Text("Enlem: \(String(format: "%.6f", location.latitude))")
                                        .font(.caption)
                                    
                                    Text("Boylam: \(String(format: "%.6f", location.longitude))")
                                        .font(.caption)
                                    
                                    Text("Son Güncelleme: \(location.timestamp, style: .time)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            } else {
                                Text("Konum bilgisi bulunamadı")
                                    .foregroundColor(.red)
                                    .padding()
                            }
                        }
                    } else {
                        Text("Takip etmek için bir araç seçin")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Araç Takibi")
            .onAppear {
                locationService.requestLocationPermission()
                loadVehicles()
            }
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


struct TrackingView_Previews: PreviewProvider {
    static var previews: some View {
        TrackingView()
    }
}
