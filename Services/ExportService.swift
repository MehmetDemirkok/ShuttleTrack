import Foundation
import SwiftUI
import PDFKit

class ExportService: ObservableObject {
    @Published var isExporting = false
    @Published var exportError: String?
    
    // MARK: - Excel Export (CSV Format)
    func exportTripsToExcel(_ trips: [Trip]) async -> URL? {
        isExporting = true
        exportError = nil
        
        do {
            let csvContent = generateCSVContent(for: trips)
            let fileName = "isler_\(Date().formatted(.dateTime.day().month().year()))"
            let url = try saveCSVToFile(csvContent, fileName: fileName)
            isExporting = false
            return url
        } catch {
            exportError = "Excel export hatası: \(error.localizedDescription)"
            isExporting = false
            return nil
        }
    }
    
    // MARK: - PDF Export
    func exportTripsToPDF(_ trips: [Trip]) async -> URL? {
        isExporting = true
        exportError = nil
        
        do {
            let pdfData = try generatePDFContent(for: trips)
            let fileName = "isler_\(Date().formatted(.dateTime.day().month().year()))"
            let url = try savePDFToFile(pdfData, fileName: fileName)
            isExporting = false
            return url
        } catch {
            exportError = "PDF export hatası: \(error.localizedDescription)"
            isExporting = false
            return nil
        }
    }
    
    // MARK: - CSV Generation
    private func generateCSVContent(for trips: [Trip]) -> String {
        var csvContent = "İş No,Alış Noktası,Varış Noktası,Kalkış Zamanı,Varış Zamanı,Yolcu Sayısı,Durum,Ücret,Notlar\n"
        
        for trip in trips {
            let pickupLocation = trip.pickupLocation.name.replacingOccurrences(of: ",", with: ";")
            let dropoffLocation = trip.dropoffLocation.name.replacingOccurrences(of: ",", with: ";")
            let pickupTime = trip.scheduledPickupTime.formatted(.dateTime.day().month().year().hour().minute())
            let dropoffTime = trip.scheduledDropoffTime.formatted(.dateTime.day().month().year().hour().minute())
            let status = statusText(trip.status)
            let fare = trip.fare?.formatted() ?? ""
            let notes = (trip.notes ?? "").replacingOccurrences(of: ",", with: ";")
            
            csvContent += "\(trip.tripNumber),\(pickupLocation),\(dropoffLocation),\(pickupTime),\(dropoffTime),\(trip.passengerCount),\(status),\(fare),\(notes)\n"
        }
        
        return csvContent
    }
    
