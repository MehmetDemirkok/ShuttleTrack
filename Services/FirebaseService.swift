import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class FirebaseService: ObservableObject {
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    @Published var currentUser: User?
    @Published var currentCompany: Company?
    @Published var currentUserProfile: UserProfile?
    
    init() {
        auth.addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            if let user = user {
                self?.fetchUserProfile(for: user.uid)
                if let userProfile = self?.currentUserProfile, userProfile.userType == .companyAdmin {
                    self?.fetchCompany(for: user.uid)
                }
            } else {
                self?.currentUserProfile = nil
                self?.currentCompany = nil
            }
        }
    }
    
    // MARK: - Authentication
    func signIn(email: String, password: String) async throws {
        try await auth.signIn(withEmail: email, password: password)
    }
    
    func signUp(email: String, password: String, company: Company?, userType: UserType, fullName: String, phone: String? = nil) async throws {
        let result = try await auth.createUser(withEmail: email, password: password)
        
        // Kullanıcı profili oluştur
        let userProfile = UserProfile(
            userId: result.user.uid,
            userType: userType,
            email: email,
            fullName: fullName,
            phone: phone,
            companyId: userType == .companyAdmin ? result.user.uid : nil,
            driverLicenseNumber: nil
        )
        
        try await createUserProfile(userProfile)
        
        // Şirket yetkilisi ise şirket bilgilerini kaydet
        if userType == .companyAdmin, let company = company {
            var companyData = company
            companyData.id = result.user.uid
            try await db.collection("companies").document(result.user.uid).setData(from: companyData)
        }
        
        // E-posta doğrulama gönder
        try await result.user.sendEmailVerification()
    }
    
    func createUserProfile(_ profile: UserProfile) async throws {
        var profileData = profile
        profileData.id = profile.userId
        try await db.collection("userProfiles").document(profile.userId).setData(from: profileData)
    }
    
    func fetchUserProfile(for userId: String) async throws -> UserProfile? {
        let document = try await db.collection("userProfiles").document(userId).getDocument()
        
        if document.exists {
            return try document.data(as: UserProfile.self)
        }
        return nil
    }
    
    func signOut() throws {
        try auth.signOut()
        currentCompany = nil
        currentUserProfile = nil
    }
    
    // MARK: - Email Verification
    func sendEmailVerification() async throws {
        guard let user = auth.currentUser else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı bulunamadı"])
        }
        try await user.sendEmailVerification()
    }
    
    func isEmailVerified() -> Bool {
        return auth.currentUser?.isEmailVerified ?? false
    }
    
    // MARK: - Password Reset
    func sendPasswordReset(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }
    
    // MARK: - Phone Authentication (iOS only)
    #if os(iOS)
    func startPhoneSignIn(phoneNumber: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: verificationID ?? "")
                }
            }
        }
    }
    
    func confirmOTP(verificationID: String, code: String) async throws {
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: code)
        try await auth.signIn(with: credential)
    }
    #endif
    
    // MARK: - Apple Sign In
    func signInWithApple(idToken: String, nonce: String) async throws {
        let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idToken, rawNonce: nonce)
        try await auth.signIn(with: credential)
    }
    
    // MARK: - User Profile Management
    private func fetchUserProfile(for userId: String) {
        db.collection("userProfiles").document(userId).getDocument { [weak self] document, error in
            if let document = document, document.exists {
                do {
                    self?.currentUserProfile = try document.data(as: UserProfile.self)
                } catch {
                    print("Error decoding user profile: \(error)")
                }
            }
        }
    }
    
    // MARK: - Company Management
    private func fetchCompany(for userId: String) {
        db.collection("companies").document(userId).getDocument { [weak self] document, error in
            if let document = document, document.exists {
                do {
                    self?.currentCompany = try document.data(as: Company.self)
                } catch {
                    print("Error decoding company: \(error)")
                }
            }
        }
    }
    
    // MARK: - Vehicle Management
    func addVehicle(_ vehicle: Vehicle) async throws {
        var vehicleData = vehicle
        vehicleData.id = UUID().uuidString
        try await db.collection("vehicles").document(vehicleData.id!).setData(from: vehicleData)
    }
    
    func fetchVehicles(for companyId: String) async throws -> [Vehicle] {
        let snapshot = try await db.collection("vehicles")
            .whereField("companyId", isEqualTo: companyId)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: Vehicle.self)
        }
    }
    
    func updateVehicle(_ vehicle: Vehicle) async throws {
        guard let id = vehicle.id else { return }
        try await db.collection("vehicles").document(id).setData(from: vehicle)
    }
    
    func deleteVehicle(_ vehicle: Vehicle) async throws {
        guard let id = vehicle.id else { return }
        try await db.collection("vehicles").document(id).delete()
    }
    
    // MARK: - Driver Management
    func addDriver(_ driver: Driver) async throws {
        var driverData = driver
        driverData.id = UUID().uuidString
        try await db.collection("drivers").document(driverData.id!).setData(from: driverData)
    }
    
    func fetchDrivers(for companyId: String) async throws -> [Driver] {
        let snapshot = try await db.collection("drivers")
            .whereField("companyId", isEqualTo: companyId)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: Driver.self)
        }
    }
    
    func updateDriver(_ driver: Driver) async throws {
        guard let id = driver.id else { return }
        try await db.collection("drivers").document(id).setData(from: driver)
    }
    
    // MARK: - Trip Management
    func addTrip(_ trip: Trip) async throws {
        var tripData = trip
        tripData.id = UUID().uuidString
        try await db.collection("trips").document(tripData.id!).setData(from: tripData)
    }
    
    func fetchTrips(for companyId: String) async throws -> [Trip] {
        let snapshot = try await db.collection("trips")
            .whereField("companyId", isEqualTo: companyId)
            .order(by: "scheduledPickupTime", descending: false)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: Trip.self)
        }
    }
    
    func updateTrip(_ trip: Trip) async throws {
        guard let id = trip.id else { return }
        try await db.collection("trips").document(id).setData(from: trip)
    }
    
    // MARK: - Location Tracking
    func updateVehicleLocation(vehicleId: String, location: VehicleLocation) async throws {
        try await db.collection("vehicles").document(vehicleId).updateData([
            "currentLocation": try Firestore.Encoder().encode(location),
            "lastUpdated": Date()
        ])
    }
}
