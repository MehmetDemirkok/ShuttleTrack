import SwiftUI

struct DashboardView: View {
    @StateObject private var appViewModel = AppViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Ana Sayfa
            VStack {
                Text("Araç Takip Sistemi")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                Text("Hoş geldiniz!")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Hızlı İstatistikler
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 20) {
                    StatCard(title: "Toplam Araç", value: "12", icon: "car.fill", color: .blue)
                    StatCard(title: "Aktif Şoför", value: "8", icon: "person.fill", color: .green)
                    StatCard(title: "Bugünkü İşler", value: "15", icon: "list.bullet", color: .orange)
                    StatCard(title: "Tamamlanan", value: "23", icon: "checkmark.circle.fill", color: .purple)
                }
                .padding()
                
                Spacer()
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
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            trailing: Button("Çıkış") {
                appViewModel.signOut()
            }
        )
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

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
