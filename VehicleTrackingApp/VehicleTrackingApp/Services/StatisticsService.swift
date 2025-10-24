import Foundation
import FirebaseFirestore
import Combine

class StatisticsService: ObservableObject {
    @Published var totalVehicles = 0
    @Published var activeDrivers = 0
    @Published var todaysTrips = 0
    @Published var completedTrips = 0
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    func fetchStatistics(for companyId: String) {
        isLoading = true
        errorMessage = ""
        
        // Tüm istatistikleri paralel olarak çek
        let group = DispatchGroup()
        
        // Araç sayısı
        group.enter()
        fetchVehicleCount(for: companyId) { [weak self] count in
            DispatchQueue.main.async {
                self?.totalVehicles = count
                group.leave()
            }
        }
        
        // Aktif şoför sayısı
        group.enter()
        fetchActiveDriverCount(for: companyId) { [weak self] count in
            DispatchQueue.main.async {
                self?.activeDrivers = count
                group.leave()
            }
        }
        
        // Bugünkü işler
        group.enter()
        fetchTodaysTripCount(for: companyId) { [weak self] count in
            DispatchQueue.main.async {
                self?.todaysTrips = count
                group.leave()
            }
        }
        
        // Tamamlanan işler
        group.enter()
        fetchCompletedTripCount(for: companyId) { [weak self] count in
            DispatchQueue.main.async {
                self?.completedTrips = count
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.isLoading = false
        }
    }
    
    private func fetchVehicleCount(for companyId: String, completion: @escaping (Int) -> Void) {
        db.collection("vehicles")
            .whereField("companyId", isEqualTo: companyId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching vehicles: \(error)")
                    completion(0)
                    return
                }
                
                let count = snapshot?.documents.count ?? 0
                completion(count)
            }
    }
    
    private func fetchActiveDriverCount(for companyId: String, completion: @escaping (Int) -> Void) {
        db.collection("drivers")
            .whereField("companyId", isEqualTo: companyId)
            .whereField("isActive", isEqualTo: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching active drivers: \(error)")
                    completion(0)
                    return
                }
                
                let count = snapshot?.documents.count ?? 0
                completion(count)
            }
    }
    
    private func fetchTodaysTripCount(for companyId: String, completion: @escaping (Int) -> Void) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        db.collection("trips")
            .whereField("companyId", isEqualTo: companyId)
            .whereField("pickupTime", isGreaterThanOrEqualTo: today)
            .whereField("pickupTime", isLessThan: tomorrow)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching today's trips: \(error)")
                    completion(0)
                    return
                }
                
                let count = snapshot?.documents.count ?? 0
                completion(count)
            }
    }
    
    private func fetchCompletedTripCount(for companyId: String, completion: @escaping (Int) -> Void) {
        db.collection("trips")
            .whereField("companyId", isEqualTo: companyId)
            .whereField("status", isEqualTo: "completed")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching completed trips: \(error)")
                    completion(0)
                    return
                }
                
                let count = snapshot?.documents.count ?? 0
                completion(count)
            }
    }
    
    // Real-time istatistik güncellemeleri için listener'lar
    func startRealTimeUpdates(for companyId: String) {
        // Araç sayısı listener
        db.collection("vehicles")
            .whereField("companyId", isEqualTo: companyId)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error listening to vehicles: \(error)")
                        return
                    }
                    self?.totalVehicles = snapshot?.documents.count ?? 0
                }
            }
        
        // Aktif şoför sayısı listener
        db.collection("drivers")
            .whereField("companyId", isEqualTo: companyId)
            .whereField("isActive", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error listening to active drivers: \(error)")
                        return
                    }
                    self?.activeDrivers = snapshot?.documents.count ?? 0
                }
            }
        
        // Bugünkü işler listener
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        db.collection("trips")
            .whereField("companyId", isEqualTo: companyId)
            .whereField("pickupTime", isGreaterThanOrEqualTo: today)
            .whereField("pickupTime", isLessThan: tomorrow)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error listening to today's trips: \(error)")
                        return
                    }
                    self?.todaysTrips = snapshot?.documents.count ?? 0
                }
            }
        
        // Tamamlanan işler listener
        db.collection("trips")
            .whereField("companyId", isEqualTo: companyId)
            .whereField("status", isEqualTo: "completed")
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error listening to completed trips: \(error)")
                        return
                    }
                    self?.completedTrips = snapshot?.documents.count ?? 0
                }
            }
    }
    
    func stopRealTimeUpdates() {
        // Listener'ları durdur
        cancellables.removeAll()
    }
}
