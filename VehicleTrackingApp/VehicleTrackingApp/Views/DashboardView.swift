import SwiftUI
import FirebaseAuth

struct DashboardView: View {
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var statisticsService = StatisticsService()
    @StateObject private var tripViewModel = TripViewModel()
    @StateObject private var vehicleViewModel = VehicleViewModel()
    @StateObject private var driverViewModel = DriverViewModel()
    @State private var selectedTab = 0
    @State private var showingProfile = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Ana Sayfa
            NavigationView {
                VStack {
                    // Welcome Header
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: ShuttleTrackTheme.Spacing.xs) {
                                Text("Hoş geldiniz!")
                                    .shuttleTrackCaption()
                                    .foregroundColor(.secondary)
                                
                                Text(getUserName())
                                    .shuttleTrackSubtitle()
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            // Profile Button
                            Button(action: {
                                showingProfile = true
                            }) {
                                CompactLogoView(size: 50)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Company Info
                        if let company = appViewModel.currentCompany {
                            HStack {
                                Image(systemName: "building.2.fill")
                                    .foregroundColor(.blue)
                                
                                Text(company.name)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                    
                    Spacer()
                    
                    // Hızlı İstatistikler
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Hızlı İstatistikler")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Button(action: {
                                if let companyId = appViewModel.currentCompany?.id {
                                    statisticsService.refreshStatistics(for: companyId)
                                }
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.blue)
                            }
                            .disabled(statisticsService.isLoading)
                        }
                        .padding(.horizontal)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            StatCard(
                                title: "Toplam Araç", 
                                value: statisticsService.isLoading ? "..." : "\(statisticsService.totalVehicles)", 
                                icon: "car.fill", 
                                color: .blue
                            )
                            StatCard(
                                title: "Aktif Sürücü", 
                                value: statisticsService.isLoading ? "..." : "\(statisticsService.activeDrivers)", 
                                icon: "person.fill", 
                                color: .green
                            )
                            StatCard(
                                title: "Bugünkü İşler", 
                                value: statisticsService.isLoading ? "..." : "\(statisticsService.todaysTrips)", 
                                icon: "list.bullet", 
                                color: .orange
                            )
                            StatCard(
                                title: "Tamamlanan", 
                                value: statisticsService.isLoading ? "..." : "\(statisticsService.completedTrips)", 
                                icon: "checkmark.circle.fill", 
                                color: .purple
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    // Quick Actions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Hızlı İşlemler")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        HStack(spacing: 16) {
                            QuickActionButton(
                                title: "Araç Ekle",
                                icon: "plus.circle.fill",
                                color: .blue
                            ) {
                                selectedTab = 1
                            }
                            
                            QuickActionButton(
                                title: "Sürücü Ekle",
                                icon: "person.badge.plus",
                                color: .green
                            ) {
                                selectedTab = 2
                            }
                            
                            QuickActionButton(
                                title: "İş Oluştur",
                                icon: "list.bullet",
                                color: .orange
                            ) {
                                selectedTab = 3
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom)
                }
                .navigationTitle("Araç Takip Sistemi")
                .navigationBarTitleDisplayMode(.large)
            }
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
                    Text("Sürücüler")
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
        .sheet(isPresented: $showingProfile) {
            ProfileView()
        }
        .onAppear {
            if let companyId = appViewModel.currentCompany?.id {
                print("🏠 Dashboard yüklendi - Company ID: \(companyId)")
                
                // İstatistikleri hemen yükle (main thread'de)
                statisticsService.startRealTimeUpdates(for: companyId)
                statisticsService.fetchStatistics(for: companyId)
                
                // Diğer verileri paralel yükle
                DispatchQueue.global(qos: .userInitiated).async {
                    let group = DispatchGroup()
                    
                    group.enter()
                    tripViewModel.fetchTrips(for: companyId)
                    group.leave()
                    
                    group.enter()
                    vehicleViewModel.fetchVehicles(for: companyId)
                    group.leave()
                    
                    group.enter()
                    driverViewModel.fetchDrivers(for: companyId)
                    group.leave()
                    
                    group.wait()
                    print("✅ Tüm veriler yüklendi")
                }
            } else {
                print("⚠️ Dashboard: Company ID bulunamadı")
            }
        }
        .onDisappear {
            statisticsService.stopRealTimeUpdates()
        }
        .alert("İstatistik Hatası", isPresented: .constant(!statisticsService.errorMessage.isEmpty)) {
            Button("Tamam") {
                statisticsService.clearError()
            }
        } message: {
            Text(statisticsService.errorMessage)
        }
    }
    
    // MARK: - Helper Functions
    private func getUserName() -> String {
        if let user = appViewModel.currentUser {
            return user.displayName ?? "Kullanıcı"
        }
        return "Kullanıcı"
    }
    
    private func getUserInitials() -> String {
        let name = getUserName()
        let components = name.components(separatedBy: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1)) + String(components[1].prefix(1))
        } else {
            return String(name.prefix(2))
        }
    }
}


struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
