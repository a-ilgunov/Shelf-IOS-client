import SwiftUI

@main
struct ShelfApp: App {
    var body: some Scene {
        WindowGroup {
            ShelfTabs().preferredColorScheme(.light)
        }
    }
}
