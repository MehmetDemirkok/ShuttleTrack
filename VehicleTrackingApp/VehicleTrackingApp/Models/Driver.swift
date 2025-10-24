import Foundation

struct Driver: Identifiable, Codable {
    let id: String
    var firstName: String
    var lastName: String
    var phoneNumber: String
    var email: String
    var licenseNumber: String
    var licenseExpiryDate: Date
    var isActive: Bool
    var assignedVehicleId: String?
    var companyId: String
    var createdAt: Date
    var updatedAt: Date
    
    init(id: String = UUID().uuidString,
         firstName: String,
         lastName: String,
         phoneNumber: String,
         email: String,
         licenseNumber: String,
         licenseExpiryDate: Date,
         isActive: Bool = true,
         companyId: String) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.phoneNumber = phoneNumber
        self.email = email
        self.licenseNumber = licenseNumber
        self.licenseExpiryDate = licenseExpiryDate
        self.isActive = isActive
        self.assignedVehicleId = nil
        self.companyId = companyId
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var fullName: String {
        return "\(firstName) \(lastName)"
    }
    
    var statusText: String {
        return isActive ? "Aktif" : "Pasif"
    }
    
    var statusColor: String {
        return isActive ? "green" : "red"
    }
    
    var isLicenseExpired: Bool {
        return licenseExpiryDate < Date()
    }
    
    var licenseStatusText: String {
        if isLicenseExpired {
            return "Süresi Dolmuş"
        } else {
            let daysUntilExpiry = Calendar.current.dateComponents([.day], from: Date(), to: licenseExpiryDate).day ?? 0
            if daysUntilExpiry <= 30 {
                return "\(daysUntilExpiry) gün kaldı"
            } else {
                return "Geçerli"
            }
        }
    }
    
    var licenseStatusColor: String {
        if isLicenseExpired {
            return "red"
        } else {
            let daysUntilExpiry = Calendar.current.dateComponents([.day], from: Date(), to: licenseExpiryDate).day ?? 0
            if daysUntilExpiry <= 30 {
                return "orange"
            } else {
                return "green"
            }
        }
    }
}
