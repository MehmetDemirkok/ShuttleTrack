import SwiftUI
import Combine
import FirebaseFirestore

class VehicleViewModel: ObservableObject {
    @Published var vehicles: [Vehicle] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    func fetchVehicles(for companyId: String) {
        isLoading = true
        errorMessage = ""
        
        db.collection("vehicles")
            .whereField("companyId", isEqualTo: companyId)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self?.vehicles = []
                        return
                    }
                    
                    let vehicles = documents.compactMap { document in
                        try? document.data(as: Vehicle.self)
                    }
                    // Client-side sorting to avoid index requirement
                    self?.vehicles = vehicles.sorted { $0.createdAt > $1.createdAt }
                }
            }
    }
    
    func addVehicle(_ vehicle: Vehicle) {
        isLoading = true
        errorMessage = ""
        
        do {
            try db.collection("vehicles").document(vehicle.id).setData(from: vehicle) { [weak self] error in
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
    
    func updateVehicle(_ vehicle: Vehicle) {
        isLoading = true
        errorMessage = ""
        
        var updatedVehicle = vehicle
        updatedVehicle.updatedAt = Date()
        
        do {
            try db.collection("vehicles").document(vehicle.id).setData(from: updatedVehicle) { [weak self] error in
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
    
    func deleteVehicle(_ vehicle: Vehicle) {
        isLoading = true
        errorMessage = ""
        
        db.collection("vehicles").document(vehicle.id).delete { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func toggleVehicleStatus(_ vehicle: Vehicle) {
        var updatedVehicle = vehicle
        updatedVehicle.isActive.toggle()
        updatedVehicle.updatedAt = Date()
        
        updateVehicle(updatedVehicle)
    }
}
