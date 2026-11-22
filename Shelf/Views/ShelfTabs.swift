import SwiftUI
import UIKit

enum ShelfTab: String, CaseIterable {
    case catalog = "Лента", search = "Поиск", messages = "Сообщения", profile = "Профиль"

    var icon: String {
        switch self {
        case .catalog: "TabFeed"
        case .search: "TabSearch"
        case .messages: "TabMessages"
        case .profile: "TabProfile"
        }
    }

    var placeholder: String {
        switch self {
        case .catalog: "Экран каталога"
        case .search: "Экран поиска"
        case .messages: "Экран сообщений"
        case .profile: "Профиль"
        }
    }
}

struct ShelfTabs: View {
    var body: some View {
        ShelfTabController()
            .ignoresSafeArea(.container)
    }
}

private struct ShelfTabController: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UITabBarController {
        let tabs = UITabBarController()
        tabs.overrideUserInterfaceStyle = .light
        tabs.view.tintColor = UIColor(Palette.accent)
        tabs.viewControllers = ShelfTab.allCases.map { tab in
            let placeholder = Text(tab.placeholder)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Palette.ink)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Palette.paper.ignoresSafeArea())
            let controller = UIHostingController(rootView: placeholder)
            let item = UITabBarItem(title: tab.rawValue, image: UIImage(named: tab.icon)?.withRenderingMode(.alwaysTemplate), tag: 0)
            item.accessibilityIdentifier = "tab." + tab.icon
            controller.tabBarItem = item
            return controller
        }
        tabs.selectedViewController = tabs.viewControllers?.last
        return tabs
    }

    func updateUIViewController(_ controller: UITabBarController, context: Context) {}
}
