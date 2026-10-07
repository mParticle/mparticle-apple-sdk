import SwiftUI
import SizeRoktKit

struct ContentView: View {
    @State private var sdkTriggered = true

    // Embedded placement, which links the kit's SwiftUI layout and the Rokt UI.
    private var layout: MPRoktLayout {
        MPRoktLayout(sdkTriggered: $sdkTriggered, identifier: "size_test", attributes: ["email": "test@example.com"])
    }

    var body: some View {
        VStack {
            Text("Hello, world!")
            layout.roktLayout
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
