import Foundation
import FirebaseFirestore

struct Driver: Identifiable, Codable {
    @DocumentID var id: String?
    var companyId: String
    var firstName: String
    var lastName: String
    var email: String
    var phone: String
    var licenseNumber: String
    var licenseExpiryDate: Date
    var isActive: Bool
    var isAvailable: Bool
    var currentVehicleId: String?
    var rating: Double
    var totalTrips: Int
    var createdAt: Date
    var updatedAt: Date
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    init(companyId: String, firstName: String, lastName: String, email: String, phone: String, licenseNumber: String, licenseExpiryDate: Date) {
        self.companyId = companyId
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phone = phone
        self.licenseNumber = licenseNumber
        self.licenseExpiryDate = licenseExpiryDate
        self.isActive = true
        self.isAvailable = true
        self.rating = 0.0
        self.totalTrips = 0
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
