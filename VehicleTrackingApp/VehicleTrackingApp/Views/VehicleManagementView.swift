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
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        
                        Text("Araçlar yükleniyor...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Bu işlem birkaç saniye sürebilir")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
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
                                onEdit: { 
                                    print("🔧 VehicleManagementView: Düzenle butonuna tıklandı - Vehicle: \(vehicle.displayName)")
                                    print("🔧 selectedVehicle öncesi: \(selectedVehicle?.displayName ?? "nil")")
                                    selectedVehicle = vehicle
                                    print("🔧 selectedVehicle sonrası: \(selectedVehicle?.displayName ?? "nil")")
                                },
                                onDelete: { 
                                    vehicleToDelete = vehicle
                                    showingDeleteAlert = true
                                },
                                onToggleStatus: {
                                    viewModel.toggleVehicleStatus(vehicle)
                                }
                            )
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(PlainListStyle())
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
            .sheet(isPresented: Binding<Bool>(
                get: { 
                    let shouldShow = showingAddVehicle || selectedVehicle != nil
                    print("🔧 Vehicle Sheet binding get: showingAddVehicle=\(showingAddVehicle), selectedVehicle=\(selectedVehicle?.displayName ?? "nil"), shouldShow=\(shouldShow)")
                    return shouldShow
                },
                set: { 
                    print("🔧 Vehicle Sheet binding set: \($0)")
                    if !$0 {
                        showingAddVehicle = false
                        selectedVehicle = nil
                    }
                }
            )) {
                if let vehicle = selectedVehicle {
                    AddEditVehicleView(vehicle: vehicle, viewModel: viewModel, appViewModel: appViewModel)
                } else {
                    AddEditVehicleView(viewModel: viewModel, appViewModel: appViewModel)
                }
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
    
    // Araç ikonu
    private var vehicleIcon: String {
        switch vehicle.vehicleType {
        case .sedan:
            return "car.fill"
        case .suv:
            return "car.fill"
        case .minivan:
            return "car.fill"
        case .bus:
            return "bus.fill"
        case .van:
            return "car.fill"
        case .pickup:
            return "car.fill"
        }
    }
    
    // Araç ikon rengi
    private var vehicleIconColor: Color {
        switch vehicle.vehicleType {
        case .sedan:
            return .blue
        case .suv:
            return .green
        case .minivan:
            return .orange
        case .bus:
            return .purple
        case .van:
            return .red
        case .pickup:
            return .brown
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Ana bilgi kartı
            HStack(alignment: .top, spacing: 12) {
                // Araç ikonu
                VStack {
                    Image(systemName: vehicleIcon)
                        .font(.title2)
                        .foregroundColor(vehicleIconColor)
                        .frame(width: 40, height: 40)
                        .background(vehicleIconColor.opacity(0.1))
                        .cornerRadius(8)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    // Araç adı ve plaka
                    HStack {
                        Text(vehicle.displayName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Durum badge'i
                        HStack(spacing: 4) {
                            Circle()
                                .fill(vehicle.isActive ? Color.green : Color.red)
                                .frame(width: 6, height: 6)
                            
                            Text(vehicle.statusText)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(vehicle.isActive ? .green : .red)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background((vehicle.isActive ? Color.green : Color.red).opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // Araç detayları
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Yıl")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(String(vehicle.year))")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Kapasite")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(vehicle.capacity) kişi")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Renk")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(vehicle.color)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
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
            
            // Modern buton tasarımı
            HStack(spacing: 12) {
                Button(action: {
                    print("🔧 VehicleRowView: Düzenle butonuna tıklandı - Vehicle: \(vehicle.displayName)")
                    onEdit()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                            .font(.caption)
                        Text("Düzenle")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                
                Spacer()
                
                Button(action: onToggleStatus) {
                    HStack(spacing: 4) {
                        Image(systemName: vehicle.isActive ? "pause.circle" : "play.circle")
                            .font(.caption)
                        Text(vehicle.isActive ? "Pasifleştir" : "Aktifleştir")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(vehicle.isActive ? Color.orange : Color.green)
                    .cornerRadius(8)
                }
                
                Spacer()
                
                Button(action: {
                    print("🗑️ VehicleRowView: Sil butonuna tıklandı - Vehicle: \(vehicle.displayName)")
                    onDelete()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.caption)
                        Text("Sil")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.red)
                    .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
}

struct VehicleManagementView_Previews: PreviewProvider {
    static var previews: some View {
        VehicleManagementView()
    }
}
