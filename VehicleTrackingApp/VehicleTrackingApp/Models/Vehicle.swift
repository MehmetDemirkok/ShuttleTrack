import Foundation
import CoreLocation

enum VehicleType: String, CaseIterable, Codable {
    case sedan = "Sedan"
    case suv = "SUV"
    case minivan = "Minivan"
    case bus = "Otobüs"
    case van = "Van"
    case pickup = "Pickup"
    
    var displayName: String {
        return self.rawValue
    }
}

struct Vehicle: Identifiable, Codable {
    let id: String
    var plateNumber: String
    var model: String
    var brand: String
    var year: Int
    var capacity: Int
    var vehicleType: VehicleType
    var color: String
    var insuranceExpiryDate: Date
    var inspectionExpiryDate: Date
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
         vehicleType: VehicleType,
         color: String, 
         insuranceExpiryDate: Date,
         inspectionExpiryDate: Date,
         isActive: Bool = true,
         companyId: String) {
        self.id = id
        self.plateNumber = plateNumber
        self.model = model
        self.brand = brand
        self.year = year
        self.capacity = capacity
        self.vehicleType = vehicleType
        self.color = color
        self.insuranceExpiryDate = insuranceExpiryDate
        self.inspectionExpiryDate = inspectionExpiryDate
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
