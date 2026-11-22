import SwiftUI

@main
struct ShelfApp: App {
    private let profiles: any ProfileService = MockProfileService()

    var body: some Scene {
        WindowGroup {
            ShelfTabs(profiles: profiles).preferredColorScheme(.light)
        }
    }
}
