import SwiftUI

struct LoginView: View {
    @StateObject private var appViewModel = AppViewModel()
    @State private var email = ""
    @State private var password = ""
    @State private var showingSignUp = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Logo ve Başlık
                VStack(spacing: 10) {
                    Image(systemName: "car.2.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Araç Takip Sistemi")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Havalimanı Transfer Yönetimi")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 50)
                
                Spacer()
                
                // Giriş Formu
                VStack(spacing: 15) {
                    TextField("E-posta", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Şifre", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    if appViewModel.isLoading {
                        ProgressView("Giriş yapılıyor...")
                            .frame(maxWidth: .infinity)
                    } else {
                        Button("Giriş Yap") {
                            Task {
                                await appViewModel.signIn(email: email, password: password)
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    
                    if let errorMessage = appViewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                // Kayıt Ol Linki
                HStack {
                    Text("Hesabınız yok mu?")
                    Button("Kayıt Ol") {
                        showingSignUp = true
                    }
                    .foregroundColor(.blue)
                }
                .font(.footnote)
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingSignUp) {
            SignUpView()
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
