import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var statisticsService = StatisticsService()
    @State private var showingLogoutAlert = false
    @State private var showingEditProfile = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 120, height: 120)
                            
                            Text(getUserInitials())
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        
                        // User Info
                        VStack(spacing: 8) {
                            Text(getUserName())
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text(getUserEmail())
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if let company = appViewModel.currentCompany {
                                Text(company.name)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.top, 20)
                    
                    // Profile Sections
                    VStack(spacing: 16) {
                        // Account Information
                        ProfileSectionView(
                            title: "Hesap Bilgileri",
                            icon: "person.circle.fill",
                            iconColor: .blue
                        ) {
                            VStack(spacing: 12) {
                                ProfileInfoRow(
                                    icon: "envelope.fill",
                                    title: "E-posta",
                                    value: getUserEmail(),
                                    iconColor: .green
                                )
                                
                                ProfileInfoRow(
                                    icon: "building.2.fill",
                                    title: "Şirket",
                                    value: appViewModel.currentCompany?.name ?? "Şirket bilgisi yok",
                                    iconColor: .orange
                                )
                                
                                ProfileInfoRow(
                                    icon: "calendar.badge.clock",
                                    title: "Üyelik Tarihi",
                                    value: getJoinDate(),
                                    iconColor: .purple
                                )
                            }
                        }
                        
                        // Statistics
                        ProfileSectionView(
                            title: "İstatistikler",
                            icon: "chart.bar.fill",
                            iconColor: .green
                        ) {
                            HStack(spacing: 20) {
                                StatCard(
                                    title: "Toplam Araç",
                                    value: statisticsService.isLoading ? "..." : "\(statisticsService.totalVehicles)",
                                    icon: "car.fill",
                                    color: .blue
                                )
                                
                                StatCard(
                                    title: "Aktif Şoför",
                                    value: statisticsService.isLoading ? "..." : "\(statisticsService.activeDrivers)",
                                    icon: "person.fill",
                                    color: .green
                                )
                                
                                StatCard(
                                    title: "Bu Ay İş",
                                    value: statisticsService.isLoading ? "..." : "\(statisticsService.todaysTrips)",
                                    icon: "list.bullet.fill",
                                    color: .orange
                                )
                            }
                        }
                        
                        // Quick Actions
                        ProfileSectionView(
                            title: "Hızlı İşlemler",
                            icon: "bolt.fill",
                            iconColor: .yellow
                        ) {
                            VStack(spacing: 12) {
                                ProfileActionButton(
                                    title: "Profil Düzenle",
                                    icon: "pencil.circle.fill",
                                    iconColor: .blue
                                ) {
                                    showingEditProfile = true
                                }
                                
                                ProfileActionButton(
                                    title: "Ayarlar",
                                    icon: "gearshape.fill",
                                    iconColor: .gray
                                ) {
                                    // Settings action
                                }
                                
                                ProfileActionButton(
                                    title: "Yardım & Destek",
                                    icon: "questionmark.circle.fill",
                                    iconColor: .green
                                ) {
                                    // Help action
                                }
                            }
                        }
                        
                        // Logout Section
                        VStack(spacing: 16) {
                            Button(action: {
                                showingLogoutAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                    
                                    Text("Çıkış Yap")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                }
                                .padding()
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.red, .pink]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                        }
                        .padding(.top, 20)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.large)
            .alert("Çıkış Yap", isPresented: $showingLogoutAlert) {
                Button("İptal", role: .cancel) { }
                Button("Çıkış Yap", role: .destructive) {
                    appViewModel.signOut()
                }
            } message: {
                Text("Hesabınızdan çıkmak istediğinizden emin misiniz?")
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
            }
            .onAppear {
                if let companyId = appViewModel.currentCompany?.id {
                    statisticsService.startRealTimeUpdates(for: companyId)
                }
            }
            .onDisappear {
                statisticsService.stopRealTimeUpdates()
            }
        }
    }
    
    // MARK: - Helper Functions
    private func getUserName() -> String {
        if let user = appViewModel.currentUser {
            return user.displayName ?? "Kullanıcı"
        }
        return "Kullanıcı"
    }
    
    private func getUserEmail() -> String {
        return appViewModel.currentUser?.email ?? "E-posta bulunamadı"
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
    
    private func getJoinDate() -> String {
        if let user = appViewModel.currentUser {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.locale = Locale(identifier: "tr_TR")
            return formatter.string(from: user.metadata.creationDate ?? Date())
        }
        return "Bilinmiyor"
    }
}

// MARK: - Supporting Views
struct ProfileSectionView<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: Content
    
    init(title: String, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            content
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct ProfileInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let iconColor: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ProfileActionButton: View {
    let title: String
    let icon: String
    let iconColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
                    .frame(width: 24)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EditProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var displayName = ""
    @State private var email = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Kişisel Bilgiler")) {
                    TextField("Ad Soyad", text: $displayName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("E-posta", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                Section(header: Text("Bilgi")) {
                    Text("Profil düzenleme özelliği yakında eklenecek.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Profil Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("İptal") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Kaydet") {
                    // Save profile logic
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
