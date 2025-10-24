import SwiftUI

struct VehicleManagementView: View {
    @StateObject private var viewModel = VehicleViewModel()
    @StateObject private var appViewModel = AppViewModel()
    @State private var showingAddVehicle = false
    @State private var selectedVehicle: Vehicle?
    @State private var showingDeleteAlert = false
    @State private var vehicleToDelete: Vehicle?
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Araçlar yükleniyor...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.vehicles.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("Henüz araç eklenmemiş")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text("İlk aracınızı eklemek için + butonuna tıklayın")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.vehicles) { vehicle in
                            VehicleRowView(
                                vehicle: vehicle,
                                onEdit: { selectedVehicle = vehicle },
                                onDelete: { 
                                    vehicleToDelete = vehicle
                                    showingDeleteAlert = true
                                },
                                onToggleStatus: {
                                    viewModel.toggleVehicleStatus(vehicle)
                                }
                            )
                        }
                    }
                }
                
                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }
            }
            .navigationTitle("Araçlar")
            .navigationBarItems(
                trailing: Button(action: {
                    showingAddVehicle = true
                }) {
                    Image(systemName: "plus")
                }
            )
            .onAppear {
                loadVehicles()
            }
            .sheet(isPresented: $showingAddVehicle) {
                AddEditVehicleView(viewModel: viewModel, appViewModel: appViewModel)
            }
            .sheet(item: $selectedVehicle) { vehicle in
                AddEditVehicleView(vehicle: vehicle, viewModel: viewModel, appViewModel: appViewModel)
            }
            .alert("Aracı Sil", isPresented: $showingDeleteAlert) {
                Button("İptal", role: .cancel) { }
                Button("Sil", role: .destructive) {
                    if let vehicle = vehicleToDelete {
                        viewModel.deleteVehicle(vehicle)
                    }
                }
            } message: {
                Text("Bu aracı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.")
            }
        }
    }
    
    private func loadVehicles() {
        guard let companyId = appViewModel.currentCompany?.id else { return }
        viewModel.fetchVehicles(for: companyId)
    }
}

struct VehicleRowView: View {
    let vehicle: Vehicle
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onToggleStatus: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(vehicle.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(vehicle.year) • \(vehicle.capacity) kişi • \(vehicle.color)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        Circle()
                            .fill(Color(vehicle.statusColor))
                            .frame(width: 8, height: 8)
                        
                        Text(vehicle.statusText)
                            .font(.caption)
                            .foregroundColor(Color(vehicle.statusColor))
                    }
                    
                    if let location = vehicle.currentLocation {
                        Text("📍 Konum mevcut")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // Sigorta ve Muayene Bilgileri
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sigorta")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(vehicle.insuranceStatusColor))
                                .frame(width: 6, height: 6)
                            
                            Text(vehicle.insuranceStatus)
                                .font(.caption)
                                .foregroundColor(Color(vehicle.insuranceStatusColor))
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Muayene")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(vehicle.inspectionStatusColor))
                                .frame(width: 6, height: 6)
                            
                            Text(vehicle.inspectionStatus)
                                .font(.caption)
                                .foregroundColor(Color(vehicle.inspectionStatusColor))
                        }
                    }
                }
                
                // Uyarı mesajları
                if vehicle.daysUntilInsuranceExpiry < 0 || vehicle.daysUntilInspectionExpiry < 0 {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.caption2)
                        
                        Text("Süresi dolmuş belgeler var!")
                            .font(.caption2)
                            .foregroundColor(.red)
                            .fontWeight(.medium)
                    }
                    .padding(.top, 2)
                } else if vehicle.daysUntilInsuranceExpiry <= 30 || vehicle.daysUntilInspectionExpiry <= 30 {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.orange)
                            .font(.caption2)
                        
                        Text("Yakında süresi dolacak belgeler var!")
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .fontWeight(.medium)
                    }
                    .padding(.top, 2)
                }
            }
            .padding(.top, 4)
            
            HStack {
                Button("Düzenle") {
                    onEdit()
                }
                .font(.caption)
                .foregroundColor(.blue)
                
                Spacer()
                
                Button(vehicle.isActive ? "Pasifleştir" : "Aktifleştir") {
                    onToggleStatus()
                }
                .font(.caption)
                .foregroundColor(vehicle.isActive ? .orange : .green)
                
                Spacer()
                
                Button("Sil") {
                    onDelete()
                }
                .font(.caption)
                .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

struct VehicleManagementView_Previews: PreviewProvider {
    static var previews: some View {
        VehicleManagementView()
    }
}
