import Foundation
import Combine

class VehicleViewModel: ObservableObject {
    @Published var vehicles: [Vehicle] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let firebaseService = FirebaseService()
    private var cancellables = Set<AnyCancellable>()
    
    func fetchVehicles(for companyId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            vehicles = try await firebaseService.fetchVehicles(for: companyId)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func addVehicle(_ vehicle: Vehicle) async {
        do {
            try await firebaseService.addVehicle(vehicle)
            if let companyId = vehicle.companyId as String? {
                await fetchVehicles(for: companyId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func updateVehicle(_ vehicle: Vehicle) async {
        do {
            try await firebaseService.updateVehicle(vehicle)
            if let companyId = vehicle.companyId as String? {
                await fetchVehicles(for: companyId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func deleteVehicle(_ vehicle: Vehicle) async {
        do {
            try await firebaseService.deleteVehicle(vehicle)
            vehicles.removeAll { $0.id == vehicle.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
