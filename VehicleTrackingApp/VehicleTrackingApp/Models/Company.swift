import Foundation

struct Company: Identifiable, Codable {
    let id: String
    let name: String
    let email: String
    let phone: String
    let address: String
    let createdAt: Date
    
    init(id: String = UUID().uuidString, name: String, email: String, phone: String, address: String) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.address = address
        self.createdAt = Date()
    }
}
