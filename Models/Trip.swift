import Foundation
import FirebaseFirestore
import CoreLocation

struct Trip: Identifiable, Codable {
    @DocumentID var id: String?
    var companyId: String
    var vehicleId: String
    var driverId: String
    var tripNumber: String
    var pickupLocation: TripLocation
    var dropoffLocation: TripLocation
    var scheduledPickupTime: Date
    var scheduledDropoffTime: Date
    var actualPickupTime: Date?
    var actualDropoffTime: Date?
    var status: TripStatus
    var passengerCount: Int
    var notes: String?
    var fare: Double?
    var createdAt: Date
    var updatedAt: Date
    
    enum TripStatus: String, CaseIterable, Codable {
        case scheduled = "scheduled"
        case assigned = "assigned"
        case inProgress = "in_progress"
        case completed = "completed"
        case cancelled = "cancelled"
    }
    
    init(companyId: String, vehicleId: String, driverId: String, tripNumber: String, pickupLocation: TripLocation, dropoffLocation: TripLocation, scheduledPickupTime: Date, scheduledDropoffTime: Date, passengerCount: Int) {
        self.companyId = companyId
        self.vehicleId = vehicleId
        self.driverId = driverId
        self.tripNumber = tripNumber
        self.pickupLocation = pickupLocation
        self.dropoffLocation = dropoffLocation
        self.scheduledPickupTime = scheduledPickupTime
        self.scheduledDropoffTime = scheduledDropoffTime
        self.status = .scheduled
        self.passengerCount = passengerCount
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

struct TripLocation: Codable {
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
    var notes: String?
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
