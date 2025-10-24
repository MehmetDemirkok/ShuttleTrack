import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignUpView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var companyName = ""
    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Hesap Oluştur")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                VStack(spacing: 15) {
                    TextField("Şirket Adı", text: $companyName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Ad Soyad", text: $displayName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.words)
                    
                    TextField("E-posta", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Şifre", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    SecureField("Şifre Tekrar", text: $confirmPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Button(action: signUp) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text("Hesap Oluştur")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isLoading || companyName.isEmpty || displayName.isEmpty || email.isEmpty || password.isEmpty || password != confirmPassword)
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
    
    private func signUp() {
        isLoading = true
        errorMessage = ""
        
        Auth.auth().createUser(withEmail: email, password: password) { [self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                } else if let user = result?.user {
                    // Kullanıcı oluşturuldu, şimdi şirket ve profil verilerini kaydet
                    self.saveCompanyAndProfileData(user: user)
                }
            }
        }
    }
    
    private func saveCompanyAndProfileData(user: User) {
        let db = Firestore.firestore()
        
        // Şirket verilerini kaydet
        let company = Company(
            id: user.uid,
            name: companyName,
            email: email,
            phone: "",
            address: ""
        )
        
        // Kullanıcı profilini oluştur
        let userProfile = UserProfile(
            userId: user.uid,
            displayName: displayName,
            email: email,
            companyId: user.uid,
            role: .admin
        )
        
        // Firebase'e kaydet
        Task {
            do {
                // Şirket verilerini kaydet
                try await db.collection("companies").document(user.uid).setData(from: company)
                
                // Kullanıcı profilini kaydet
                var profileData = userProfile
                profileData.id = user.uid
                try await db.collection("userProfiles").document(user.uid).setData(from: profileData)
                
                // Kullanıcı adını güncelle
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = displayName
                try await changeRequest.commitChanges()
                
                await MainActor.run {
                    self.isLoading = false
                    self.presentationMode.wrappedValue.dismiss()
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Veriler kaydedilirken hata oluştu: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
