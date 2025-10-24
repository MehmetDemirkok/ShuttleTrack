import SwiftUI

struct TripAssignmentView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("İş Atama")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                Text("Transfer işleri burada görünecek")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("İşler")
        }
    }
}

struct TripAssignmentView_Previews: PreviewProvider {
    static var previews: some View {
        TripAssignmentView()
    }
}
