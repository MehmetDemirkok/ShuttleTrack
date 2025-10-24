import SwiftUI

struct PhoneLoginView: View {
    @StateObject private var appViewModel = AppViewModel()
    @Environment(\.presentationMode) var presentationMode
    @Binding var phoneNumber: String
    @Binding var showingOTP: Bool
    @State private var formattedPhoneNumber = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Başlık
                VStack(spacing: 10) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("Telefon ile Giriş")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Telefon numaranıza gönderilen doğrulama kodunu girin")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Form
                VStack(spacing: 15) {
                    TextField("Telefon Numarası", text: $phoneNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.phonePad)
                        .onChange(of: phoneNumber) { newValue in
                            formattedPhoneNumber = formatPhoneNumber(newValue)
                        }
                    
                    if appViewModel.isLoading {
                        ProgressView("Kod gönderiliyor...")
                            .frame(maxWidth: .infinity)
                    } else {
                        Button("Doğrulama Kodu Gönder") {
                            Task {
                                await appViewModel.startPhoneSignIn(phoneNumber: formattedPhoneNumber)
                                if appViewModel.errorMessage == nil {
                                    showingOTP = true
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(phoneNumber.isEmpty)
                    }
                    
                    if let errorMessage = appViewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("İptal") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func formatPhoneNumber(_ phoneNumber: String) -> String {
        let cleaned = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        if cleaned.hasPrefix("90") {
            return "+\(cleaned)"
        } else if cleaned.hasPrefix("0") {
            return "+90\(String(cleaned.dropFirst()))"
        } else if !cleaned.isEmpty {
            return "+90\(cleaned)"
        }
        
        return phoneNumber
    }
}

struct PhoneLoginView_Previews: PreviewProvider {
    static var previews: some View {
        PhoneLoginView(phoneNumber: .constant(""), showingOTP: .constant(false))
    }
}

