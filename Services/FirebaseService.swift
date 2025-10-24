import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class FirebaseService: ObservableObject {
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    @Published var currentUser: User?
    @Published var currentCompany: Company?
    
    init() {
        auth.addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            if let user = user {
                self?.fetchCompany(for: user.uid)
            }
        }
    }
    
    // MARK: - Authentication
    func signIn(email: String, password: String) async throws {
        try await auth.signIn(withEmail: email, password: password)
    }
    
    func signUp(email: String, password: String, company: Company) async throws {
        let result = try await auth.createUser(withEmail: email, password: password)
        let companyData = company
        companyData.id = result.user.uid
        try await db.collection("companies").document(result.user.uid).setData(from: companyData)
    }
    
    func signOut() throws {
        try auth.signOut()
        currentCompany = nil
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
