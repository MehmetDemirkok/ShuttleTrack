import SwiftUI
import FirebaseAuth
import Combine

class AppViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var currentCompany: Company?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        checkAuthenticationStatus()
    }
    
    private func checkAuthenticationStatus() {
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isAuthenticated = user != nil
                self?.currentUser = user
                if let user = user {
                    self?.loadCompanyData(for: user)
                }
            }
        }
    }
    
    private func loadCompanyData(for user: User) {
        // Company verilerini yükle
        // Bu kısım Firebase Firestore'dan company bilgilerini çekecek
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            isAuthenticated = false
            currentUser = nil
            currentCompany = nil
        } catch {
            print("Sign out error: \(error)")
        }
    }
}
