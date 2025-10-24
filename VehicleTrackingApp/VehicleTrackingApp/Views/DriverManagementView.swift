import SwiftUI

struct DriverManagementView: View {
    @StateObject private var viewModel = DriverViewModel()
    @StateObject private var appViewModel = AppViewModel()
    @State private var showingAddDriver = false
    @State private var selectedDriver: Driver?
    @State private var showingDeleteAlert = false
    @State private var driverToDelete: Driver?
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Şoförler yükleniyor...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.drivers.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("Henüz şoför eklenmemiş")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text("İlk şoförünüzü eklemek için + butonuna tıklayın")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.drivers) { driver in
                            DriverRowView(
                                driver: driver,
                                onEdit: { selectedDriver = driver },
                                onDelete: { 
                                    driverToDelete = driver
                                    showingDeleteAlert = true
                                },
                                onToggleStatus: {
                                    viewModel.toggleDriverStatus(driver)
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
            .navigationTitle("Şoförler")
            .navigationBarItems(
                trailing: Button(action: {
                    showingAddDriver = true
                }) {
                    Image(systemName: "plus")
                }
            )
            .onAppear {
                loadDrivers()
            }
            .sheet(isPresented: $showingAddDriver) {
                AddEditDriverView(viewModel: viewModel, appViewModel: appViewModel)
            }
            .sheet(item: $selectedDriver) { driver in
                AddEditDriverView(driver: driver, viewModel: viewModel, appViewModel: appViewModel)
            }
            .alert("Şoförü Sil", isPresented: $showingDeleteAlert) {
                Button("İptal", role: .cancel) { }
                Button("Sil", role: .destructive) {
                    if let driver = driverToDelete {
                        viewModel.deleteDriver(driver)
                    }
                }
            } message: {
                Text("Bu şoförü silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.")
            }
        }
    }
    
    private func loadDrivers() {
        guard let companyId = appViewModel.currentCompany?.id else { return }
        viewModel.fetchDrivers(for: companyId)
    }
}

struct DriverRowView: View {
    let driver: Driver
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onToggleStatus: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(driver.fullName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(driver.phoneNumber)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        Circle()
                            .fill(Color(driver.statusColor))
                            .frame(width: 8, height: 8)
                        
                        Text(driver.statusText)
                            .font(.caption)
                            .foregroundColor(Color(driver.statusColor))
                    }
                    
                    
                    if driver.assignedVehicleId != nil {
                        Text("🚗 Araç atanmış")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            HStack {
                Button("Düzenle") {
                    print("🔧 DriverRowView: Düzenle butonuna tıklandı - Driver: \(driver.fullName)")
                    onEdit()
                }
                .font(.caption)
                .foregroundColor(.blue)
                
                Spacer()
                
                Button(driver.isActive ? "Pasifleştir" : "Aktifleştir") {
                    onToggleStatus()
                }
                .font(.caption)
                .foregroundColor(driver.isActive ? .orange : .green)
                
                Spacer()
                
                Button("Sil") {
                    print("🗑️ DriverRowView: Sil butonuna tıklandı - Driver: \(driver.fullName)")
                    onDelete()
                }
                .font(.caption)
                .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

struct DriverManagementView_Previews: PreviewProvider {
    static var previews: some View {
        DriverManagementView()
    }
}
