import Foundation
import FirebaseFirestore

struct UserProfile: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var displayName: String
    var email: String
    var phoneNumber: String?
    var profileImageURL: String?
    var companyId: String
    var role: UserRole
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
    var lastLoginAt: Date?
    
    enum UserRole: String, CaseIterable, Codable {
        case admin = "admin"
        case manager = "manager"
        case driver = "driver"
        case dispatcher = "dispatcher"
        
        var displayName: String {
            switch self {
            case .admin: return "Yönetici"
            case .manager: return "Müdür"
            case .driver: return "Şoför"
            case .dispatcher: return "Sevk Memuru"
            }
        }
    }
    
    init(userId: String, displayName: String, email: String, companyId: String, role: UserRole = .admin) {
        self.userId = userId
        self.displayName = displayName
        self.email = email
        self.companyId = companyId
        self.role = role
        self.isActive = true
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