    // MARK: - PDF Generation
    private func generatePDFContent(for trips: [Trip]) throws -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "Araç Takip Sistemi",
            kCGPDFContextAuthor: "Şirket Yönetim Sistemi",
            kCGPDFContextTitle: "İş Listesi Raporu"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            // Başlık
            let title = "İş Listesi Raporu"
            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.black
            ]
            let titleSize = title.size(withAttributes: titleAttributes)
            let titleRect = CGRect(x: (pageWidth - titleSize.width) / 2, y: 50, width: titleSize.width, height: titleSize.height)
            title.draw(in: titleRect, withAttributes: titleAttributes)
            
            // Tarih
            let dateString = "Rapor Tarihi: \(Date().formatted(.dateTime.day().month().year().hour().minute()))"
            let dateFont = UIFont.systemFont(ofSize: 14)
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: dateFont,
                .foregroundColor: UIColor.gray
            ]
            let dateSize = dateString.size(withAttributes: dateAttributes)
            let dateRect = CGRect(x: (pageWidth - dateSize.width) / 2, y: titleRect.maxY + 10, width: dateSize.width, height: dateSize.height)
            dateString.draw(in: dateRect, withAttributes: dateAttributes)
            
            // İş listesi
            var yPosition: CGFloat = dateRect.maxY + 30
            let lineHeight: CGFloat = 20
            let leftMargin: CGFloat = 50
            let rightMargin: CGFloat = 50
            let contentWidth = pageWidth - leftMargin - rightMargin
            
            for (index, trip) in trips.enumerated() {
                if yPosition + lineHeight * 6 > pageHeight - 50 {
                    context.beginPage()
                    yPosition = 50
                }
                
                // İş numarası
                let tripNumber = "İş #\(trip.tripNumber)"
                let tripNumberFont = UIFont.boldSystemFont(ofSize: 16)
                let tripNumberAttributes: [NSAttributedString.Key: Any] = [
                    .font: tripNumberFont,
                    .foregroundColor: UIColor.blue
                ]
                tripNumber.draw(in: CGRect(x: leftMargin, y: yPosition, width: contentWidth, height: lineHeight), withAttributes: tripNumberAttributes)
                yPosition += lineHeight
                
                // Rota bilgisi
                let routeInfo = "\(trip.pickupLocation.name) → \(trip.dropoffLocation.name)"
                let routeFont = UIFont.systemFont(ofSize: 14)
                let routeAttributes: [NSAttributedString.Key: Any] = [
                    .font: routeFont,
                    .foregroundColor: UIColor.black
                ]
                routeInfo.draw(in: CGRect(x: leftMargin, y: yPosition, width: contentWidth, height: lineHeight), withAttributes: routeAttributes)
                yPosition += lineHeight
                
                // Zaman bilgisi
                let timeInfo = "Kalkış: \(trip.scheduledPickupTime.formatted(.dateTime.day().month().year().hour().minute())) | Varış: \(trip.scheduledDropoffTime.formatted(.dateTime.day().month().year().hour().minute()))"
                let timeFont = UIFont.systemFont(ofSize: 12)
                let timeAttributes: [NSAttributedString.Key: Any] = [
                    .font: timeFont,
                    .foregroundColor: UIColor.gray
                ]
                timeInfo.draw(in: CGRect(x: leftMargin, y: yPosition, width: contentWidth, height: lineHeight), withAttributes: timeAttributes)
                yPosition += lineHeight
                
                // Yolcu sayısı ve durum
                let passengerInfo = "Yolcu Sayısı: \(trip.passengerCount) | Durum: \(statusText(trip.status))"
                let passengerFont = UIFont.systemFont(ofSize: 12)
                let passengerAttributes: [NSAttributedString.Key: Any] = [
                    .font: passengerFont,
                    .foregroundColor: UIColor.darkGray
                ]
                passengerInfo.draw(in: CGRect(x: leftMargin, y: yPosition, width: contentWidth, height: lineHeight), withAttributes: passengerAttributes)
                yPosition += lineHeight
                
                // Ücret bilgisi
                if let fare = trip.fare {
                    let fareInfo = "Ücret: \(fare.formatted(.currency(code: "TRY")))"
                    let fareFont = UIFont.boldSystemFont(ofSize: 12)
                    let fareAttributes: [NSAttributedString.Key: Any] = [
                        .font: fareFont,
                        .foregroundColor: UIColor.green
                    ]
                    fareInfo.draw(in: CGRect(x: leftMargin, y: yPosition, width: contentWidth, height: lineHeight), withAttributes: fareAttributes)
                    yPosition += lineHeight
                }
                
                // Notlar
                if let notes = trip.notes, !notes.isEmpty {
                    let notesInfo = "Notlar: \(notes)"
                    let notesFont = UIFont.italicSystemFont(ofSize: 12)
                    let notesAttributes: [NSAttributedString.Key: Any] = [
                        .font: notesFont,
                        .foregroundColor: UIColor.darkGray
                    ]
                    notesInfo.draw(in: CGRect(x: leftMargin, y: yPosition, width: contentWidth, height: lineHeight), withAttributes: notesAttributes)
                    yPosition += lineHeight
                }
                
                yPosition += 10 // Boşluk
            }
        }
        
        return data
    }
    
    // MARK: - File Operations
    private func saveCSVToFile(_ content: String, fileName: String) throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent("\(fileName).csv")
        
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
    
    private func savePDFToFile(_ data: Data, fileName: String) throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent("\(fileName).pdf")
        
        try data.write(to: fileURL)
        return fileURL
    }
    
    // MARK: - Helper Methods
    private func statusText(_ status: Trip.TripStatus) -> String {
        switch status {
        case .scheduled: return "Planlandı"
        case .assigned: return "Atandı"
        case .inProgress: return "Devam Ediyor"
        case .completed: return "Tamamlandı"
        case .cancelled: return "İptal"
        }
    }
}
