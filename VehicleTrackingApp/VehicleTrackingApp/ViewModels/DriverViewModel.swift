import SwiftUI
import Combine
import FirebaseFirestore

class DriverViewModel: ObservableObject {
    @Published var drivers: [Driver] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    func fetchDrivers(for companyId: String) {
        isLoading = true
        errorMessage = ""
        
        db.collection("drivers")
            .whereField("companyId", isEqualTo: companyId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self?.drivers = []
                        return
                    }
                    
                    self?.drivers = documents.compactMap { document in
                        try? document.data(as: Driver.self)
                    }
                }
            }
    }
    
    func addDriver(_ driver: Driver) {
        isLoading = true
        errorMessage = ""
        
        do {
            try db.collection("drivers").document(driver.id).setData(from: driver) { [weak self] error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func updateDriver(_ driver: Driver) {
        isLoading = true
        errorMessage = ""
        
        var updatedDriver = driver
        updatedDriver.updatedAt = Date()
        
        do {
            try db.collection("drivers").document(driver.id).setData(from: updatedDriver) { [weak self] error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func deleteDriver(_ driver: Driver) {
        isLoading = true
        errorMessage = ""
        
        db.collection("drivers").document(driver.id).delete { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func toggleDriverStatus(_ driver: Driver) {
        var updatedDriver = driver
        updatedDriver.isActive.toggle()
        updatedDriver.updatedAt = Date()
        
        updateDriver(updatedDriver)
    }
    
    func assignVehicleToDriver(_ driver: Driver, vehicleId: String?) {
        var updatedDriver = driver
        updatedDriver.assignedVehicleId = vehicleId
        updatedDriver.updatedAt = Date()
        
        updateDriver(updatedDriver)
    }
}
