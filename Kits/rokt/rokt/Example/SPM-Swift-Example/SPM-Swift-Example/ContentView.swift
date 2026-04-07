import SwiftUI
import mParticle_Rokt_Swift
import Rokt_Widget
import mParticle_Apple_SDK

struct ContentView: View {
    @State private var sdkTriggered = false
    @State private var bottomsheetTriggered = false
    @State private var eventLog: [String] = []

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

                MPRoktLayout(
                    sdkTriggered: $sdkTriggered,
                    identifier: "MSDKOverlayLayout",
                    attributes: attributes
                ).roktLayout

                Button("Load Bottomsheet Placement") {
                    bottomsheetTriggered = true
                    MParticle.sharedInstance().rokt.events("MSDKBottomsheetLayout") { event in
                        let description = describeEvent(event)
                        print("RoktEvent: \(description)")
                        DispatchQueue.main.async {
                            eventLog.append(description)
                        }
                    }
                    MParticle.sharedInstance().rokt.selectPlacements(
                        "MSDKBottomsheetLayout",
                        attributes: attributes,
                        embeddedViews: nil,
                        config: nil,
                        onEvent: nil
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "#5A2D82"))
                .disabled(bottomsheetTriggered)

                if !eventLog.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Event Log")
                            .font(.headline)
                        ForEach(eventLog.reversed(), id: \.self) { entry in
                            Text(entry)
                                .font(.system(.caption, design: .monospaced))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }

                Spacer()
            }
            .padding()
        }
    }

    private func describeEvent(_ event: RoktEvent) -> String {
        switch event {
        case is RoktEvent.ShowLoadingIndicator:
            return "ShowLoadingIndicator"
        case is RoktEvent.HideLoadingIndicator:
            return "HideLoadingIndicator"
        case let e as RoktEvent.PlacementReady:
            return "PlacementReady - \(e.identifier ?? "")"
        case let e as RoktEvent.PlacementInteractive:
            return "PlacementInteractive - \(e.identifier ?? "")"
        case let e as RoktEvent.OfferEngagement:
            return "OfferEngagement - \(e.identifier ?? "")"
        case let e as RoktEvent.PositiveEngagement:
            return "PositiveEngagement - \(e.identifier ?? "")"
        case let e as RoktEvent.FirstPositiveEngagement:
            return "FirstPositiveEngagement - \(e.identifier ?? "")"
        case let e as RoktEvent.OpenUrl:
            return "OpenUrl - \(e.url)"
        case let e as RoktEvent.PlacementClosed:
            return "PlacementClosed - \(e.identifier ?? "")"
        case let e as RoktEvent.PlacementCompleted:
            return "PlacementCompleted - \(e.identifier ?? "")"
        case let e as RoktEvent.PlacementFailure:
            return "PlacementFailure - \(e.identifier ?? "")"
        default:
            return "\(type(of: event))"
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
