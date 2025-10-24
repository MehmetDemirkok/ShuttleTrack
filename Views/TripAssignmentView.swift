import SwiftUI

struct TripAssignmentView: View {
    @StateObject private var tripViewModel = TripViewModel()
    @StateObject private var vehicleViewModel = VehicleViewModel()
    @StateObject private var driverViewModel = DriverViewModel()
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var exportService = ExportService()
    @State private var showingAddTrip = false
    @State private var selectedStatus: Trip.TripStatus? = nil
    @State private var showingExportOptions = false
    @State private var showingShareSheet = false
    @State private var shareURL: URL?
    
    var filteredTrips: [Trip] {
        if let status = selectedStatus {
            return tripViewModel.trips.filter { $0.status == status }
        }
        return tripViewModel.trips
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Filtre Butonları
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        FilterButton(
                            title: "Tümü",
                            isSelected: selectedStatus == nil
                        ) {
                            selectedStatus = nil
                        }
                        
                        ForEach(Trip.TripStatus.allCases, id: \.self) { status in
                            FilterButton(
                                title: statusText(status),
                                isSelected: selectedStatus == status
                            ) {
                                selectedStatus = status
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 10)
                
                if tripViewModel.isLoading {
                    ProgressView("İşler yükleniyor...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredTrips.isEmpty {
                    EmptyStateView(
                        icon: "list.bullet",
                        title: selectedStatus == nil ? "Henüz İş Yok" : "Bu Durumda İş Yok",
                        message: selectedStatus == nil ? "İlk işinizi ekleyerek başlayın" : "Seçilen durumda iş bulunmuyor"
                    )
                } else {
                    List {
                        ForEach(filteredTrips) { trip in
                            TripRow(
                                trip: trip,
                                onAssign: { trip in
                                    showingAddTrip = true
                                },
                                onStart: { trip in
                                    Task {
                                        await tripViewModel.startTrip(tripId: trip.id ?? "")
                                    }
                                },
                                onComplete: { trip in
                                    Task {
                                        await tripViewModel.completeTrip(tripId: trip.id ?? "")
                                    }
                                }
                            )
                        }
                    }
                }
            }
            .navigationTitle("İş Yönetimi")
            .navigationBarItems(
                leading: Button(action: {
                    showingExportOptions = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(filteredTrips.isEmpty || exportService.isExporting),
                trailing: Button(action: {
                    showingAddTrip = true
                }) {
                    Image(systemName: "plus")
                }
            )
            .sheet(isPresented: $showingAddTrip) {
                AddTripView()
            }
            .actionSheet(isPresented: $showingExportOptions) {
                ActionSheet(
                    title: Text("Dışa Aktar"),
                    message: Text("Hangi formatta dışa aktarmak istiyorsunuz?"),
                    buttons: [
                        .default(Text("Excel (CSV)")) {
                            Task {
                                await exportToExcel()
                            }
                        },
                        .default(Text("PDF")) {
                            Task {
                                await exportToPDF()
                            }
                        },
                        .cancel()
                    ]
                )
            }
            .sheet(isPresented: $showingShareSheet, content: {
                if let url = shareURL {
                    ShareSheet(activityItems: [url])
                }
            })
            .onAppear {
                loadData()
            }
        }
    }
    
    private func loadData() {
        guard let companyId = appViewModel.currentCompany?.id else { return }
        
        Task {
            await tripViewModel.fetchTrips(for: companyId)
            await vehicleViewModel.fetchVehicles(for: companyId)
            await driverViewModel.fetchDrivers(for: companyId)
        }
    }
    
    private func statusText(_ status: Trip.TripStatus) -> String {
        switch status {
        case .scheduled: return "Planlandı"
        case .assigned: return "Atandı"
        case .inProgress: return "Devam Ediyor"
        case .completed: return "Tamamlandı"
        case .cancelled: return "İptal"
        }
    }
    
    private func exportToExcel() async {
        if let url = await exportService.exportTripsToExcel(filteredTrips) {
            shareURL = url
            showingShareSheet = true
        }
    }
    
    private func exportToPDF() async {
        if let url = await exportService.exportTripsToPDF(filteredTrips) {
            shareURL = url
            showingShareSheet = true
        }
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(15)
        }
    }
}

struct TripRow: View {
    let trip: Trip
    let onAssign: (Trip) -> Void
    let onStart: (Trip) -> Void
    let onComplete: (Trip) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Başlık
            HStack {
                Text("İş #\(trip.tripNumber)")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Spacer()
                
                StatusBadge(status: trip.status)
            }
            
