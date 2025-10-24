import SwiftUI

struct PasswordResetView: View {
    @StateObject private var appViewModel = AppViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var email = ""
    @State private var showingSuccess = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Başlık
                VStack(spacing: 10) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("Şifre Sıfırlama")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("E-posta adresinize şifre sıfırlama bağlantısı gönderilecek")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Form
                VStack(spacing: 15) {
                    TextField("E-posta", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    if appViewModel.isLoading {
                        ProgressView("Gönderiliyor...")
                            .frame(maxWidth: .infinity)
                    } else {
                        Button("Şifre Sıfırlama Bağlantısı Gönder") {
                            Task {
                                await appViewModel.sendPasswordReset(email: email)
                                if appViewModel.errorMessage == nil {
                                    showingSuccess = true
                                }
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(email.isEmpty)
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
        .alert("Başarılı", isPresented: $showingSuccess) {
            Button("Tamam") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Şifre sıfırlama bağlantısı e-posta adresinize gönderildi.")
        }
    }
}

struct PasswordResetView_Previews: PreviewProvider {
    static var previews: some View {
        PasswordResetView()
    }
}
