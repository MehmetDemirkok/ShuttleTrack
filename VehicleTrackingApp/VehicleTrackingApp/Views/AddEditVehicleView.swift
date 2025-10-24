import SwiftUI

struct AddEditVehicleView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: VehicleViewModel
    @StateObject private var appViewModel: AppViewModel
    
    @State private var plateNumber = ""
    @State private var model = ""
    @State private var brand = ""
    @State private var year = Calendar.current.component(.year, from: Date())
    @State private var capacity = 4
    @State private var color = ""
    @State private var isActive = true
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    let vehicle: Vehicle?
    let isEditing: Bool
    
    init(vehicle: Vehicle? = nil, viewModel: VehicleViewModel, appViewModel: AppViewModel) {
        self.vehicle = vehicle
        self.isEditing = vehicle != nil
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._appViewModel = StateObject(wrappedValue: appViewModel)
        
        if let vehicle = vehicle {
            _plateNumber = State(initialValue: vehicle.plateNumber)
            _model = State(initialValue: vehicle.model)
            _brand = State(initialValue: vehicle.brand)
            _year = State(initialValue: vehicle.year)
            _capacity = State(initialValue: vehicle.capacity)
            _color = State(initialValue: vehicle.color)
            _isActive = State(initialValue: vehicle.isActive)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Araç Bilgileri")) {
                    TextField("Plaka", text: $plateNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Marka", text: $brand)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Model", text: $model)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Stepper("Yıl: \(year)", value: $year, in: 1990...Calendar.current.component(.year, from: Date()))
                    
                    Stepper("Kapasite: \(capacity)", value: $capacity, in: 1...50)
                    
                    TextField("Renk", text: $color)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section(header: Text("Durum")) {
                    Toggle("Aktif", isOn: $isActive)
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(isEditing ? "Araç Düzenle" : "Yeni Araç")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("İptal") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Kaydet") {
                    saveVehicle()
                }
                .disabled(isLoading || plateNumber.isEmpty || brand.isEmpty || model.isEmpty)
            )
        }
    }
    
    private func saveVehicle() {
        isLoading = true
        errorMessage = ""
        
        guard let companyId = appViewModel.currentCompany?.id else {
            errorMessage = "Şirket bilgisi bulunamadı"
            isLoading = false
            return
        }
        
        let newVehicle = Vehicle(
            id: vehicle?.id ?? UUID().uuidString,
            plateNumber: plateNumber,
            model: model,
            brand: brand,
            year: year,
            capacity: capacity,
            color: color,
            isActive: isActive,
            companyId: companyId
        )
        
        if isEditing {
            viewModel.updateVehicle(newVehicle)
        } else {
            viewModel.addVehicle(newVehicle)
        }
        
        // Simulate save completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            if viewModel.errorMessage.isEmpty {
                presentationMode.wrappedValue.dismiss()
            } else {
                errorMessage = viewModel.errorMessage
            }
        }
    }
}

struct AddEditVehicleView_Previews: PreviewProvider {
    static var previews: some View {
        AddEditVehicleView(
            viewModel: VehicleViewModel(),
            appViewModel: AppViewModel()
        )
    }
}
