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
    @StateObject private var flow: ProfileFlow

    init(profiles: any ProfileService) {
        _flow = StateObject(wrappedValue: ProfileFlow(profiles: profiles))
    }

    var body: some View {
        ShelfTabController(flow: flow)
            .ignoresSafeArea(.container)
            .onOpenURL { flow.openMailLink($0) }
    }
}

private struct ShelfTabController: UIViewControllerRepresentable {
    let flow: ProfileFlow

    func makeUIViewController(context: Context) -> UITabBarController {
        let tabs = UITabBarController()
        tabs.overrideUserInterfaceStyle = .light
        tabs.view.tintColor = UIColor(Palette.accent)
        tabs.viewControllers = ShelfTab.allCases.map { tab in
            let controller: UIViewController
            if tab == .profile {
                let nav = UINavigationController()
                nav.view.backgroundColor = UIColor(Palette.paper)
                flow.attach(nav)
                controller = nav
            } else {
                let placeholder = Text(tab.placeholder)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Palette.paper.ignoresSafeArea())
                controller = UIHostingController(rootView: placeholder)
            }
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

enum AuthPage: Equatable {
    case login, register, recover, changePassword, faq, resend, mailSent, sendError, verified, expired, profile
    case guestProfile(id: String)
    case friends(userID: String, isOwner: Bool)
    case communities(userID: String, isOwner: Bool)
    case collections(userID: String, isOwner: Bool)
}

@MainActor
final class ProfileFlow: NSObject, ObservableObject, UIGestureRecognizerDelegate {
    private weak var navigation: UINavigationController?
    private var pendingLink: AuthPage?
    let profiles: any ProfileService
    var ownerID: String?

    init(profiles: any ProfileService) {
        self.profiles = profiles
        super.init()
    }

    func openProfile(id: String) {
        if id == ownerID {
            navigation?.popToRootViewController(animated: true)
        } else {
            show(.guestProfile(id: id))
        }
    }

    func attach(_ nav: UINavigationController) {
        navigation = nav
        nav.setNavigationBarHidden(true, animated: false)
        nav.setViewControllers([controller(.login)], animated: false)
        nav.interactivePopGestureRecognizer?.delegate = self
        if let pendingLink {
            self.pendingLink = nil
            show(pendingLink, animated: false)
        }
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let navigation else { return false }
        return navigation.viewControllers.count > 1 && navigation.transitionCoordinator == nil
    }

    func show(_ page: AuthPage, animated: Bool = true) {
        navigation?.view.endEditing(true)
        navigation?.pushViewController(controller(page), animated: animated)
    }

    func back() { navigation?.popViewController(animated: true) }

    func login() {
        guard let navigation else { return }
        if navigation.viewControllers.first?.restorationIdentifier == String(describing: AuthPage.login) {
            navigation.popToRootViewController(animated: true)
        } else {
            navigation.setViewControllers([controller(.login)], animated: true)
        }
    }

    func selectTab(_ tab: ShelfTab) {
        guard let tabs = navigation?.tabBarController,
              let index = ShelfTab.allCases.firstIndex(of: tab) else { return }
        tabs.selectedIndex = index
    }

    func signIn() {
        ownerID = nil
        navigation?.view.endEditing(true)
        navigation?.setViewControllers([controller(.profile)], animated: true)
    }

    func sendMail(to address: String, recovery: Bool = false) {
        let email = address.trimmingCharacters(in: .whitespacesAndNewlines)
        let valid = email.isEmpty || email.range(of: #"^[^@\s]+@[^@\s]+\.[^@\s]+$"#, options: .regularExpression) != nil
        show(valid ? (recovery ? .changePassword : .mailSent) : .sendError)
    }

    func openMailLink(_ url: URL) {
        guard url.scheme == "shelf", url.host == "mail" else { return }
        let page: AuthPage
        switch url.path {
        case "/verified": page = .verified
        case "/expired": page = .expired
        case "/reset": page = .changePassword
        default: return
        }
        if let navigation { navigation.tabBarController?.selectedViewController = navigation }
        if navigation == nil { pendingLink = page } else { show(page) }
    }

    private func controller(_ page: AuthPage) -> UIViewController {
        let host = UIHostingController(rootView: AccountPage(page: page, flow: self,
            fromFAQ: navigation?.topViewController?.restorationIdentifier == String(describing: AuthPage.faq)))
        switch page {
        case .login, .register, .profile, .guestProfile, .friends, .communities, .collections: host.hidesBottomBarWhenPushed = false
        default: host.hidesBottomBarWhenPushed = true
        }
        host.view.backgroundColor = UIColor(Palette.paper)
        host.overrideUserInterfaceStyle = .light
        host.restorationIdentifier = String(describing: page)
        return host
    }
}

private struct AccountPage: View {
    let page: AuthPage
    let flow: ProfileFlow
    let fromFAQ: Bool

    var body: some View {
        Group {
            switch page {
            case .login, .register: AuthView(registering: page == .register, flow: flow)
            case .recover, .changePassword, .resend, .faq: HelpView(page: page, flow: flow, fromFAQ: fromFAQ)
            case .mailSent, .sendError, .verified, .expired: MailView(page: page, flow: flow)
            case .profile: ProfilePage(flow: flow)
            case .friends(let id, let isOwner): FriendsView(userID: id, isOwner: isOwner, flow: flow)
            case .collections(let id, let isOwner): CollectionsView(userID: id, isOwner: isOwner, flow: flow)
            case .communities(let id, let isOwner): CommunitiesView(userID: id, isOwner: isOwner, flow: flow)
            case .guestProfile(let id): ProfilePage(userID: id, flow: flow)
            }
        }
        .foregroundStyle(Palette.ink)
        .tint(Palette.accent)
        .background(Palette.paper.ignoresSafeArea())
    }
}
