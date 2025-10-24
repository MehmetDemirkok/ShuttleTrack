import Foundation
import Combine

class TripViewModel: ObservableObject {
    @Published var trips: [Trip] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let firebaseService = FirebaseService()
    private var cancellables = Set<AnyCancellable>()
    
    func fetchTrips(for companyId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            trips = try await firebaseService.fetchTrips(for: companyId)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func addTrip(_ trip: Trip) async {
        do {
            try await firebaseService.addTrip(trip)
            if let companyId = trip.companyId as String? {
                await fetchTrips(for: companyId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func updateTrip(_ trip: Trip) async {
        do {
            try await firebaseService.updateTrip(trip)
            if let companyId = trip.companyId as String? {
                await fetchTrips(for: companyId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func assignTripToDriver(tripId: String, driverId: String, vehicleId: String) async {
        guard let tripIndex = trips.firstIndex(where: { $0.id == tripId }) else { return }
        
        var updatedTrip = trips[tripIndex]
        updatedTrip.driverId = driverId
        updatedTrip.vehicleId = vehicleId
        updatedTrip.status = .assigned
        
        await updateTrip(updatedTrip)
    }
    
    func startTrip(tripId: String) async {
        guard let tripIndex = trips.firstIndex(where: { $0.id == tripId }) else { return }
        
        var updatedTrip = trips[tripIndex]
        updatedTrip.status = .inProgress
        updatedTrip.actualPickupTime = Date()
        
        await updateTrip(updatedTrip)
    }
    
    func completeTrip(tripId: String) async {
        guard let tripIndex = trips.firstIndex(where: { $0.id == tripId }) else { return }
        
        var updatedTrip = trips[tripIndex]
        updatedTrip.status = .completed
        updatedTrip.actualDropoffTime = Date()
        
        await updateTrip(updatedTrip)
    }
    
    func getTripsByStatus(_ status: Trip.TripStatus) -> [Trip] {
        return trips.filter { $0.status == status }
    }
    
    func getTodayTrips() -> [Trip] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return trips.filter { trip in
            trip.scheduledPickupTime >= today && trip.scheduledPickupTime < tomorrow
        }
    }
}
