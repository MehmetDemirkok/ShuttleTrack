import SwiftUI

struct DriverManagementView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Şoför Yönetimi")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                Text("Şoför listesi burada görünecek")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Şoförler")
        }
    }
}

struct DriverManagementView_Previews: PreviewProvider {
    static var previews: some View {
        DriverManagementView()
    }
}
