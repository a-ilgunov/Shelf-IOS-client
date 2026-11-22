import Foundation

struct ProfileContact: Identifiable {
    let id: String
    let name: String
}

enum CollectionVisibility: String {
    case everyone = "Все"
    case friends = "Только друзья"
    case owner = "Только я"

    var symbol: String {
        switch self {
        case .everyone: "globe"
        case .friends: "person.2"
        case .owner: "lock"
        }
    }
}

struct ProfileCollection: Identifiable {
    let id: String
    let name: String
    let date: Date
    let visibility: CollectionVisibility
}

struct CollectionsPage {
    let items: [ProfileCollection]
    let total: Int
    let nextOffset: Int?
}

enum CollectionListError: Error { case accessDenied }

struct Community: Identifiable {
    let id: String
    let name: String
}

struct CommunitiesPage {
    let items: [Community]
    let nextOffset: Int?
}

struct ProfileSection<Item> {
    let total: Int
    let preview: [Item]
}

enum ProfileRelationship { case none, friends, incoming, requested, blocked }
enum ProfileAction {
    case requestFriendship, acceptRequest, declineRequest, cancelRequest, removeFriend, block, unblock

    var failureMessage: String {
        switch self {
        case .requestFriendship: "Не удалось отправить заявку. Попробуйте позже"
        case .acceptRequest: "Не удалось принять заявку. Попробуйте позже"
        case .declineRequest: "Не удалось отклонить заявку. Попробуйте позже"
        case .cancelRequest: "Не удалось отменить заявку"
        case .removeFriend: "Не удалось удалить пользователя из друзей"
        case .block: "Не удалось заблокировать пользователя"
        case .unblock: "Не удалось разблокировать пользователя"
        }
    }
}

enum FriendshipError: Error { case noLongerCurrent }

enum FriendsList {
    case friends(userID: String)
    case incoming, outgoing
}

struct FriendsPage {
    let contacts: [ProfileContact]
    let total: Int
    let incomingCount: Int?
}

struct UserProfile: Identifiable {
    let id: String
    let name: String
    let bio: String
    let friends: ProfileSection<ProfileContact>
    let communities: ProfileSection<Community>
    let collections: ProfileSection<ProfileCollection>
    var relationship: ProfileRelationship
}

@MainActor
protocol ProfileService {
    func myProfile() async throws -> UserProfile
    func friendsPage(_ list: FriendsList, offset: Int, limit: Int) async throws -> FriendsPage
    func profile(id: String) async throws -> UserProfile
    func communitiesPage(userID: String, offset: Int, limit: Int) async throws -> CommunitiesPage
    func collectionsPage(userID: String, offset: Int, limit: Int) async throws -> CollectionsPage
    func createCommunity(name: String) async throws
    func perform(_ action: ProfileAction, for id: String) async throws -> UserProfile
}
