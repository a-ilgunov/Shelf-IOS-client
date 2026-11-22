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

@MainActor
final class MockProfileService: ProfileService {
    private let owner = ProfileContact(id: "anna", name: "Anna")
    private static let initialFriends: [ProfileContact] = {
        let first = [
            ProfileContact(id: "masha", name: "Маша"), ProfileContact(id: "ilya", name: "Илья"),
            ProfileContact(id: "sonya", name: "Соня"), ProfileContact(id: "dima", name: "Дима"),
            ProfileContact(id: "alisa", name: "Алиса")
        ]
        let names = """
            Александр Алексей Алина Анастасия Андрей Анна Антон Арина Богдан Вадим Валерий Василий Вера Виктор Виктория Владимир Галина Георгий
            Глеб Григорий Даниил Дарья Денис Диана Дмитрий Ева Евгений Евгения Егор Екатерина Елена Елизавета Захар Злата Зоя Иван Игорь Инна
            Ирина Карина Кирилл Кристина Ксения Лариса Лев Леонид Лидия Лилия Любовь Людмила Майя Макар Максим Маргарита Марина Мария Марк
            Марта Матвей Милана Михаил Надежда Наталья Нина Оксана Олег Ольга Павел Пётр Полина Прохор Раиса Регина Роман Ростислав Руслан
            Руслана Савелий Светлана Семён Сергей София Станислав Степан Таисия Тамара Татьяна Тимофей Тимур Ульяна Фёдор Филипп Эдуард Элина
            Эмилия Юлия Юрий Яна Ярослав Ярослава Агата Агния Адам Аделина Алёна Альбина Амелия Ангелина Анфиса Аркадий Арсений Афанасий
            Борис Валентин Валентина Варвара Вероника Владислав Геннадий Герман Давид Демид Елисей Ефим Зинаида Изабелла Инесса Иосиф Леся
            """
        let more = names.split(whereSeparator: { $0.isWhitespace }).map { name in
            ProfileContact(id: "friend-" + name, name: String(name))
        }
        return Array((first + more).prefix(128))
    }()
    private let incoming = [ProfileContact(id: "lena", name: "Лена"), .init(id: "kolya", name: "Коля"),
                            .init(id: "sasha", name: "Саша")]
    private let outgoing = [ProfileContact(id: "miroslava", name: "Мирослава"), .init(id: "artem", name: "Артём"),
                            .init(id: "valeria", name: "Валерия"), .init(id: "nikita", name: "Никита")]
    private var contacts: [ProfileContact] { Self.initialFriends + incoming + outgoing }
    private var relationships: [String: ProfileRelationship] = [:]

    private static let subscriptions = [
        "Мир книгоманов", "Фильмы Нолана", "Аниме и саундтреки", "Винил и кассеты",
        "Манга и комиксы", "Настольные игры", "Ретро-игры и эмуляция", "Саундтреки и джаз",
        "Сериалы и дорамы", "Фигурки и статуэтки", "Артбуки и концепт-арт", "Аудиокниги и подкасты",
        "Джаз и акустическая музыка", "Искусство и арт-принты", "Классическое кино",
        "Коллекционные виниловые коробки", "Кофейные книги и журналы", "Лайт-новеллы и ранобэ",
        "Мерч и коллекционные вещи", "Поэзия и литературные журналы", "Фотокниги",
        "Художественные альбомы", "Экспериментальное кино", "Японская анимация"
    ].enumerated().map { Community(id: "community-" + String($0.offset), name: $0.element) }

    private var ownCommunities = Array(subscriptions.prefix(10))

    private func memberships(for userID: String) -> [Community] {
        switch userID {
        case owner.id: ownCommunities
        case "masha": Self.subscriptions
        case "ilya": []
        default: Array(Self.subscriptions.prefix(10))
        }
    }

    private func communitySection(for userID: String) -> ProfileSection<Community> {
        let items = memberships(for: userID)
        return .init(total: items.count, preview: Array(items.prefix(2)))
    }

    func communitiesPage(userID: String, offset: Int, limit: Int) async throws -> CommunitiesPage {
        let ordered = memberships(for: userID).sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        let items = Array(ordered.dropFirst(offset).prefix(limit))
        let end = offset + items.count
        return CommunitiesPage(items: items, nextOffset: end < ordered.count ? end : nil)
    }

