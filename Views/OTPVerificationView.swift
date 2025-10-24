import SwiftUI

struct OTPVerificationView: View {
    @StateObject private var appViewModel = AppViewModel()
    @Environment(\.presentationMode) var presentationMode
    let phoneNumber: String
    @Binding var otpCode: String
    @State private var timeRemaining = 60
    @State private var timer: Timer?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Başlık
                VStack(spacing: 10) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("Doğrulama Kodu")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("\(phoneNumber) numarasına gönderilen 6 haneli kodu girin")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Form
                VStack(spacing: 15) {
                    TextField("Doğrulama Kodu", text: $otpCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(.title2)
                        .onChange(of: otpCode) { newValue in
                            if newValue.count == 6 {
                                Task {
                                    await appViewModel.confirmOTP(code: newValue)
                                    if appViewModel.errorMessage == nil {
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                }
                            }
                        }
                    
                    if appViewModel.isLoading {
                        ProgressView("Doğrulanıyor...")
                            .frame(maxWidth: .infinity)
                    } else {
                        Button("Doğrula") {
                            Task {
                                await appViewModel.confirmOTP(code: otpCode)
                                if appViewModel.errorMessage == nil {
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(otpCode.count != 6)
                    }
                    
                    // Yeniden gönder
                    if timeRemaining > 0 {
                        Text("Kodu yeniden gönderebilmek için \(timeRemaining) saniye bekleyin")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Button("Kodu Yeniden Gönder") {
                            Task {
                                await appViewModel.startPhoneSignIn(phoneNumber: phoneNumber)
                                timeRemaining = 60
                                startTimer()
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
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
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer?.invalidate()
            }
        }
    }
}

struct OTPVerificationView_Previews: PreviewProvider {
    static var previews: some View {
        OTPVerificationView(phoneNumber: "+905551234567", otpCode: .constant(""))
    }
}

