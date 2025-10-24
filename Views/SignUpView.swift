import SwiftUI

struct SignUpView: View {
    @StateObject private var appViewModel = AppViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var companyName = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var licenseNumber = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Başlık
                    VStack(spacing: 10) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Şirket Kaydı")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    .padding(.top, 20)
                    
                    // Form
                    VStack(spacing: 15) {
                        // Şirket Bilgileri
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Şirket Bilgileri")
                                .font(.headline)
                                .foregroundColor(.blue)
                            
                            TextField("Şirket Adı", text: $companyName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            TextField("Telefon", text: $phone)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.phonePad)
                            
                            TextField("Adres", text: $address)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            TextField("Lisans Numarası", text: $licenseNumber)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
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
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        !companyName.isEmpty &&
        !phone.isEmpty &&
        !address.isEmpty &&
        !licenseNumber.isEmpty &&
        password == confirmPassword &&
        password.count >= 6
    }
    
    private func signUp() async {
        let company = Company(
            name: companyName,
            email: email,
            phone: phone,
            address: address,
            licenseNumber: licenseNumber
        )
        
        await appViewModel.signUp(email: email, password: password, company: company)
        
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