            // Rota Bilgisi
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    
                    Text(trip.pickupLocation.name)
                        .font(.subheadline)
                }
                
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    
                    Text(trip.dropoffLocation.name)
                        .font(.subheadline)
                }
            }
            
            // Zaman Bilgisi
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.blue)
                    .font(.caption)
                
                Text("Kalkış: \(trip.scheduledPickupTime, style: .time)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Varış: \(trip.scheduledDropoffTime, style: .time)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Yolcu Sayısı
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
                
                Text("\(trip.passengerCount) yolcu")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Aksiyon Butonları
            if trip.status == .scheduled {
                Button("Şoför Ata") {
                    onAssign(trip)
                }
                .buttonStyle(ActionButtonStyle(color: .blue))
            } else if trip.status == .assigned {
                Button("Başlat") {
                    onStart(trip)
                }
                .buttonStyle(ActionButtonStyle(color: .green))
            } else if trip.status == .inProgress {
                Button("Tamamla") {
                    onComplete(trip)
                }
                .buttonStyle(ActionButtonStyle(color: .orange))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct ActionButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color)
            .cornerRadius(6)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct AddTripView: View {
    @StateObject private var tripViewModel = TripViewModel()
    @StateObject private var vehicleViewModel = VehicleViewModel()
    @StateObject private var driverViewModel = DriverViewModel()
    @StateObject private var appViewModel = AppViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    @State private var tripNumber = ""
    @State private var pickupLocationName = ""
    @State private var pickupAddress = ""
    @State private var pickupLatitude = ""
    @State private var pickupLongitude = ""
    @State private var dropoffLocationName = ""
    @State private var dropoffAddress = ""
    @State private var dropoffLatitude = ""
    @State private var dropoffLongitude = ""
    @State private var scheduledPickupTime = Date()
    @State private var scheduledDropoffTime = Date()
    @State private var passengerCount = 1
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("İş Bilgileri") {
                    TextField("İş Numarası", text: $tripNumber)
                    Stepper("Yolcu Sayısı: \(passengerCount)", value: $passengerCount, in: 1...50)
                    TextField("Notlar", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Kalkış Noktası") {
                    TextField("Konum Adı", text: $pickupLocationName)
                    TextField("Adres", text: $pickupAddress)
                    HStack {
                        TextField("Enlem", text: $pickupLatitude)
                            .keyboardType(.decimalPad)
                        TextField("Boylam", text: $pickupLongitude)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section("Varış Noktası") {
                    TextField("Konum Adı", text: $dropoffLocationName)
                    TextField("Adres", text: $dropoffAddress)
                    HStack {
                        TextField("Enlem", text: $dropoffLatitude)
                            .keyboardType(.decimalPad)
                        TextField("Boylam", text: $dropoffLongitude)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section("Zaman Planlaması") {
                    DatePicker("Kalkış Zamanı", selection: $scheduledPickupTime)
                    DatePicker("Varış Zamanı", selection: $scheduledDropoffTime)
                }
            }
            .navigationTitle("Yeni İş")
            .navigationBarItems(
                leading: Button("İptal") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Kaydet") {
                    Task {
                        await addTrip()
                    }
                }
                .disabled(!isFormValid)
            )
        }
    }
    
    private var isFormValid: Bool {
        !tripNumber.isEmpty &&
        !pickupLocationName.isEmpty &&
        !pickupAddress.isEmpty &&
        !dropoffLocationName.isEmpty &&
        !dropoffAddress.isEmpty &&
        !pickupLatitude.isEmpty &&
        !pickupLongitude.isEmpty &&
        !dropoffLatitude.isEmpty &&
        !dropoffLongitude.isEmpty
    }
    
    private func addTrip() async {
        guard let companyId = appViewModel.currentCompany?.id else { return }
        
        let pickupLocation = TripLocation(
            name: pickupLocationName,
            address: pickupAddress,
            latitude: Double(pickupLatitude) ?? 0.0,
            longitude: Double(pickupLongitude) ?? 0.0
        )
        
        let dropoffLocation = TripLocation(
            name: dropoffLocationName,
            address: dropoffAddress,
            latitude: Double(dropoffLatitude) ?? 0.0,
            longitude: Double(dropoffLongitude) ?? 0.0
        )
        
        let trip = Trip(
            companyId: companyId,
            vehicleId: "", // Boş bırakılacak, sonra atanacak
            driverId: "", // Boş bırakılacak, sonra atanacak
            tripNumber: tripNumber,
            pickupLocation: pickupLocation,
            dropoffLocation: dropoffLocation,
            scheduledPickupTime: scheduledPickupTime,
            scheduledDropoffTime: scheduledDropoffTime,
            passengerCount: passengerCount
        )
        
        await tripViewModel.addTrip(trip)
        
        if tripViewModel.errorMessage == nil {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ShareSheet>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ShareSheet>) {}
}

struct TripAssignmentView_Previews: PreviewProvider {
    static var previews: some View {
        TripAssignmentView()
    }
}
