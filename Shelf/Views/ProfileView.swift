import SwiftUI

enum ProfileColor {
    static let background = Color(red: 1, green: 0.977, blue: 0.962)
    static let muted = Color(red: 0.50, green: 0.44, blue: 0.41)
    static let peach = Color(red: 1, green: 0.91, blue: 0.86)
    static let cover = Color(red: 0.95, green: 0.84, blue: 0.77)
    static let line = Color(red: 0.92, green: 0.86, blue: 0.82)
    static let initials = [
        Color(red: 0.91, green: 0.84, blue: 0.79), Color(red: 0.85, green: 0.89, blue: 0.84),
        Color(red: 0.95, green: 0.82, blue: 0.77), Color(red: 0.85, green: 0.88, blue: 0.90),
        Color(red: 0.90, green: 0.86, blue: 0.92)
    ]
}

struct ProfileView<Actions: View>: View {
    let profile: UserProfile
    let isOwner: Bool
    let flow: ProfileFlow
    @ViewBuilder let actions: () -> Actions

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    actions()
                    sectionHeading("Друзья", count: profile.friends.total)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), alignment: .topLeading), count: 5),
                              alignment: .leading, spacing: 8) {
                        ForEach(Array(profile.friends.preview.enumerated()), id: \.element.id) { index, friend in
                            Button {
                                flow.openProfile(id: friend.id)
                            } label: {
                                VStack(spacing: 6) {
                                    initial(friend.name, index: index)
                                    Text(friend.name).font(.caption2).foregroundStyle(ProfileColor.muted)
                                }
                                .frame(width: 44)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(friend.name)
                            .accessibilityIdentifier("profile.friend." + friend.id)
                        }
                    }
                    divider
                    sectionHeading("Сообщества", count: profile.communities.total)
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(profile.communities.preview.enumerated()), id: \.element.id) { index, community in
                            CommunityRow(community: community, index: index)
                        }
                    }
                    divider
                    sectionHeading("Коллекции", count: profile.collections.total)
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(profile.collections.preview) { collection in
                            collectionCard(collection)
                        }
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 24)
                .frame(maxWidth: 580).frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .foregroundStyle(Palette.ink)
        .background(ProfileColor.background.ignoresSafeArea())
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Button {
                if isOwner { flow.selectTab(.catalog) } else { flow.back() }
            } label: {
                Image(systemName: "arrow.left").frame(width: 38, height: 38)
                    .background(ProfileColor.peach, in: Circle()).frame(width: 44, height: 44)
            }.accessibilityLabel("Назад")
            Text(isOwner ? "Профиль" : "Профиль " + profile.name)
                .font(.headline).foregroundStyle(Palette.ink).accessibilityAddTraits(.isHeader)
            Spacer()
            if isOwner {
                Menu {
                    Button("Выйти", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive,
                           action: flow.login).accessibilityIdentifier("logout")
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .frame(width: 38, height: 38)
                        .background(ProfileColor.peach, in: RoundedRectangle(cornerRadius: 10))
                        .frame(width: 44, height: 44)
                }.accessibilityLabel("Меню профиля").accessibilityIdentifier("profile.menu")
            }
        }
        .buttonStyle(.plain).foregroundStyle(Palette.accent)
        .padding(.horizontal, 17).padding(.vertical, 3)
        .frame(maxWidth: 580)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoundedRectangle(cornerRadius: 18).fill(ProfileColor.cover)
                .aspectRatio(3.02, contentMode: .fit)
            HStack(alignment: .bottom) {
                Image(systemName: "person").font(.system(size: 30, weight: .light))
                    .foregroundStyle(Palette.accent).frame(width: 80, height: 80)
                    .background(ProfileColor.peach, in: Circle()).padding(4)
                    .background(ProfileColor.background, in: Circle()).accessibilityHidden(true)
                Spacer()
                if isOwner {
                    Label("Ваш профиль", systemImage: "person").font(.caption2)
                        .foregroundStyle(ProfileColor.muted).padding(.bottom, 14)
                } else if profile.relationship == .friends {
                    Label("У вас в друзьях", systemImage: "checkmark").font(.caption2)
                        .foregroundStyle(Palette.accent).padding(.bottom, 14)
                }
            }.padding(.leading, 10).padding(.top, -42)
            Text(profile.name).font(.system(size: 27, weight: .bold)).padding(.top, 6)
            if !profile.bio.isEmpty {
                Text(profile.bio).font(.footnote).foregroundStyle(ProfileColor.muted)
                    .fixedSize(horizontal: false, vertical: true).padding(.top, 7)
            }
        }.padding(.bottom, isOwner ? 25 : 14)
    }

    private func sectionHeading(_ title: String, count: Int) -> some View {
        HStack(spacing: 7) {
            Text(title).font(.headline)
            Text(String(count)).font(.subheadline).foregroundStyle(ProfileColor.muted)
            Spacer()
            Image(systemName: "chevron.right").font(.footnote.weight(.semibold))
                .foregroundStyle(ProfileColor.muted).padding(.trailing, 6).accessibilityHidden(true)
        }
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private var divider: some View {
        Rectangle().fill(ProfileColor.line).frame(height: 0.8).padding(.top, 18).padding(.bottom, 5)
    }

    private func initial(_ name: String, index: Int) -> some View {
        let colors = ProfileColor.initials
        return Text(String(name.prefix(1))).font(.headline.weight(.medium)).frame(width: 44, height: 44)
            .background(colors[index % colors.count], in: Circle()).accessibilityHidden(true)
    }

    private func collectionCard(_ collection: ProfileCollection) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(collection.name).font(.subheadline.weight(.semibold))
            if isOwner {
                Label(collection.visibility.rawValue, systemImage: collection.visibility.symbol)
                    .font(.caption2).foregroundStyle(ProfileColor.muted)
            }
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 11))
        .overlay { RoundedRectangle(cornerRadius: 11).strokeBorder(ProfileColor.line) }
    }
}
