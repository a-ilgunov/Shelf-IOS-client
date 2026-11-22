import SwiftUI

private enum FriendsTab: CaseIterable {
    case friends, incoming, outgoing

    func label(incomingCount: Int?) -> String {
        switch self {
        case .friends: "Мои\nдрузья"
        case .incoming: "Входящие\nзаявки" + (incomingCount.map { " " + String($0) } ?? "")
        case .outgoing: "Исходящие\nзаявки"
        }
    }

    var heading: String {
        switch self {
        case .friends: "Мои друзья"
        case .incoming: "Ожидают вашего ответа"
        case .outgoing: "Отправленные заявки"
        }
    }
}

struct FriendsView: View {
    let userID: String
    let isOwner: Bool
    let flow: ProfileFlow
    @State private var tab = FriendsTab.friends
    @State private var incomingCount: Int?
    @State private var changingRequest = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Button(action: flow.back) {
                    Image(systemName: "arrow.left").foregroundStyle(Palette.accent)
                        .frame(width: 38, height: 38).background(ProfileColor.peach, in: Circle())
                        .frame(width: 44, height: 44)
                }.accessibilityLabel("Назад")
                Text("Друзья").font(.headline).accessibilityAddTraits(.isHeader)
            }.padding(.vertical, 3)

            if isOwner {
                HStack(spacing: 6) {
                    ForEach(FriendsTab.allCases, id: \.self) { item in
                        Button {
                            tab = item
                        } label: {
                            Text(item.label(incomingCount: incomingCount))
                                .font(.footnote.weight(tab == item ? .semibold : .regular))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(tab == item ? Palette.accent : ProfileColor.muted)
                                .frame(maxWidth: .infinity, minHeight: 54)
                                .background(tab == item ? ProfileColor.peach : .clear, in: RoundedRectangle(cornerRadius: 12))
                                .contentShape(Rectangle())
                        }.accessibilityAddTraits(tab == item ? .isSelected : [])
                    }
                }.padding(.vertical, 10).disabled(changingRequest)
            }

            FriendsListContent(userID: userID, isOwner: isOwner, tab: tab, flow: flow,
                               incomingCount: $incomingCount, changingRequest: $changingRequest)
                .id(tab)
        }
        .padding(.horizontal, 20).frame(maxWidth: 580).frame(maxWidth: .infinity)
        .buttonStyle(.plain).foregroundStyle(Palette.ink)
        .background(ProfileColor.background.ignoresSafeArea())
    }
}

private struct FriendsListContent: View {
    let userID: String
    let isOwner: Bool
    let tab: FriendsTab
    let flow: ProfileFlow
    @Binding var incomingCount: Int?
    @Binding var changingRequest: Bool
    @State private var contacts: [ProfileContact] = []
    @State private var total: Int?
    @State private var offset = 0
    @State private var revision = 0
    @State private var loading = false
    @State private var loadFailed = false
    @State private var actionError: String?

    private var list: FriendsList {
        switch tab {
        case .friends: .friends(userID: userID)
        case .incoming: .incoming
        case .outgoing: .outgoing
        }
    }

    var body: some View {
        Group {
            if total == 0 && !loadFailed && actionError == nil {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        if let actionError { notice(actionError) }
                        if isOwner, let total, total > 0 {
                            HStack(spacing: 8) {
                                Text(tab.heading).font(.subheadline.weight(.semibold))
                                Text(String(total)).font(.footnote).foregroundStyle(ProfileColor.muted)
                            }.padding(.vertical, 12).accessibilityElement(children: .combine)
                        }
                        ForEach(Array(contacts.enumerated()), id: \.element.id) { index, contact in
                            row(contact, index: index)
                            Rectangle().fill(ProfileColor.line).frame(height: 0.8)
                        }
                        if loadFailed {
                            notice(tab == .friends ? "Не удалось загрузить список друзей. Попробуйте позже" :
                                    "Не удалось загрузить список заявок. Попробуйте позже", retry: true)
                        } else if loading {
                            ProgressView().frame(maxWidth: .infinity).padding()
                        } else if let total, contacts.count < total {
                            Button {
                                offset = contacts.count
                                revision += 1
                            } label: {
                                Text("Показать ещё").font(.footnote.weight(.semibold))
                                    .frame(maxWidth: .infinity, minHeight: 34)
                                    .background(requestFill, in: RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.horizontal, 4).padding(.vertical, 14)
                            .disabled(changingRequest)
                        }
                    }.padding(.bottom, 12)
                }
                .scrollIndicators(.hidden, axes: .vertical)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: revision) { await load() }
    }

    private var requestFill: Color { Color(red: 0.97, green: 0.78, blue: 0.68) }

