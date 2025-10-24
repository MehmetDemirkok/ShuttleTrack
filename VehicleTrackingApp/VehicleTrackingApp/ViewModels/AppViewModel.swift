import SwiftUI
import FirebaseAuth
import FirebaseFirestore
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
        let db = Firestore.firestore()
        
        db.collection("companies").document(user.uid).getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error loading company data: \(error)")
                    return
                }
                
                if let document = document, document.exists {
                    do {
                        self?.currentCompany = try document.data(as: Company.self)
                    } catch {
                        print("Error decoding company: \(error)")
                    }
                } else {
                    print("Company document not found for user: \(user.uid)")
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
