import Foundation
import CoreLocation

struct Vehicle: Identifiable, Codable {
    let id: String
    var plateNumber: String
    var model: String
    var brand: String
    var year: Int
    var capacity: Int
    var color: String
    var isActive: Bool
    var currentLocation: VehicleLocation?
    var companyId: String
    var createdAt: Date
    var updatedAt: Date
    
    init(id: String = UUID().uuidString, 
         plateNumber: String, 
         model: String, 
         brand: String, 
         year: Int, 
         capacity: Int, 
         color: String, 
         isActive: Bool = true,
         companyId: String) {
        self.id = id
        self.plateNumber = plateNumber
        self.model = model
        self.brand = brand
        self.year = year
        self.capacity = capacity
        self.color = color
        self.isActive = isActive
        self.currentLocation = nil
        self.companyId = companyId
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var displayName: String {
        return "\(brand) \(model) - \(plateNumber)"
    }
    
    var statusText: String {
        return isActive ? "Aktif" : "Pasif"
    }
    
    var statusColor: String {
        return isActive ? "green" : "red"
    }
}

struct VehicleLocation: Codable {
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    let address: String?
    
    init(latitude: Double, longitude: Double, address: String? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = Date()
        self.address = address
    }
}
