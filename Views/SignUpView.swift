import SwiftUI

struct SignUpView: View {
    @StateObject private var appViewModel = AppViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var fullName = ""
    @State private var phone = ""
    @State private var selectedUserType: UserType = .companyAdmin
    @State private var companyName = ""
    @State private var address = ""
    @State private var licenseNumber = ""
    @State private var driverLicenseNumber = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Başlık
                    VStack(spacing: 10) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Kayıt Ol")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    .padding(.top, 20)
                    
                    // Form
                    VStack(spacing: 15) {
                        // Kullanıcı Tipi Seçimi
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Kullanıcı Tipi")
                                .font(.headline)
                                .foregroundColor(.blue)
                            
                            ForEach(UserType.allCases, id: \.self) { userType in
                                Button(action: {
                                    selectedUserType = userType
                                }) {
                                    HStack {
                                        Image(systemName: userType.icon)
                                            .foregroundColor(selectedUserType == userType ? .white : .blue)
                                            .frame(width: 20)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(userType.displayName)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(selectedUserType == userType ? .white : .primary)
                                            
                                            Text(userType.description)
                                                .font(.caption)
                                                .foregroundColor(selectedUserType == userType ? .white.opacity(0.8) : .secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if selectedUserType == userType {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .padding()
                                    .background(selectedUserType == userType ? Color.blue : Color.gray.opacity(0.1))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(selectedUserType == userType ? Color.blue : Color.clear, lineWidth: 2)
                                    )
                                }
                            }
                        }
                        
                        // Kişisel Bilgiler
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Kişisel Bilgiler")
                                .font(.headline)
                                .foregroundColor(.blue)
                            
                            TextField("Ad Soyad", text: $fullName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            TextField("Telefon", text: $phone)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.phonePad)
                        }
                        
                        // Koşullu Form Alanları
                        if selectedUserType == .companyAdmin {
                            // Şirket Bilgileri
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Şirket Bilgileri")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                
                                TextField("Şirket Adı", text: $companyName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                TextField("Adres", text: $address)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                TextField("Lisans Numarası", text: $licenseNumber)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        } else if selectedUserType == .driver {
                            // Sürücü Bilgileri
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Sürücü Bilgileri")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                
                                TextField("Ehliyet Numarası", text: $driverLicenseNumber)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                        
                        Divider()
                        
                        // Hesap Bilgileri
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Hesap Bilgileri")
                                .font(.headline)
                                .foregroundColor(.blue)
                            
                            TextField("E-posta", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                            
                            SecureField("Şifre", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            SecureField("Şifre Tekrar", text: $confirmPassword)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        if appViewModel.isLoading {
                            ProgressView("Kayıt oluşturuluyor...")
                                .frame(maxWidth: .infinity)
                        } else {
                            Button("Kayıt Ol") {
                                Task {
                                    await signUp()
                                }
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(!isFormValid)
                        }
                        
                        if let errorMessage = appViewModel.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        
                        // E-posta doğrulama uyarısı
                        if appViewModel.isAuthenticated && !appViewModel.isEmailVerified {
                            VStack(spacing: 10) {
                                Text("⚠️ E-posta Doğrulama Gerekli")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                                
                                Text("Hesabınızı aktifleştirmek için e-posta adresinize gönderilen doğrulama bağlantısına tıklayın.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                Button("Doğrulama E-postası Tekrar Gönder") {
                                    Task {
                                        await appViewModel.sendEmailVerification()
                                    }
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("İptal") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private var isFormValid: Bool {
        let basicValidation = !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        !fullName.isEmpty &&
        !phone.isEmpty &&
        password == confirmPassword &&
        password.count >= 6
        
        if selectedUserType == .companyAdmin {
            return basicValidation &&
            !companyName.isEmpty &&
            !address.isEmpty &&
            !licenseNumber.isEmpty
        } else if selectedUserType == .driver {
            return basicValidation &&
            !driverLicenseNumber.isEmpty
        }
        
        return basicValidation
    }
    
    private func signUp() async {
        if selectedUserType == .companyAdmin {
            let company = Company(
                name: companyName,
                email: email,
                phone: phone,
                address: address,
                licenseNumber: licenseNumber
            )
            
            await appViewModel.signUp(email: email, password: password, company: company, userType: selectedUserType, fullName: fullName)
        } else if selectedUserType == .driver {
            await appViewModel.signUp(email: email, password: password, company: nil, userType: selectedUserType, fullName: fullName, driverLicenseNumber: driverLicenseNumber)
        }
        
        if appViewModel.isAuthenticated {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
