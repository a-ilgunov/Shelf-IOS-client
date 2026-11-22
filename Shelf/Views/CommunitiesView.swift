import SwiftUI

struct CommunityRow: View {
    let community: Community
    let index: Int

    var body: some View {
        HStack(spacing: 12) {
            Text(String(community.name.prefix(1))).font(.headline)
                .frame(width: 40, height: 40)
                .background(ProfileColor.initials[index % ProfileColor.initials.count], in: RoundedRectangle(cornerRadius: 10))
                .accessibilityHidden(true)
            Text(community.name).font(.subheadline.weight(.medium))
        }
    }
}

struct CommunitiesView: View {
    let userID: String
    let isOwner: Bool
    let flow: ProfileFlow

    private enum LoadState { case loading, ready, failed }

    @State private var communities: [Community] = []
    @State private var state = LoadState.loading
    @State private var nextOffset: Int?
    @State private var requestOffset = 0
    @State private var revision = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Button(action: flow.back) {
                    Image(systemName: "arrow.left").foregroundStyle(Palette.accent)
                        .frame(width: 38, height: 38).background(ProfileColor.peach, in: Circle())
                        .frame(width: 44, height: 44)
                }.accessibilityLabel("Назад")
                Text("Сообщества").font(.headline).accessibilityAddTraits(.isHeader)
            }.padding(.vertical, 3)

            GeometryReader { area in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(communities.enumerated()), id: \.element.id) { index, community in
                            CommunityRow(community: community, index: index)
                                .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
                            Rectangle().fill(ProfileColor.line).frame(height: 0.8)
                        }

                        switch state {
                        case .loading:
                            ProgressView("Загрузка сообществ").padding()
                        case .failed:
                            Text("Не удалось загрузить сообщества.").font(.footnote).padding(.top, 16)
                            Button("Повторить") { reload(from: requestOffset) }
                                .foregroundStyle(Palette.accent).frame(minHeight: 44)
                        case .ready:
                            if communities.isEmpty {
                                Text(isOwner ? "Вы пока не подписаны ни на одно сообщество" :
                                        "Пользователь не подписан ни на одно сообщество")
                                    .font(.subheadline).foregroundStyle(ProfileColor.muted)
                                    .multilineTextAlignment(.center).padding(.horizontal, 20)
                                    .padding(.top, area.size.height * 0.28)
                            }
                            if let nextOffset {
                                Button {
                                    reload(from: nextOffset)
                                } label: {
                                    Text("Показать ещё").font(.footnote.weight(.semibold))
                                        .frame(maxWidth: .infinity, minHeight: 34)
                                        .background(Color(red: 0.97, green: 0.78, blue: 0.68),
                                                    in: RoundedRectangle(cornerRadius: 12))
                                }.padding(.vertical, 12)
                            }
                        }

                        if isOwner {
                            Button(action: {}) {
                                Label("Создать сообщество", systemImage: "plus")
                                    .font(.footnote.weight(.medium)).foregroundStyle(Palette.accent)
                                    .padding(.horizontal, 18).frame(minHeight: 40)
                                    .background(ProfileColor.peach, in: Capsule())
                            }.padding(.vertical, 20)
                        }
                    }
                    .frame(maxWidth: .infinity).padding(.bottom, 16)
                }
                .scrollIndicators(.hidden, axes: .vertical)
            }
        }
        .padding(.horizontal, 20).frame(maxWidth: 580).frame(maxWidth: .infinity)
        .buttonStyle(.plain).foregroundStyle(Palette.ink)
        .background(ProfileColor.background.ignoresSafeArea())
        .task(id: revision) { await load() }
    }

    private func reload(from offset: Int) {
        requestOffset = offset
        state = .loading
        revision += 1
    }

    @MainActor private func load() async {
        let offset = requestOffset
        state = .loading
        do {
            let page = try await flow.profiles.communitiesPage(userID: userID, offset: offset,
                                                               limit: offset == 0 ? max(20, communities.count) : 20)
            try Task.checkCancellation()
            if offset == 0 {
                communities = page.items
            } else {
                let existingIDs = Set(communities.map(\.id))
                communities.append(contentsOf: page.items.filter { !existingIDs.contains($0.id) })
            }
            nextOffset = page.nextOffset
            requestOffset = 0
            state = .ready
        } catch {
            if !Task.isCancelled { state = .failed }
        }
    }
}
