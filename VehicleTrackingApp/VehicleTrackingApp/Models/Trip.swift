import Foundation

struct Trip: Identifiable, Codable, @unchecked Sendable {
    let id: String
    var title: String
    var description: String
    var pickupLocation: String
    var dropoffLocation: String
    var pickupTime: Date
    var dropoffTime: Date
    var passengerCount: Int
    var passengerName: String
    var passengerPhone: String
    var status: TripStatus
    var assignedVehicleId: String?
    var assignedDriverId: String?
    var companyId: String
    var createdAt: Date
    var updatedAt: Date
    
    init(id: String = UUID().uuidString,
         title: String,
         description: String,
         pickupLocation: String,
         dropoffLocation: String,
         pickupTime: Date,
         dropoffTime: Date,
         passengerCount: Int,
         passengerName: String,
         passengerPhone: String,
         status: TripStatus = .pending,
         companyId: String) {
        self.id = id
        self.title = title
        self.description = description
        self.pickupLocation = pickupLocation
        self.dropoffLocation = dropoffLocation
        self.pickupTime = pickupTime
        self.dropoffTime = dropoffTime
        self.passengerCount = passengerCount
        self.passengerName = passengerName
        self.passengerPhone = passengerPhone
        self.status = status
        self.assignedVehicleId = nil
        self.assignedDriverId = nil
        self.companyId = companyId
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var statusText: String {
        switch status {
        case .pending:
            return "Beklemede"
        case .assigned:
            return "Atanmış"
        case .inProgress:
            return "Devam Ediyor"
        case .completed:
            return "Tamamlandı"
        case .cancelled:
            return "İptal Edildi"
        }
    }
    
    var statusColor: String {
        switch status {
        case .pending:
            return "orange"
        case .assigned:
            return "blue"
        case .inProgress:
            return "green"
        case .completed:
            return "gray"
        case .cancelled:
            return "red"
        }
    }
    
    var isOverdue: Bool {
        return pickupTime < Date() && status != .completed && status != .cancelled
    }
    
    var timeRemaining: String {
        let timeInterval = pickupTime.timeIntervalSinceNow
        if timeInterval < 0 {
            return "Geçti"
        } else {
            let hours = Int(timeInterval) / 3600
            let minutes = Int(timeInterval.truncatingRemainder(dividingBy: 3600)) / 60
            if hours > 0 {
                return "\(hours) saat \(minutes) dakika"
            } else {
                return "\(minutes) dakika"
            }
        }
    }
}

enum TripStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case assigned = "assigned"
    case inProgress = "inProgress"
    case completed = "completed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Beklemede"
        case .assigned:
            return "Atanmış"
        case .inProgress:
            return "Devam Ediyor"
        case .completed:
            return "Tamamlandı"
        case .cancelled:
            return "İptal Edildi"
        }
    }
}
