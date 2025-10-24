import SwiftUI

struct TripAssignmentView: View {
    @StateObject private var viewModel = TripViewModel()
    @StateObject private var appViewModel = AppViewModel()
    @State private var showingAddTrip = false
    @State private var selectedTrip: Trip?
    @State private var showingDeleteAlert = false
    @State private var tripToDelete: Trip?
    @State private var selectedStatus: TripStatus = .pending
    
    var body: some View {
        NavigationView {
            VStack {
                // Status Filter
                Picker("Durum", selection: $selectedStatus) {
                    Text("Tümü").tag(TripStatus.pending as TripStatus?)
                    ForEach(TripStatus.allCases, id: \.self) { status in
                        Text(status.displayName).tag(status as TripStatus?)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                if viewModel.isLoading {
                    ProgressView("İşler yükleniyor...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredTrips.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "list.bullet.clipboard")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("Henüz iş eklenmemiş")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text("İlk işinizi eklemek için + butonuna tıklayın")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredTrips) { trip in
                            TripRowView(
                                trip: trip,
                                onEdit: { selectedTrip = trip },
                                onDelete: { 
                                    tripToDelete = trip
                                    showingDeleteAlert = true
                                },
                                onStatusChange: { newStatus in
                                    viewModel.updateTripStatus(trip, status: newStatus)
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
            .navigationTitle("İşler")
            .navigationBarItems(
                trailing: Button(action: {
                    showingAddTrip = true
                }) {
                    Image(systemName: "plus")
                }
            )
            .onAppear {
                loadTrips()
            }
            .sheet(isPresented: $showingAddTrip) {
                AddEditTripView(viewModel: viewModel, appViewModel: appViewModel)
            }
            .sheet(item: $selectedTrip) { trip in
                AddEditTripView(trip: trip, viewModel: viewModel, appViewModel: appViewModel)
            }
            .alert("İşi Sil", isPresented: $showingDeleteAlert) {
                Button("İptal", role: .cancel) { }
                Button("Sil", role: .destructive) {
                    if let trip = tripToDelete {
                        viewModel.deleteTrip(trip)
                    }
                }
            } message: {
                Text("Bu işi silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.")
            }
        }
    }
    
    private var filteredTrips: [Trip] {
        if selectedStatus == .pending {
            return viewModel.trips
        } else {
            return viewModel.trips.filter { $0.status == selectedStatus }
        }
    }
    
    private func loadTrips() {
        guard let companyId = appViewModel.currentCompany?.id else { return }
        viewModel.fetchTrips(for: companyId)
        viewModel.fetchVehicles(for: companyId)
        viewModel.fetchDrivers(for: companyId)
    }
}

struct TripRowView: View {
    let trip: Trip
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onStatusChange: (TripStatus) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(trip.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(trip.pickupLocation) → \(trip.dropoffLocation)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Yolcu: \(trip.passengerName) (\(trip.passengerCount) kişi)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        Circle()
                            .fill(Color(trip.statusColor))
                            .frame(width: 8, height: 8)
                        
                        Text(trip.statusText)
                            .font(.caption)
                            .foregroundColor(Color(trip.statusColor))
                    }
                    
                    Text(trip.pickupTime, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if trip.isOverdue {
                        Text("⚠️ Geçti")
                            .font(.caption2)
                            .foregroundColor(.red)
                    } else {
                        Text("⏰ \(trip.timeRemaining)")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            if let vehicleId = trip.assignedVehicleId, let driverId = trip.assignedDriverId {
                HStack {
                    Text("🚗 Araç atanmış")
                        .font(.caption2)
                        .foregroundColor(.green)
                    
                    Spacer()
                    
                    Text("👨‍💼 Şoför atanmış")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
            
            HStack(spacing: 12) {
                Button("Düzenle") {
                    print("🔧 TripRowView: Düzenle butonuna tıklandı - Trip: \(trip.title)")
                    onEdit()
                }
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(6)
                
                if trip.status != .completed && trip.status != .cancelled {
                    Menu("Durum") {
                        ForEach(TripStatus.allCases, id: \.self) { status in
                            if status != trip.status {
                                Button(status.displayName) {
                                    onStatusChange(status)
                                }
                            }
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
                }
                
                Button("Sil") {
                    print("🗑️ TripRowView: Sil butonuna tıklandı - Trip: \(trip.title)")
                    onDelete()
                }
                .font(.caption)
                .foregroundColor(.red)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .padding(.vertical, 4)
    }
}

struct TripAssignmentView_Previews: PreviewProvider {
    static var previews: some View {
        TripAssignmentView()
    }
}
