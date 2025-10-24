import SwiftUI

struct AddEditTripView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: TripViewModel
    @StateObject private var appViewModel: AppViewModel
    
    @State private var title = ""
    @State private var description = ""
    @State private var pickupLocation = ""
    @State private var dropoffLocation = ""
    @State private var pickupTime = Date()
    @State private var dropoffTime = Date()
    @State private var passengerCount = 1
    @State private var passengerName = ""
    @State private var passengerPhone = ""
    @State private var status: TripStatus = .pending
    @State private var selectedVehicleId: String?
    @State private var selectedDriverId: String?
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    let trip: Trip?
    let isEditing: Bool
    
    init(trip: Trip? = nil, viewModel: TripViewModel, appViewModel: AppViewModel) {
        self.trip = trip
        self.isEditing = trip != nil
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._appViewModel = StateObject(wrappedValue: appViewModel)
        
        if let trip = trip {
            _title = State(initialValue: trip.title)
            _description = State(initialValue: trip.description)
            _pickupLocation = State(initialValue: trip.pickupLocation)
            _dropoffLocation = State(initialValue: trip.dropoffLocation)
            _pickupTime = State(initialValue: trip.pickupTime)
            _dropoffTime = State(initialValue: trip.dropoffTime)
            _passengerCount = State(initialValue: trip.passengerCount)
            _passengerName = State(initialValue: trip.passengerName)
            _passengerPhone = State(initialValue: trip.passengerPhone)
            _status = State(initialValue: trip.status)
            _selectedVehicleId = State(initialValue: trip.assignedVehicleId)
            _selectedDriverId = State(initialValue: trip.assignedDriverId)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("İş Bilgileri")) {
                    TextField("Başlık", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Açıklama", text: $description)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section(header: Text("Lokasyon Bilgileri")) {
                    TextField("Alış Noktası", text: $pickupLocation)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Bırakış Noktası", text: $dropoffLocation)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section(header: Text("Zaman Bilgileri")) {
                    DatePicker("Alış Zamanı", selection: $pickupTime, displayedComponents: [.date, .hourAndMinute])
                    
                    DatePicker("Bırakış Zamanı", selection: $dropoffTime, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section(header: Text("Yolcu Bilgileri")) {
                    TextField("Yolcu Adı", text: $passengerName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Yolcu Telefonu", text: $passengerPhone)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.phonePad)
                    
                    Stepper("Yolcu Sayısı: \(passengerCount)", value: $passengerCount, in: 1...50)
                }
                
                if isEditing {
                    Section(header: Text("Durum")) {
                        Picker("Durum", selection: $status) {
                            ForEach(TripStatus.allCases, id: \.self) { status in
                                Text(status.displayName).tag(status)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    Section(header: Text("Atama")) {
                        Picker("Araç", selection: $selectedVehicleId) {
                            Text("Araç Seçin").tag(nil as String?)
                            ForEach(viewModel.vehicles) { vehicle in
                                Text(vehicle.displayName).tag(vehicle.id as String?)
                            }
                        }
                        
                        Picker("Şoför", selection: $selectedDriverId) {
                            Text("Şoför Seçin").tag(nil as String?)
                            ForEach(viewModel.drivers) { driver in
                                Text(driver.fullName).tag(driver.id as String?)
                            }
                        }
                    }
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(isEditing ? "İş Düzenle" : "Yeni İş")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("İptal") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Kaydet") {
                    saveTrip()
                }
                .disabled(isLoading || title.isEmpty || pickupLocation.isEmpty || dropoffLocation.isEmpty)
            )
            .onAppear {
                loadData()
            }
        }
    }
    
    private func loadData() {
        guard let companyId = appViewModel.currentCompany?.id else { return }
        viewModel.fetchVehicles(for: companyId)
        viewModel.fetchDrivers(for: companyId)
    }
    
    private func saveTrip() {
        isLoading = true
        errorMessage = ""
        
        guard let companyId = appViewModel.currentCompany?.id else {
            errorMessage = "Şirket bilgisi bulunamadı"
            isLoading = false
            return
        }
        
        let newTrip = Trip(
            id: trip?.id ?? UUID().uuidString,
            title: title,
            description: description,
            pickupLocation: pickupLocation,
            dropoffLocation: dropoffLocation,
            pickupTime: pickupTime,
            dropoffTime: dropoffTime,
            passengerCount: passengerCount,
            passengerName: passengerName,
            passengerPhone: passengerPhone,
            status: status,
            companyId: companyId
        )
        
        if isEditing {
            var updatedTrip = newTrip
            updatedTrip.assignedVehicleId = selectedVehicleId
            updatedTrip.assignedDriverId = selectedDriverId
            viewModel.updateTrip(updatedTrip)
        } else {
            viewModel.addTrip(newTrip)
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

struct AddEditTripView_Previews: PreviewProvider {
    static var previews: some View {
        AddEditTripView(
            viewModel: TripViewModel(),
            appViewModel: AppViewModel()
        )
    }
}
