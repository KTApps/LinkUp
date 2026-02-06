import SwiftUI
import LinkUpFeature
import FirebaseCore

@main
struct LinkUpApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
