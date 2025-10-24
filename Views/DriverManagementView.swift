import SwiftUI

struct DriverManagementView: View {
    @StateObject private var driverViewModel = DriverViewModel()
    @StateObject private var appViewModel = AppViewModel()
    @State private var showingAddDriver = false
    
    var body: some View {
        NavigationView {
            VStack {
                if driverViewModel.isLoading {
                    ProgressView("Şoförler yükleniyor...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if driverViewModel.drivers.isEmpty {
                    EmptyStateView(
                        icon: "person.fill",
                        title: "Henüz Şoför Yok",
                        message: "İlk şoförünüzü ekleyerek başlayın"
                    )
                } else {
                    List {
                        ForEach(driverViewModel.drivers) { driver in
                            DriverRow(driver: driver)
                        }
                    }
                }
            }
            .navigationTitle("Şoför Yönetimi")
            .navigationBarItems(
                trailing: Button(action: {
                    showingAddDriver = true
                }) {
                    Image(systemName: "plus")
                }
            )
            .sheet(isPresented: $showingAddDriver) {
                AddDriverView()
            }
            .onAppear {
                loadDrivers()
            }
        }
    }
    
    private func loadDrivers() {
        guard let companyId = appViewModel.currentCompany?.id else { return }
        Task {
            await driverViewModel.fetchDrivers(for: companyId)
        }
    }
}

struct DriverRow: View {
    let driver: Driver
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(driver.fullName)
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Text(driver.phone)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        Circle()
                            .fill(driver.isAvailable ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        
                        Text(driver.isAvailable ? "Müsait" : "Meşgul")
                            .font(.caption)
                            .foregroundColor(driver.isAvailable ? .green : .red)
                    }
                    
                    if driver.rating > 0 {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            
                            Text(String(format: "%.1f", driver.rating))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            HStack {
                Text("Ehliyet: \(driver.licenseNumber)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Son güncelleme: \(driver.updatedAt, style: .time)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let vehicleId = driver.currentVehicleId {
                HStack {
                    Image(systemName: "car.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                    
                    Text("Araç ID: \(vehicleId)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddDriverView: View {
    @StateObject private var driverViewModel = DriverViewModel()
    @StateObject private var appViewModel = AppViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var licenseNumber = ""
    @State private var licenseExpiryDate = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section("Kişisel Bilgiler") {
                    TextField("Ad", text: $firstName)
                    TextField("Soyad", text: $lastName)
                    TextField("E-posta", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Telefon", text: $phone)
                        .keyboardType(.phonePad)
                }
                
                Section("Ehliyet Bilgileri") {
                    TextField("Ehliyet Numarası", text: $licenseNumber)
                    
                    DatePicker("Ehliyet Bitiş Tarihi", selection: $licenseExpiryDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Yeni Şoför")
            .navigationBarItems(
                leading: Button("İptal") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Kaydet") {
                    Task {
                        await addDriver()
                    }
                }
                .disabled(!isFormValid)
            )
        }
    }
    
    private var isFormValid: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !email.isEmpty &&
        !phone.isEmpty &&
        !licenseNumber.isEmpty
    }
    
    private func addDriver() async {
        guard let companyId = appViewModel.currentCompany?.id else { return }
        
        let driver = Driver(
            companyId: companyId,
            firstName: firstName,
            lastName: lastName,
            email: email,
            phone: phone,
            licenseNumber: licenseNumber,
            licenseExpiryDate: licenseExpiryDate
        )
        
        await driverViewModel.addDriver(driver)
        
        if driverViewModel.errorMessage == nil {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct DriverManagementView_Previews: PreviewProvider {
    static var previews: some View {
        DriverManagementView()
    }
}