    func createCommunity(name: String) async throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw CommunityError.emptyName }
        ownCommunities.insert(.init(id: UUID().uuidString, name: trimmed), at: 0)
    }

    private enum CommunityError: LocalizedError {
        case emptyName
        var errorDescription: String? { "Введите название сообщества." }
    }

    private func visibleCollections(for userID: String) throws -> [ProfileCollection] {
        if userID == owner.id { return MockCollections.own }
        let relationship = relationship(for: userID)
        guard userID != "dima", relationship != .blocked else { throw CollectionListError.accessDenied }
        let items: [ProfileCollection]
        switch userID {
        case "masha": items = MockCollections.guest
        case "ilya": items = []
        default: items = Array(MockCollections.guest.prefix(3))
        }
        return items.filter { $0.visibility == .everyone || ($0.visibility == .friends && relationship == .friends) }
    }

    private func collectionSection(for userID: String) -> ProfileSection<ProfileCollection> {
        let items = (try? visibleCollections(for: userID)) ?? []
        return .init(total: items.count, preview: Array(items.prefix(2)))
    }

    func collectionsPage(userID: String, offset: Int, limit: Int) async throws -> CollectionsPage {
        let visible = try visibleCollections(for: userID)
        let items = Array(visible.dropFirst(offset).prefix(limit))
        let end = offset + items.count
        return CollectionsPage(items: items, total: visible.count, nextOffset: end < visible.count ? end : nil)
    }

    private func friends(of id: String) -> [ProfileContact] {
        if id == owner.id { return contacts.filter { relationship(for: $0.id) == .friends } }
        var list: [ProfileContact] = []
        if Self.initialFriends.contains(where: { $0.id == id }) {
            list = Self.initialFriends.filter { $0.id != id }
        }
        if relationship(for: id) == .friends { list.insert(owner, at: 0) }
        return list
    }

    func friendsPage(_ list: FriendsList, offset: Int, limit: Int) async throws -> FriendsPage {
        let members: [ProfileContact]
        let showRequests: Bool
        switch list {
        case .friends(let id):
            showRequests = id == owner.id
            let list = friends(of: id)
            members = showRequests ? list : list.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        case .incoming:
            showRequests = true
            members = contacts.filter { relationship(for: $0.id) == .incoming }
        case .outgoing:
            showRequests = true
            members = contacts.filter { relationship(for: $0.id) == .requested }
        }
        return FriendsPage(contacts: Array(members.dropFirst(offset).prefix(limit)), total: members.count,
                          incomingCount: showRequests ? contacts.filter { relationship(for: $0.id) == .incoming }.count : nil)
    }

    func myProfile() async throws -> UserProfile {
        let visibleFriends = friends(of: owner.id)
        return UserProfile(id: owner.id, name: owner.name, bio: "Не всё интересное можно рассказать словами.",
            friends: .init(total: visibleFriends.count, preview: Array(visibleFriends.prefix(5))),
            communities: communitySection(for: owner.id),
            collections: collectionSection(for: owner.id), relationship: .none)
    }

    func profile(id: String) async throws -> UserProfile {
        guard let contact = contacts.first(where: { $0.id == id }) else {
            throw ProfileError.missing
        }
        let relationship = relationship(for: id)
        let members = friends(of: id)
        return UserProfile(id: id, name: contact.name, bio: "Не всё интересное можно рассказать словами.",
            friends: .init(total: members.count, preview: Array(members.prefix(5))),
            communities: communitySection(for: id),
            collections: collectionSection(for: id),
            relationship: relationship)
    }

    func perform(_ action: ProfileAction, for id: String) async throws -> UserProfile {
        var profile = try await profile(id: id)
        switch (action, profile.relationship) {
        case (.block, _): profile.relationship = .blocked
        case (.acceptRequest, .incoming): profile.relationship = .friends
        case (.unblock, .blocked), (.cancelRequest, .requested), (.declineRequest, .incoming), (.removeFriend, .friends):
            profile.relationship = .none
        case (.requestFriendship, .none): profile.relationship = .requested
        default: throw FriendshipError.noLongerCurrent
        }
        relationships[id] = profile.relationship
        return try await self.profile(id: id)
    }

    private func relationship(for id: String) -> ProfileRelationship {
        if let changed = relationships[id] { return changed }
        if incoming.contains(where: { $0.id == id }) { return .incoming }
        if outgoing.contains(where: { $0.id == id }) { return .requested }
        return .friends
    }

    private enum ProfileError: LocalizedError {
        case missing
        var errorDescription: String? { "Профиль не найден." }
    }
}
