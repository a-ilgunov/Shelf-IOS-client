import Foundation

enum MockCollections {
    static let own = [
        item("Книги", 2026, 10, 23), item("Фильмы", 2026, 10, 16, .owner),
        item("Сериалы", 2026, 10, 4, .friends), item("Аниме", 2026, 9, 20, .owner)
    ]

    static let guest = [
        item("Книги", 2026, 10, 24), item("Фильмы", 2026, 10, 21, .friends),
        item("Сериалы", 2026, 10, 17), item("Открытки", 2026, 10, 12),
        item("Музыка", 2026, 10, 5), item("Аниме", 2026, 9, 28),
        item("Мультфильмы", 2026, 9, 19), item("Кассеты", 2026, 9, 11),
        item("Компьютерные игры", 2026, 8, 30), item("Настольные игры", 2026, 8, 18),
        item("Фигурки", 2026, 8, 3), item("Манга", 2026, 7, 24),
        item("Комиксы", 2026, 7, 9), item("Значки", 2026, 3, 8),
        item("Наклейки", 2026, 2, 14), item("Марки", 2026, 1, 19),
        item("Афиши", 2025, 12, 12), item("Артбуки", 2025, 12, 9),
        item("Пазлы", 2025, 11, 8), item("Картины", 2025, 10, 25),
        item("Пластинки", 2025, 10, 12), item("Журналы", 2025, 9, 24),
        item("Монеты", 2025, 9, 10), item("Минералы", 2025, 8, 19),
        item("Модели", 2025, 8, 3), item("Фотографии", 2025, 7, 21),
        item("Игрушки", 2025, 7, 8), item("Карточки", 2025, 6, 12),
        item("Личный архив", 2025, 5, 2, .owner)
    ]

    private static func item(_ name: String, _ year: Int, _ month: Int, _ day: Int,
                             _ visibility: CollectionVisibility = .everyone) -> ProfileCollection {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let date = calendar.date(from: DateComponents(year: year, month: month, day: day))!
        return ProfileCollection(id: name, name: name, date: date, visibility: visibility)
    }
}
