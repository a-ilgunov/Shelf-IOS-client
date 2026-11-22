import SwiftUI

// A nil ID loads the signed-in user. Other profiles are loaded by their stable ID.
struct ProfilePage: View {
    var userID: String?
    let flow: ProfileFlow
    @State private var profile: UserProfile?
    @State private var loadError: String?
    @State private var attempt = 0

    var body: some View {
        Group {
            if let profile {
                if userID == nil {
                    ProfileView(profile: profile, isOwner: true, flow: flow) { EmptyView() }
                } else {
                    GuestProfileView(profile: profile, flow: flow) { self.profile = $0 }
                }
            } else if let loadError {
                VStack(spacing: 16) {
                    Text(loadError).multilineTextAlignment(.center)
                    Button("Повторить") { attempt += 1 }
                    Button("Назад") {
                        if userID == nil { flow.selectTab(.catalog) } else { flow.back() }
                    }
                }.padding()
            } else {
                ProgressView("Загрузка профиля")
            }
        }
        .task(id: attempt) {
            loadError = nil
            do {
                let loaded: UserProfile
                if let userID {
                    loaded = try await flow.profiles.profile(id: userID)
                } else {
                    loaded = try await flow.profiles.myProfile()
                    try Task.checkCancellation()
                    flow.ownerID = loaded.id
                }
                try Task.checkCancellation()
                profile = loaded
            } catch {
                guard !Task.isCancelled else { return }
                profile = nil
                loadError = error.localizedDescription
            }
        }
    }
}

struct GuestProfileView: View {
    let profile: UserProfile
    let flow: ProfileFlow
    let onUpdate: (UserProfile) -> Void
    @State private var confirmingBlock = false
    @State private var pendingAction: ProfileAction?
    @State private var actionError: String?

    var body: some View {
        ProfileView(profile: profile, isOwner: false, flow: flow) {
            VStack(spacing: 7) {
                if let friendshipButton {
                    Button {
                        send(friendshipButton.action)
                    } label: {
                        Label {
                            Text(friendshipButton.title)
                        } icon: {
                            Image(systemName: friendshipButton.icon).foregroundStyle(Palette.accent)
                        }
                            .frame(maxWidth: .infinity, minHeight: 47)
                            .background(profile.relationship == .friends ? ProfileColor.peach : Color(red: 0.97, green: 0.78, blue: 0.68), in: RoundedRectangle(cornerRadius: 13))
                    }
                    .accessibilityIdentifier("profile.friendRequest")
                }
                Button { flow.selectTab(.messages) } label: {
                    Label {
                        Text("Сообщение")
                    } icon: {
                        Image(systemName: "bubble.left").foregroundStyle(Palette.accent)
                    }
                        .frame(maxWidth: .infinity, minHeight: 46)
                        .overlay { RoundedRectangle(cornerRadius: 13).strokeBorder(ProfileColor.line) }
                }.disabled(profile.relationship == .blocked)
                Button {
                    if profile.relationship == .blocked { send(.unblock) }
                    else { confirmingBlock = true }
                } label: {
                    Label(profile.relationship == .blocked ? "Разблокировать" : "Заблокировать", systemImage: "nosign")
                        .font(.caption2).foregroundStyle(ProfileColor.muted).frame(minHeight: 34)
                }
                if pendingAction != nil { ProgressView() }
                if let actionError { Text(actionError).font(.footnote) }
            }
            .disabled(pendingAction != nil)
            .font(.subheadline.weight(.semibold)).buttonStyle(.plain).padding(.bottom, 10)
        }
        .alert("Заблокировать пользователя \(profile.name)?", isPresented: $confirmingBlock) {
            Button("Заблокировать", role: .destructive) { send(.block) }
            Button("Отмена", role: .cancel) {}
        } message: { Text("Отправка сообщений и заявок в друзья будет недоступна.") }
    }

    private var friendshipButton: (title: String, icon: String, action: ProfileAction)? {
        switch profile.relationship {
        case .friends: ("Удалить из друзей", "person.badge.minus", .removeFriend)
        case .incoming: ("Принять заявку", "person.badge.plus", .acceptRequest)
        case .requested: ("Отменить заявку", "person.badge.minus", .cancelRequest)
        case .none: ("Добавить в друзья", "person.badge.plus", .requestFriendship)
        case .blocked: nil
        }
    }

    private func send(_ action: ProfileAction) {
        guard pendingAction == nil else { return }
        pendingAction = action
        actionError = nil
        Task {
            defer { pendingAction = nil }
            do {
                let updated = try await flow.profiles.perform(action, for: profile.id)
                onUpdate(updated)
            } catch FriendshipError.noLongerCurrent {
                actionError = "Заявка больше не актуальна"
                if let updated = try? await flow.profiles.profile(id: profile.id) { onUpdate(updated) }
            } catch {
                actionError = action.failureMessage
            }
        }
    }
}
