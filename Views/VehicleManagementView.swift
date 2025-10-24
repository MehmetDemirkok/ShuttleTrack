import SwiftUI

struct VehicleManagementView: View {
    @StateObject private var vehicleViewModel = VehicleViewModel()
    @StateObject private var appViewModel = AppViewModel()
    @State private var showingAddVehicle = false
    
    var body: some View {
        NavigationView {
            VStack {
                if vehicleViewModel.isLoading {
                    ProgressView("Araçlar yükleniyor...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vehicleViewModel.vehicles.isEmpty {
                    EmptyStateView(
                        icon: "car.fill",
                        title: "Henüz Araç Yok",
                        message: "İlk aracınızı ekleyerek başlayın"
                    )
                } else {
                    List {
                        ForEach(vehicleViewModel.vehicles) { vehicle in
                            VehicleRow(vehicle: vehicle)
                        }
                        .onDelete(perform: deleteVehicles)
                    }
                }
            }
            .navigationTitle("Araç Yönetimi")
            .navigationBarItems(
                trailing: Button(action: {
                    showingAddVehicle = true
                }) {
                    Image(systemName: "plus")
                }
            )
            .sheet(isPresented: $showingAddVehicle) {
                AddVehicleView()
            }
            .onAppear {
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
    
    private func deleteVehicles(offsets: IndexSet) {
        for index in offsets {
            let vehicle = vehicleViewModel.vehicles[index]
            Task {
                await vehicleViewModel.deleteVehicle(vehicle)
            }
        }
    }
}

struct VehicleRow: View {
    let vehicle: Vehicle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(vehicle.plateNumber)
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Text("\(vehicle.make) \(vehicle.model) (\(vehicle.year))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(vehicle.vehicleType.rawValue.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                    
                    Text("\(vehicle.capacity) kişi")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let location = vehicle.currentLocation {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    
                    Text("Son güncelleme: \(location.timestamp, style: .time)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                HStack {
                    Image(systemName: "location.slash")
                        .foregroundColor(.red)
                        .font(.caption)
                    
                    Text("Konum bilgisi yok")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct AddVehicleView: View {
    @StateObject private var vehicleViewModel = VehicleViewModel()
    @StateObject private var appViewModel = AppViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    @State private var plateNumber = ""
    @State private var make = ""
    @State private var model = ""
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var capacity = 4
    @State private var selectedVehicleType = Vehicle.VehicleType.car
    
    var body: some View {
        NavigationView {
            Form {
                Section("Araç Bilgileri") {
                    TextField("Plaka", text: $plateNumber)
                    TextField("Marka", text: $make)
                    TextField("Model", text: $model)
                    
                    Picker("Yıl", selection: $year) {
                        ForEach(2000...Calendar.current.component(.year, from: Date()), id: \.self) { year in
                            Text("\(year)").tag(year)
                        }
                    }
                    
                    Stepper("Kapasite: \(capacity)", value: $capacity, in: 1...50)
                    
                    Picker("Araç Tipi", selection: $selectedVehicleType) {
                        ForEach(Vehicle.VehicleType.allCases, id: \.self) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
                    }
                }
            }
            .navigationTitle("Yeni Araç")
            .navigationBarItems(
                leading: Button("İptal") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Kaydet") {
                    Task {
                        await addVehicle()
                    }
                }
                .disabled(!isFormValid)
            )
        }
    }
    
    private var isFormValid: Bool {
        !plateNumber.isEmpty &&
        !make.isEmpty &&
        !model.isEmpty
    }
    
    private func addVehicle() async {
        guard let companyId = appViewModel.currentCompany?.id else { return }
        
        let vehicle = Vehicle(
            companyId: companyId,
            plateNumber: plateNumber,
            make: make,
            model: model,
            year: year,
            capacity: capacity,
            vehicleType: selectedVehicleType
        )
        
        await vehicleViewModel.addVehicle(vehicle)
        
        if vehicleViewModel.errorMessage == nil {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct VehicleManagementView_Previews: PreviewProvider {
    static var previews: some View {
        VehicleManagementView()
    }
}
