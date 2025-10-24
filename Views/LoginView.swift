import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @StateObject private var appViewModel = AppViewModel()
    @State private var email = ""
    @State private var password = ""
    @State private var showingSignUp = false
    @State private var showingPasswordReset = false
    @State private var showingPhoneLogin = false
    @State private var phoneNumber = ""
    @State private var otpCode = ""
    @State private var showingOTP = false
    @State private var currentNonce: String?
    
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
                    
                    // Parola Sıfırlama
                    Button("Şifremi Unuttum") {
                        showingPasswordReset = true
                    }
                    .font(.footnote)
                    .foregroundColor(.blue)
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                // Alternatif Giriş Yöntemleri
                VStack(spacing: 15) {
                    // Apple ile Giriş
                    SignInWithAppleButton(
                        onRequest: { request in
                            currentNonce = appViewModel.randomNonceString()
                            request.requestedScopes = [.fullName, .email]
                            request.nonce = appViewModel.sha256(currentNonce!)
                        },
                        onCompletion: { result in
                            switch result {
                            case .success(let authResults):
                                switch authResults.credential {
                                case let appleIDCredential as ASAuthorizationAppleIDCredential:
                                    guard let nonce = currentNonce else {
                                        fatalError("Invalid state: A login callback was received, but no login request was sent.")
                                    }
                                    
                                    guard let appleIDToken = appleIDCredential.identityToken else {
                                        fatalError("Invalid state: A login callback was received, but no login request was sent.")
                                    }
                                    
                                    guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                                        print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                                        return
                                    }
                                    
                                    Task {
                                        await appViewModel.signInWithApple(idToken: idTokenString, nonce: nonce)
                                    }
                                default:
                                    break
                                }
                            case .failure(let error):
                                print("Apple Sign In failed: \(error.localizedDescription)")
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(10)
                    
                    // Telefon ile Giriş
                    Button("Telefon ile Giriş") {
                        showingPhoneLogin = true
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    
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
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingSignUp) {
            SignUpView()
        }
        .sheet(isPresented: $showingPasswordReset) {
            PasswordResetView()
        }
        .sheet(isPresented: $showingPhoneLogin) {
            PhoneLoginView(phoneNumber: $phoneNumber, showingOTP: $showingOTP)
        }
        .sheet(isPresented: $showingOTP) {
            OTPVerificationView(phoneNumber: phoneNumber, otpCode: $otpCode)
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

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.blue)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.blue, lineWidth: 1)
            )
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
