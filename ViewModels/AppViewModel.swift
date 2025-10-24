import Foundation
import Combine
import FirebaseAuth
import AuthenticationServices
import CryptoKit

class AppViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var currentCompany: Company?
    @Published var currentUserProfile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isEmailVerified = false
    @Published var verificationID: String?
    @Published var showEmailVerification = false
    
    private let firebaseService = FirebaseService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupAuthListener()
    }
    
    private func setupAuthListener() {
        firebaseService.$currentUser
            .sink { [weak self] user in
                self?.currentUser = user
                self?.isAuthenticated = user != nil
                self?.isEmailVerified = user?.isEmailVerified ?? false
                self?.showEmailVerification = user != nil && !(user?.isEmailVerified ?? false)
            }
            .store(in: &cancellables)
        
        firebaseService.$currentCompany
            .sink { [weak self] company in
                self?.currentCompany = company
            }
            .store(in: &cancellables)
        
        firebaseService.$currentUserProfile
            .sink { [weak self] profile in
                self?.currentUserProfile = profile
            }
            .store(in: &cancellables)
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await firebaseService.signIn(email: email, password: password)
            // E-posta doğrulama kontrolü
            if let user = Auth.auth().currentUser {
                try await user.reload()
                if !user.isEmailVerified {
                    try firebaseService.signOut()
                    errorMessage = "E-posta doğrulaması gerekli. Lütfen gelen kutunuzu kontrol edin."
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signUp(email: String, password: String, company: Company?, userType: UserType, fullName: String, phone: String? = nil) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await firebaseService.signUp(email: email, password: password, company: company, userType: userType, fullName: fullName, phone: phone, driverLicenseNumber: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signOut() {
        do {
            try firebaseService.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Email Verification
    func sendEmailVerification() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await firebaseService.sendEmailVerification()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Password Reset
    func sendPasswordReset(email: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await firebaseService.sendPasswordReset(email: email)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Phone Authentication (iOS only)
    #if os(iOS)
    func startPhoneSignIn(phoneNumber: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            verificationID = try await firebaseService.startPhoneSignIn(phoneNumber: phoneNumber)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func confirmOTP(code: String) async {
        guard let verificationID = verificationID else {
            errorMessage = "Doğrulama ID bulunamadı"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await firebaseService.confirmOTP(verificationID: verificationID, code: code)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    #endif
    
    // MARK: - Apple Sign In
    func signInWithApple(idToken: String, nonce: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await firebaseService.signInWithApple(idToken: idToken, nonce: nonce)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Helper Functions
    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}
