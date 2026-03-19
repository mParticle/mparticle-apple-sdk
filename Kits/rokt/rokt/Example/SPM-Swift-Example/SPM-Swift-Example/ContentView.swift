import SwiftUI
import Rokt_Widget

struct ContentView: View {
    @State private var sdkTriggered = false

    private let attributes: [String: String] = [
        "email": "jenny.smith@rokt.com",
        "firstname": "Jenny",
        "lastname": "Smith",
        "confirmationref": "ORDER-12345",
        "billingzipcode": "10014",
        "sandbox": "true"
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 56))
                        .foregroundColor(Color(hex: "#C20075"))
                    Text("Order Confirmed")
                        .font(.title.bold())
                    Text("Reference: ORDER-12345")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)

                Button("Load Rokt Placement") {
                    sdkTriggered = true
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "#C20075"))
                .disabled(sdkTriggered)

                RoktLayout(
                    sdkTriggered: $sdkTriggered,
                    identifier: "MSDKOverlayLayout",
                    attributes: attributes
                )
                .padding(.horizontal)

                Spacer()
            }
            .padding()
        }
    }
}

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF)/255
        let g = Double((int >> 8) & 0xFF)/255
        let b = Double(int & 0xFF)/255
        self.init(red: r, green: g, blue: b)
    }
}
