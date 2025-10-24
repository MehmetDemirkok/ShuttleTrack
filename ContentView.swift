import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Araç Takip Sistemi")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            Text("Havalimanı Transfer Yönetimi")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
