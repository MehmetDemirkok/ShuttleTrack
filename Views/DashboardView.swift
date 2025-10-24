import SwiftUI

struct DashboardView: View {
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var vehicleViewModel = VehicleViewModel()
    @StateObject private var driverViewModel = DriverViewModel()
    @StateObject private var tripViewModel = TripViewModel()
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Ana Dashboard
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Ana Sayfa")
                }
                .tag(0)
            
            // Araç Yönetimi
            VehicleManagementView()
                .tabItem {
                    Image(systemName: "car.fill")
                    Text("Araçlar")
                }
                .tag(1)
            
            // Şoför Yönetimi
            DriverManagementView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Şoförler")
                }
                .tag(2)
            
            // İş Atama
            TripAssignmentView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("İşler")
                }
                .tag(3)
            
            // Takip
            TrackingView()
                .tabItem {
                    Image(systemName: "location.fill")
                    Text("Takip")
                }
                .tag(4)
        }
        .onAppear {
            loadData()
        }
    }
    
    private func loadData() {
        guard let companyId = appViewModel.currentCompany?.id else { return }
        
        Task {
            await vehicleViewModel.fetchVehicles(for: companyId)
            await driverViewModel.fetchDrivers(for: companyId)
            await tripViewModel.fetchTrips(for: companyId)
        }
    }
}

struct HomeView: View {
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var vehicleViewModel = VehicleViewModel()
    @StateObject private var driverViewModel = DriverViewModel()
    @StateObject private var tripViewModel = TripViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Hoş Geldin Mesajı
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Hoş Geldiniz")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text(appViewModel.currentCompany?.name ?? "Şirket")
                                    .font(.title)
                                    .foregroundColor(.blue)
                            }
                            
                            Spacer()
                            
                            Button("Çıkış") {
                                appViewModel.signOut()
                            }
                            .foregroundColor(.red)
                        }
                        .padding(.horizontal)
                    }
                    
                    // İstatistik Kartları
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 15) {
                        StatCard(
                            title: "Toplam Araç",
                            value: "\(vehicleViewModel.vehicles.count)",
                            icon: "car.fill",
                            color: .blue
                        )
                        
                        StatCard(
                            title: "Aktif Şoför",
                            value: "\(driverViewModel.drivers.filter { $0.isActive }.count)",
                            icon: "person.fill",
                            color: .green
                        )
                        
                        StatCard(
                            title: "Bugünkü İşler",
                            value: "\(tripViewModel.getTodayTrips().count)",
                            icon: "list.bullet",
                            color: .orange
                        )
                        
                        StatCard(
                            title: "Devam Eden",
                            value: "\(tripViewModel.getTripsByStatus(.inProgress).count)",
                            icon: "clock.fill",
                            color: .red
                        )
                    }
                    .padding(.horizontal)
                    
                    // Son Aktiviteler
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Son Aktiviteler")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(tripViewModel.trips.prefix(5)) { trip in
                            ActivityRow(trip: trip)
                        }
                    }
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarHidden(true)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct ActivityRow: View {
    let trip: Trip
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("İş #\(trip.tripNumber)")
                    .font(.headline)
                
                Text("\(trip.pickupLocation.name) → \(trip.dropoffLocation.name)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(trip.scheduledPickupTime, style: .time)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            StatusBadge(status: trip.status)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

struct StatusBadge: View {
    let status: Trip.TripStatus
    
    var body: some View {
        Text(statusText)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor)
            .foregroundColor(.white)
            .cornerRadius(4)
    }
    
    private var statusText: String {
        switch status {
        case .scheduled: return "Planlandı"
        case .assigned: return "Atandı"
        case .inProgress: return "Devam Ediyor"
        case .completed: return "Tamamlandı"
        case .cancelled: return "İptal"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .scheduled: return .gray
        case .assigned: return .blue
        case .inProgress: return .orange
        case .completed: return .green
        case .cancelled: return .red
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
