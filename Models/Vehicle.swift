import Foundation
import FirebaseFirestore
import CoreLocation

struct Vehicle: Identifiable, Codable {
    @DocumentID var id: String?
    var companyId: String
    var plateNumber: String
    var make: String
    var model: String
    var year: Int
    var capacity: Int
    var vehicleType: VehicleType
    var isActive: Bool
    var currentLocation: VehicleLocation?
    var lastUpdated: Date
    var createdAt: Date
    
    enum VehicleType: String, CaseIterable, Codable {
        case bus = "bus"
        case minibus = "minibus"
        case car = "car"
        case van = "van"
    }
    
    init(companyId: String, plateNumber: String, make: String, model: String, year: Int, capacity: Int, vehicleType: VehicleType) {
        self.companyId = companyId
        self.plateNumber = plateNumber
        self.make = make
        self.model = model
        self.year = year
        self.capacity = capacity
        self.vehicleType = vehicleType
        self.isActive = true
        self.lastUpdated = Date()
        self.createdAt = Date()
    }
}

struct VehicleLocation: Codable {
    var latitude: Double
    var longitude: Double
    var timestamp: Date
    var speed: Double?
    var heading: Double?
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
