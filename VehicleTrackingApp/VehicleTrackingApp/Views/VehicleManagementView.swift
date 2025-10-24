import SwiftUI

struct VehicleManagementView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Araç Yönetimi")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                Text("Araç listesi burada görünecek")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Araçlar")
        }
    }
}

struct VehicleManagementView_Previews: PreviewProvider {
    static var previews: some View {
        VehicleManagementView()
    }
}
