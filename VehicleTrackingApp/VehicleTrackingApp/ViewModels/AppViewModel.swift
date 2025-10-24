import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

class AppViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var currentCompany: Company?
    
    private var cancellables = Set<AnyCancellable>()
    private var companyCache: [String: Company] = [:]
    private var lastCompanyLoadTime: Date?
    
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
        // Cache kontrolü - 10 dakika içinde yüklenmişse cache'den al
        if let lastLoad = lastCompanyLoadTime,
           Date().timeIntervalSince(lastLoad) < 600, // 10 dakika
           let cachedCompany = companyCache[user.uid] {
            print("📦 Company data loaded from cache")
            currentCompany = cachedCompany
            return
        }
        
        // Zaten yükleniyorsa tekrar yükleme
        if lastCompanyLoadTime != nil && Date().timeIntervalSince(lastCompanyLoadTime!) < 10 {
            print("⏳ Company data already loading, skipping...")
            return
        }
        
        print("🌐 Loading company data from Firebase...")
        lastCompanyLoadTime = Date()
        let db = Firestore.firestore()
        
        db.collection("companies").document(user.uid).getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error loading company data: \(error)")
                    return
                }
                
                if let document = document, document.exists {
                    do {
                        let company = try document.data(as: Company.self)
                        self?.currentCompany = company
                        self?.companyCache[user.uid] = company
                        print("✅ Company data loaded successfully")
                    } catch {
                        print("❌ Error decoding company: \(error)")
                    }
                } else {
                    print("⚠️ Company document not found for user: \(user.uid)")
                }
            }
        }
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