    private func row(_ contact: ProfileContact, index: Int) -> some View {
        HStack(alignment: tab == .friends ? .center : .top, spacing: 12) {
            Text(String(contact.name.prefix(1))).font(.headline.weight(.medium))
                .frame(width: 40, height: 40)
                .background(ProfileColor.initials[index % ProfileColor.initials.count], in: Circle())
                .accessibilityHidden(true)
            if tab == .friends {
                Text(contact.name).font(.subheadline.weight(.medium))
                Spacer()
                if isOwner { Image(systemName: "chevron.right").font(.footnote).foregroundStyle(ProfileColor.muted) }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text(contact.name).font(.subheadline.weight(.medium))
                    if tab == .outgoing {
                        Text("Ожидает ответа").font(.caption).foregroundStyle(ProfileColor.muted)
                        requestButton("Отменить заявку", action: .cancelRequest, id: contact.id)
                    } else {
                        HStack(spacing: 8) {
                            requestButton("Принять", action: .acceptRequest, id: contact.id, filled: true)
                            requestButton("Отклонить", action: .declineRequest, id: contact.id)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.vertical, tab == .friends ? 9 : 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(ContactLink(enabled: tab == .friends, open: { flow.openProfile(id: contact.id) }))
    }

    private func requestButton(_ title: String, action: ProfileAction, id: String, filled: Bool = false) -> some View {
        Button {
            guard !changingRequest else { return }
            changingRequest = true
            Task { await perform(action, id: id) }
        } label: {
            Text(title).font(.footnote.weight(.medium)).padding(.horizontal, 13).frame(minHeight: 34)
                .foregroundStyle(filled ? Palette.ink : Palette.accent)
                .background(filled ? requestFill : .clear, in: RoundedRectangle(cornerRadius: 10))
                .overlay { RoundedRectangle(cornerRadius: 10).strokeBorder(filled ? .clear : ProfileColor.line) }
        }.disabled(changingRequest || loading)
    }

    private func notice(_ text: String, retry: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(text).font(.footnote)
                .foregroundStyle(text == "Заявка больше не актуальна" ? Palette.ink : Palette.rust)
            if retry {
                Button("Повторить") { revision += 1 }
                    .font(.footnote.weight(.semibold)).padding(10)
                    .background(ProfileColor.peach, in: RoundedRectangle(cornerRadius: 10))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(ProfileColor.background, in: RoundedRectangle(cornerRadius: 14))
        .overlay { RoundedRectangle(cornerRadius: 14).strokeBorder(ProfileColor.line) }
        .padding(.vertical, 10)
    }

    private var emptyState: some View {
        let content: (icon: String, title: String, subtitle: String)
        switch tab {
        case .friends: content = ("person.2", "У вас пока нет друзей", "Добавляйте людей в друзья, чтобы делиться коллекциями.")
        case .incoming: content = ("person.badge.plus", "Нет входящих заявок", "Когда кто-то захочет добавить вас в друзья, заявка появится здесь.")
        case .outgoing: content = ("paperplane", "Нет отправленных заявок", "Здесь будут ваши заявки в друзья, на которые ещё не ответили.")
        }
        return VStack(spacing: 14) {
            Spacer()
            if isOwner {
                Image(systemName: content.icon).font(.title2.weight(.light)).foregroundStyle(Palette.accent)
                    .frame(width: 60, height: 60).background(ProfileColor.peach, in: Circle())
                Text(content.title).font(.headline)
                Text(content.subtitle).font(.footnote).foregroundStyle(ProfileColor.muted)
            } else {
                Text("Список друзей пуст").font(.footnote).foregroundStyle(ProfileColor.muted)
            }
            Spacer()
            Spacer()
        }.multilineTextAlignment(.center).padding(.horizontal, 8)
    }

    @MainActor private func load() async {
        loading = true
        loadFailed = false
        let pageSize = isOwner ? 9 : 20
        do {
            let page = try await flow.profiles.friendsPage(list, offset: offset, limit: offset == 0 ? max(pageSize, contacts.count) : pageSize)
            try Task.checkCancellation()
            if offset == 0 {
                contacts = page.contacts
            } else {
                let existing = Set(contacts.map(\.id))
                contacts.append(contentsOf: page.contacts.filter { !existing.contains($0.id) })
            }
            total = page.total
            if let count = page.incomingCount { incomingCount = count }
            offset = 0
        } catch {
            guard !Task.isCancelled else { return }
            loadFailed = true
        }
        loading = false
    }

    @MainActor private func perform(_ action: ProfileAction, id: String) async {
        defer { changingRequest = false }
        actionError = nil
        do {
            _ = try await flow.profiles.perform(action, for: id)
            contacts.removeAll { $0.id == id }
            total = max(0, (total ?? 1) - 1)
            if tab == .incoming { incomingCount = total }
        } catch FriendshipError.noLongerCurrent {
            actionError = "Заявка больше не актуальна"
        } catch {
            actionError = action.failureMessage
            return
        }
        offset = 0
        revision += 1
    }
}

private struct ContactLink: ViewModifier {
    let enabled: Bool
    let open: () -> Void

    @ViewBuilder func body(content: Content) -> some View {
        if enabled {
            Button(action: open) { content.contentShape(Rectangle()) }
        } else {
            content
        }
    }
}
