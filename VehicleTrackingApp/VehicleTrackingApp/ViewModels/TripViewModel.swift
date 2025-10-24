import SwiftUI
import Combine
import FirebaseFirestore

class TripViewModel: ObservableObject {
    @Published var trips: [Trip] = []
    @Published var vehicles: [Vehicle] = []
    @Published var drivers: [Driver] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    func fetchTrips(for companyId: String) {
        isLoading = true
        errorMessage = ""
        
        db.collection("trips")
            .whereField("companyId", isEqualTo: companyId)
            .order(by: "pickupTime", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self?.trips = []
                        return
                    }
                    
                    self?.trips = documents.compactMap { document in
                        try? document.data(as: Trip.self)
                    }
                }
            }
    }
    
    func fetchVehicles(for companyId: String) {
        db.collection("vehicles")
            .whereField("companyId", isEqualTo: companyId)
            .whereField("isActive", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error fetching vehicles: \(error)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self?.vehicles = []
                        return
                    }
                    
                    self?.vehicles = documents.compactMap { document in
                        try? document.data(as: Vehicle.self)
                    }
                }
            }
    }
    
    func fetchDrivers(for companyId: String) {
        db.collection("drivers")
            .whereField("companyId", isEqualTo: companyId)
            .whereField("isActive", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error fetching drivers: \(error)")
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
    
    func addTrip(_ trip: Trip) {
        isLoading = true
        errorMessage = ""
        
        do {
            try db.collection("trips").document(trip.id).setData(from: trip) { [weak self] error in
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
    
    func updateTrip(_ trip: Trip) {
        isLoading = true
        errorMessage = ""
        
        var updatedTrip = trip
        updatedTrip.updatedAt = Date()
        
        do {
            try db.collection("trips").document(trip.id).setData(from: updatedTrip) { [weak self] error in
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
    
    func deleteTrip(_ trip: Trip) {
        isLoading = true
        errorMessage = ""
        
        db.collection("trips").document(trip.id).delete { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func updateTripStatus(_ trip: Trip, status: TripStatus) {
        var updatedTrip = trip
        updatedTrip.status = status
        updatedTrip.updatedAt = Date()
        
        updateTrip(updatedTrip)
    }
    
    func assignTrip(_ trip: Trip, vehicleId: String?, driverId: String?) {
        var updatedTrip = trip
        updatedTrip.assignedVehicleId = vehicleId
        updatedTrip.assignedDriverId = driverId
        updatedTrip.status = (vehicleId != nil && driverId != nil) ? .assigned : .pending
        updatedTrip.updatedAt = Date()
        
        updateTrip(updatedTrip)
    }
    
    func getAvailableVehicles() -> [Vehicle] {
        let assignedVehicleIds = trips.compactMap { $0.assignedVehicleId }
        return vehicles.filter { !assignedVehicleIds.contains($0.id) }
    }
    
    func getAvailableDrivers() -> [Driver] {
        let assignedDriverIds = trips.compactMap { $0.assignedDriverId }
        return drivers.filter { !assignedDriverIds.contains($0.id) }
    }
}
