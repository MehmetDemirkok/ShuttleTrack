import Foundation
import Combine

class DriverViewModel: ObservableObject {
    @Published var drivers: [Driver] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let firebaseService = FirebaseService()
    private var cancellables = Set<AnyCancellable>()
    
    func fetchDrivers(for companyId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            drivers = try await firebaseService.fetchDrivers(for: companyId)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func addDriver(_ driver: Driver) async {
        do {
            try await firebaseService.addDriver(driver)
            if let companyId = driver.companyId as String? {
                await fetchDrivers(for: companyId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func updateDriver(_ driver: Driver) async {
        do {
            try await firebaseService.updateDriver(driver)
            if let companyId = driver.companyId as String? {
                await fetchDrivers(for: companyId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func getAvailableDrivers() -> [Driver] {
        return drivers.filter { $0.isAvailable && $0.isActive }
    }
    
    func assignDriverToVehicle(driverId: String, vehicleId: String) async {
        guard let driverIndex = drivers.firstIndex(where: { $0.id == driverId }) else { return }
        
        var updatedDriver = drivers[driverIndex]
        updatedDriver.currentVehicleId = vehicleId
        updatedDriver.isAvailable = false
        
        await updateDriver(updatedDriver)
    }
}
