import SwiftUI

struct CollectionsView: View {
    let userID: String
    let isOwner: Bool
    let flow: ProfileFlow

    private enum LoadState { case loading, ready, denied, failed }
    @State private var state = LoadState.loading
    @State private var items: [ProfileCollection] = []
    @State private var total: Int?
    @State private var nextOffset: Int?
    @State private var requestOffset = 0
    @State private var revision = 0

    private static let dateFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.timeZone = .gmt
        formatter.dateFormat = "d MMMM yyyy"
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Button(action: flow.back) {
                    Image(systemName: "arrow.left").foregroundStyle(Palette.accent)
                        .frame(width: 38, height: 38).background(ProfileColor.peach, in: Circle())
                        .frame(width: 44, height: 44)
                }.accessibilityLabel("Назад")
                Text("Коллекции").font(.headline).accessibilityAddTraits(.isHeader)
                Spacer()
                if let total { Text(String(total)).font(.subheadline).foregroundStyle(ProfileColor.muted) }
            }.padding(.vertical, 3)

            GeometryReader { area in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        if isOwner {
                            Text("Ваши коллекции").font(.footnote).foregroundStyle(ProfileColor.muted)
                                .padding(.vertical, 18)
                        }
                        ForEach(items) { collection in
                            collectionRow(collection)
                            Rectangle().fill(ProfileColor.line).frame(height: 0.8)
                        }
                        switch state {
                        case .loading:
                            ProgressView("Загрузка коллекций").frame(maxWidth: .infinity).padding()
                        case .denied:
                            notice("Список коллекций недоступен")
                        case .failed:
                            notice("Не удалось загрузить данные. Попробуйте позже")
                            Button("Повторить") { request(from: requestOffset) }
                                .foregroundStyle(Palette.accent).frame(maxWidth: .infinity, minHeight: 44)
                        case .ready:
                            if items.isEmpty {
                                Text(isOwner ? "У вас пока нет коллекций" : "Нет доступных коллекций")
                                    .font(.subheadline).foregroundStyle(ProfileColor.muted)
                                    .frame(maxWidth: .infinity).padding(.top, area.size.height * 0.24)
                            }
                            if let nextOffset {
                                Button { request(from: nextOffset) } label: {
                                    Text("Показать ещё").font(.footnote.weight(.semibold))
                                        .frame(maxWidth: .infinity, minHeight: 34)
                                        .background(Color(red: 0.97, green: 0.78, blue: 0.68),
                                                    in: RoundedRectangle(cornerRadius: 12))
                                }.padding(.vertical, 12)
                            }
                            if isOwner {
                                Button(action: {}) {
                                    Label("Создать коллекцию", systemImage: "plus")
                                        .font(.footnote.weight(.medium)).foregroundStyle(Palette.accent)
                                        .padding(.horizontal, 18).frame(minHeight: 40)
                                        .background(ProfileColor.peach, in: Capsule())
                                }.frame(maxWidth: .infinity).padding(.vertical, 20)
                            }
                        }
                    }
                    .padding(.bottom, 16)
                }
                .scrollIndicators(.hidden, axes: .vertical)
            }
        }
        .padding(.horizontal, 20).frame(maxWidth: 580).frame(maxWidth: .infinity)
        .foregroundStyle(Palette.ink).buttonStyle(.plain)
        .background(ProfileColor.background.ignoresSafeArea())
        .task(id: revision) { await load() }
    }

    private func collectionRow(_ collection: ProfileCollection) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(collection.name).font(.subheadline.weight(.medium))
                    Spacer(minLength: 0)
                    if isOwner {
                        Text(collection.visibility.rawValue).font(.caption2).foregroundStyle(ProfileColor.muted)
                    }
                }
                Text(Self.dateFormat.string(from: collection.date)).font(.caption).foregroundStyle(ProfileColor.muted)
            }
            Image(systemName: "chevron.right").font(.footnote.weight(.semibold))
                .foregroundStyle(ProfileColor.muted).accessibilityHidden(true)
        }
        .padding(.vertical, 12).padding(.trailing, 4)
        .frame(minHeight: 62).accessibilityElement(children: .combine)
    }

    private func notice(_ text: String) -> some View {
        Text(text).font(.subheadline).padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ProfileColor.background, in: RoundedRectangle(cornerRadius: 14))
            .overlay { RoundedRectangle(cornerRadius: 14).strokeBorder(ProfileColor.line) }
            .padding(.vertical, 12)
    }

    private func request(from offset: Int) {
        requestOffset = offset
        state = .loading
        revision += 1
    }

    @MainActor private func load() async {
        let offset = requestOffset
        state = .loading
        do {
            let page = try await flow.profiles.collectionsPage(userID: userID, offset: offset, limit: 20)
            try Task.checkCancellation()
            if offset == 0 {
                items = page.items
            } else {
                let existingIDs = Set(items.map(\.id))
                items.append(contentsOf: page.items.filter { !existingIDs.contains($0.id) })
            }
            total = page.total
            nextOffset = page.nextOffset
            requestOffset = 0
            state = .ready
        } catch CollectionListError.accessDenied {
            guard !Task.isCancelled else { return }
            items = []
            total = nil
            nextOffset = nil
            state = .denied
        } catch {
            if !Task.isCancelled { state = .failed }
        }
    }
}
