import Foundation
import FirebaseFirestore
import Combine

@MainActor
class StatisticsService: ObservableObject {
    @Published var totalVehicles = 0
    @Published var activeDrivers = 0
    @Published var todaysTrips = 0
    @Published var completedTrips = 0
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private var listeners: [ListenerRegistration] = []
    
    func fetchStatistics(for companyId: String) {
        print("📊 İstatistikler yükleniyor - Company ID: \(companyId)")
        isLoading = true
        errorMessage = ""
        
        // Tüm istatistikleri paralel olarak çek
        let group = DispatchGroup()
        
        // Araç sayısı
        group.enter()
        print("🚗 Araç sayısı sorgusu başlatılıyor...")
        fetchVehicleCount(for: companyId) { [weak self] count in
            DispatchQueue.main.async {
                print("🚗 Araç sayısı sonucu: \(count)")
                self?.totalVehicles = count
                group.leave()
            }
        }
        
        // Aktif sürücü sayısı
        group.enter()
        print("👨‍💼 Aktif sürücü sayısı sorgusu başlatılıyor...")
        fetchActiveDriverCount(for: companyId) { [weak self] count in
            DispatchQueue.main.async {
                print("👨‍💼 Aktif sürücü sayısı sonucu: \(count)")
                self?.activeDrivers = count
                group.leave()
            }
        }
        
        // Bugünkü işler
        group.enter()
        print("📅 Bugünkü işler sorgusu başlatılıyor...")
        fetchTodaysTripCount(for: companyId) { [weak self] count in
            DispatchQueue.main.async {
                print("📅 Bugünkü işler sonucu: \(count)")
                self?.todaysTrips = count
                group.leave()
            }
        }
        
        // Tamamlanan işler
        group.enter()
        print("✅ Tamamlanan işler sorgusu başlatılıyor...")
        fetchCompletedTripCount(for: companyId) { [weak self] count in
            DispatchQueue.main.async {
                print("✅ Tamamlanan işler sonucu: \(count)")
                self?.completedTrips = count
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            print("📊 İstatistikler yüklendi - Araç: \(self?.totalVehicles ?? 0), Sürücü: \(self?.activeDrivers ?? 0), Bugün: \(self?.todaysTrips ?? 0), Tamamlanan: \(self?.completedTrips ?? 0)")
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
        print("👨‍💼 Aktif sürücü sorgusu - Company ID: \(companyId)")
        db.collection("drivers")
            .whereField("companyId", isEqualTo: companyId)
            .whereField("isActive", isEqualTo: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Aktif sürücü yüklenirken hata: \(error.localizedDescription)")
                    completion(0)
                    return
                }
                
                let count = snapshot?.documents.count ?? 0
                print("👨‍💼 Aktif sürücü sayısı başarıyla yüklendi: \(count)")
                completion(count)
            }
    }
    
    private func fetchTodaysTripCount(for companyId: String, completion: @escaping (Int) -> Void) {
        print("📅 Bugünkü işler sorgusu - Company ID: \(companyId)")
        // Index gerektirmeyen basit sorgu
        db.collection("trips")
            .whereField("companyId", isEqualTo: companyId)
            .limit(to: 50) // Maksimum 50 trip
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Bugünkü işler yüklenirken hata: \(error.localizedDescription)")
                    completion(0)
                    return
                }
                
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
                
                print("📅 Bugünkü tarih aralığı: \(today) - \(tomorrow)")
                
                // Client-side filtering
                let allTrips = snapshot?.documents.compactMap { document in
                    try? document.data(as: Trip.self)
                } ?? []
                
                print("📅 Toplam trip sayısı: \(allTrips.count)")
                
                let todaysTrips = allTrips.filter { trip in
                    trip.pickupTime >= today && trip.pickupTime < tomorrow
                }.count
                
                print("📅 Bugünkü işler sayısı: \(todaysTrips)")
                completion(todaysTrips)
            }
    }
    
    private func fetchCompletedTripCount(for companyId: String, completion: @escaping (Int) -> Void) {
        print("✅ Tamamlanan işler sorgusu - Company ID: \(companyId)")
        // Index gerektirmeyen basit sorgu
        db.collection("trips")
            .whereField("companyId", isEqualTo: companyId)
            .limit(to: 50) // Maksimum 50 trip
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Tamamlanan işler yüklenirken hata: \(error.localizedDescription)")
                    completion(0)
                    return
                }
                
                // Client-side filtering
                let allTrips = snapshot?.documents.compactMap { document in
                    try? document.data(as: Trip.self)
                } ?? []
                
                print("✅ Toplam trip sayısı: \(allTrips.count)")
                
                let completedTrips = allTrips.filter { trip in
                    trip.status == .completed
                }.count
                
                print("✅ Tamamlanan işler sayısı: \(completedTrips)")
                completion(completedTrips)
            }
    }
    
    // Real-time istatistik güncellemeleri için listener'lar
    func startRealTimeUpdates(for companyId: String) {
        print("🔄 Real-time istatistik güncellemeleri başlatılıyor - Company ID: \(companyId)")
        
        // Önceki listener'ları temizle
        stopRealTimeUpdates()
        
        // Araç sayısı listener
        let vehicleListener = db.collection("vehicles")
            .whereField("companyId", isEqualTo: companyId)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Error listening to vehicles: \(error)")
                        self?.errorMessage = "Araç verileri güncellenemedi: \(error.localizedDescription)"
                        return
                    }
                    let count = snapshot?.documents.count ?? 0
                    print("🚗 Real-time araç sayısı güncellendi: \(count)")
                    self?.totalVehicles = count
                }
            }
        listeners.append(vehicleListener)
        
        // Aktif sürücü sayısı listener
        let driverListener = db.collection("drivers")
            .whereField("companyId", isEqualTo: companyId)
            .whereField("isActive", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Error listening to active drivers: \(error)")
                        self?.errorMessage = "Sürücü verileri güncellenemedi: \(error.localizedDescription)"
                        return
                    }
                    let count = snapshot?.documents.count ?? 0
                    print("👨‍💼 Real-time aktif sürücü sayısı güncellendi: \(count)")
                    self?.activeDrivers = count
                }
            }
        listeners.append(driverListener)
        
        // Bugünkü işler listener - Company ID filtresi eklendi
        let todaysTripsListener = db.collection("trips")
            .whereField("companyId", isEqualTo: companyId)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Error listening to today's trips: \(error)")
                        self?.errorMessage = "Bugünkü işler güncellenemedi: \(error.localizedDescription)"
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
                    
                    print("📅 Real-time bugünkü işler güncellendi: \(todaysTrips)")
                    self?.todaysTrips = todaysTrips
                }
            }
        listeners.append(todaysTripsListener)
        
        // Tamamlanan işler listener
        let completedTripsListener = db.collection("trips")
            .whereField("companyId", isEqualTo: companyId)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Error listening to completed trips: \(error)")
                        self?.errorMessage = "Tamamlanan işler güncellenemedi: \(error.localizedDescription)"
                        return
                    }
                    
                    let completedTrips = snapshot?.documents.compactMap { document in
                        try? document.data(as: Trip.self)
                    }.filter { trip in
                        trip.status == .completed
                    }.count ?? 0
                    
                    print("✅ Real-time tamamlanan işler güncellendi: \(completedTrips)")
                    self?.completedTrips = completedTrips
                }
            }
        listeners.append(completedTripsListener)
        
        print("✅ Real-time listener'lar başlatıldı - Toplam: \(listeners.count)")
    }
    
    func stopRealTimeUpdates() {
        print("🛑 Real-time listener'lar durduruluyor...")
        // Listener'ları durdur
        for listener in listeners {
            listener.remove()
        }
        listeners.removeAll()
        cancellables.removeAll()
        print("✅ Real-time listener'lar durduruldu")
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
    
    // Deinitializer - Memory leak önleme
    deinit {
        Task { @MainActor in
            stopRealTimeUpdates()
        }
    }
}
