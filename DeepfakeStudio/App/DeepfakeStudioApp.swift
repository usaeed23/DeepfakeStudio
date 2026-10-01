import SwiftUI

@main
struct DeepfakeStudioApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}

struct ContentView: View {
    @StateObject private var camera = LiveCameraViewModel()

    var body: some View {
        NavigationStack {
            LiveCameraView(camera: camera)
                .navigationTitle("Live Studio")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}
