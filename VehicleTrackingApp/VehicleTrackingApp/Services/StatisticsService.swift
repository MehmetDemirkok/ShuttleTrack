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
        print("📊 İstatistikler yükleniyor - Company ID: \(companyId)")
        isLoading = true
        errorMessage = ""
        
        // Tüm istatistikleri paralel olarak çek
        let group = DispatchGroup()
        
        // Araç sayısı
        group.enter()
        fetchVehicleCount(for: companyId) { [weak self] count in
            DispatchQueue.main.async {
                print("🚗 Araç sayısı: \(count)")
                self?.totalVehicles = count
                group.leave()
            }
        }
        
        // Aktif şoför sayısı
        group.enter()
        fetchActiveDriverCount(for: companyId) { [weak self] count in
            DispatchQueue.main.async {
                print("👨‍💼 Aktif şoför sayısı: \(count)")
                self?.activeDrivers = count
                group.leave()
            }
        }
        
        // Bugünkü işler
        group.enter()
        fetchTodaysTripCount(for: companyId) { [weak self] count in
            DispatchQueue.main.async {
                print("📅 Bugünkü işler: \(count)")
                self?.todaysTrips = count
                group.leave()
            }
        }
        
        // Tamamlanan işler
        group.enter()
        fetchCompletedTripCount(for: companyId) { [weak self] count in
            DispatchQueue.main.async {
                print("✅ Tamamlanan işler: \(count)")
                self?.completedTrips = count
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            print("📊 İstatistikler yüklendi - Araç: \(self?.totalVehicles ?? 0), Şoför: \(self?.activeDrivers ?? 0), Bugün: \(self?.todaysTrips ?? 0), Tamamlanan: \(self?.completedTrips ?? 0)")
            self?.isLoading = false
        }
    }
    
    private func fetchVehicleCount(for companyId: String, completion: @escaping (Int) -> Void) {
        db.collection("vehicles")
            .whereField("companyId", isEqualTo: companyId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Araç sayısı yüklenirken hata: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.errorMessage = "Araç verileri yüklenemedi: \(error.localizedDescription)"
                    }
                    completion(0)
                    return
                }
                
                let count = snapshot?.documents.count ?? 0
                print("🚗 Araç sayısı başarıyla yüklendi: \(count)")
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
        // Index gerektirmeyen yaklaşım: Tüm trip'leri çek ve client-side filtrele
        db.collection("trips")
            .whereField("companyId", isEqualTo: companyId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching trips: \(error)")
                    completion(0)
                    return
                }
                
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
                
                let todaysTrips = snapshot?.documents.compactMap { document in
                    try? document.data(as: Trip.self)
                }.filter { trip in
                    trip.pickupTime >= today && trip.pickupTime < tomorrow
                }.count ?? 0
                
                completion(todaysTrips)
            }
    }
    
    private func fetchCompletedTripCount(for companyId: String, completion: @escaping (Int) -> Void) {
        // Index gerektirmeyen yaklaşım: Tüm trip'leri çek ve client-side filtrele
        db.collection("trips")
            .whereField("companyId", isEqualTo: companyId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching trips: \(error)")
                    completion(0)
                    return
                }
                
                let completedTrips = snapshot?.documents.compactMap { document in
                    try? document.data(as: Trip.self)
                }.filter { trip in
                    trip.status == .completed
                }.count ?? 0
                
                completion(completedTrips)
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
        
        // Bugünkü işler listener - Index gerektirmeyen yaklaşım
        db.collection("trips")
            .whereField("companyId", isEqualTo: companyId)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error listening to trips: \(error)")
                        return
                    }
                    
                    let calendar = Calendar.current
                    let today = calendar.startOfDay(for: Date())
                    let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
                    
                    let todaysTrips = snapshot?.documents.compactMap { document in
                        try? document.data(as: Trip.self)
                    }.filter { trip in
                        trip.pickupTime >= today && trip.pickupTime < tomorrow
                    }.count ?? 0
                    
                    self?.todaysTrips = todaysTrips
                }
            }
        
        // Tamamlanan işler listener - Index gerektirmeyen yaklaşım
        db.collection("trips")
            .whereField("companyId", isEqualTo: companyId)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error listening to trips: \(error)")
                        return
                    }
                    
                    let completedTrips = snapshot?.documents.compactMap { document in
                        try? document.data(as: Trip.self)
                    }.filter { trip in
                        trip.status == .completed
                    }.count ?? 0
                    
                    self?.completedTrips = completedTrips
                }
            }
    }
    
    func stopRealTimeUpdates() {
        // Listener'ları durdur
        cancellables.removeAll()
    }
    
    // İstatistikleri manuel olarak yenile
    func refreshStatistics(for companyId: String) {
        print("🔄 İstatistikler yenileniyor...")
        fetchStatistics(for: companyId)
    }
    
    // Hata mesajını temizle
    func clearError() {
        errorMessage = ""
    }
}
