import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

class ProfileViewModel: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var successMessage = ""
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadUserProfile()
    }
    
    func loadUserProfile() {
        guard let user = Auth.auth().currentUser else { return }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let document = try await db.collection("userProfiles").document(user.uid).getDocument()
                
                if document.exists {
                    let profile = try document.data(as: UserProfile.self)
                    await MainActor.run {
                        self.userProfile = profile
                        self.isLoading = false
                    }
                } else {
                    // Profil bulunamadı, yeni profil oluştur
                    await MainActor.run {
                        self.isLoading = false
                        self.createUserProfile()
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Profil yüklenirken hata oluştu: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func updateProfile(displayName: String, phoneNumber: String?, role: UserProfile.UserRole) {
        guard var profile = userProfile else {
            errorMessage = "Profil bulunamadı"
            return
        }
        
        isLoading = true
        errorMessage = ""
        successMessage = ""
        
        profile.displayName = displayName
        profile.phoneNumber = phoneNumber
        profile.role = role
        profile.updatedAt = Date()
        
        Task {
            do {
                guard let userId = profile.id else { return }
                var updatedProfile = profile
                updatedProfile.updatedAt = Date()
                try await db.collection("userProfiles").document(userId).setData(from: updatedProfile)
                await MainActor.run {
                    self.userProfile = profile
                    self.isLoading = false
                    self.successMessage = "Profil başarıyla güncellendi"
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Profil güncellenirken hata oluştu: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func updateEmail(newEmail: String) {
        guard let user = Auth.auth().currentUser else { return }
        
        isLoading = true
        errorMessage = ""
        successMessage = ""
        
        Task {
            do {
                try await user.updateEmail(to: newEmail)
                
                // Update profile in Firestore
                if var profile = userProfile {
                    profile.email = newEmail
                    profile.updatedAt = Date()
                    guard let userId = profile.id else { return }
                    try await db.collection("userProfiles").document(userId).setData(from: profile)
                    
                    await MainActor.run {
                        self.userProfile = profile
                        self.isLoading = false
                        self.successMessage = "E-posta adresi başarıyla güncellendi"
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "E-posta güncellenirken hata oluştu: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func updatePassword(currentPassword: String, newPassword: String) {
        guard let user = Auth.auth().currentUser else { return }
        
        isLoading = true
        errorMessage = ""
        successMessage = ""
        
        Task {
            do {
                // Re-authenticate user before changing password
                let credential = EmailAuthProvider.credential(withEmail: user.email ?? "", password: currentPassword)
                try await user.reauthenticate(with: credential)
                
                // Update password
                try await user.updatePassword(to: newPassword)
                
                await MainActor.run {
                    self.isLoading = false
                    self.successMessage = "Şifre başarıyla güncellendi"
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Şifre güncellenirken hata oluştu: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func createUserProfile() {
        guard let user = Auth.auth().currentUser,
              let companyId = getCurrentCompanyId() else { 
            errorMessage = "Kullanıcı veya şirket bilgisi bulunamadı"
            return 
        }
        
        isLoading = true
        errorMessage = ""
        
        let newProfile = UserProfile(
            userId: user.uid,
            displayName: user.displayName ?? "",
            email: user.email ?? "",
            companyId: companyId,
            role: .admin
        )
        
        Task {
            do {
                var profileData = newProfile
                profileData.id = newProfile.userId
                try await db.collection("userProfiles").document(newProfile.userId).setData(from: profileData)
                await MainActor.run {
                    self.userProfile = newProfile
                    self.isLoading = false
                    self.successMessage = "Profil başarıyla oluşturuldu"
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Profil oluşturulurken hata oluştu: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func getCurrentCompanyId() -> String? {
        // This should be integrated with AppViewModel to get current company
        return Auth.auth().currentUser?.uid
    }
    
    func clearMessages() {
        errorMessage = ""
        successMessage = ""
    }
}
