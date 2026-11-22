import XCTest

final class ShelfFlowTests: XCTestCase {
    private let app = XCUIApplication()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app.launchArguments = ["-AppleLanguages", "(ru)", "-AppleLocale", "ru_RU"]
        app.launch()
    }

    private func tap(_ button: String) {
        let target = app.buttons[button].firstMatch
        XCTAssertTrue(target.waitForExistence(timeout: 4), button)
        target.tap()
    }

    private func see(_ title: String) {
        XCTAssertTrue(app.staticTexts[title].firstMatch.waitForExistence(timeout: 4), title)
    }

    private func capture(_ title: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = title
        shot.lifetime = .keepAlways
        add(shot)
    }

    func testTabsAndEmptyMockLogin() {
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 4))
        for (tab, title) in [("TabFeed", "Экран каталога"), ("TabSearch", "Экран поиска"), ("TabMessages", "Экран сообщений")] {
            tap("tab." + tab)
            see(title)
        }
        tap("tab.TabProfile")
        see("Вход")
        capture("01-login")
        tap("password.visibility")
        XCTAssertTrue(app.textFields["password"].exists)
        tap("password.visibility")
        tap("submit")
        see("Anna")
        app.terminate()
        app.launch()
        see("Вход")
        tap("Запомнить меня")
        tap("submit")
        see("Anna")
        tap("tab.TabFeed")
        tap("tab.TabProfile")
        see("Anna")
        tap("profile.menu")
        tap("Выйти")
        see("Вход")
    }

    func testOwnAndGuestProfiles() {
        tap("submit")
        see("Anna")
        see("Ваш профиль")
        capture("11-own-profile")
        see("Только я")
        tap("profile.friend.masha")
        see("Профиль Маша")
        XCTAssertFalse(app.staticTexts["Ваш профиль"].exists)
        XCTAssertFalse(app.staticTexts["Только я"].exists)
        capture("12-guest-profile")
        tap("Сообщение")
        see("Экран сообщений")
        tap("tab.TabProfile")
        tap("Назад")
        tap("profile.friend.ilya")
        see("Профиль Илья")
        tap("Заблокировать")
        app.alerts.buttons["Заблокировать"].tap()
        XCTAssertFalse(app.buttons["Сообщение"].isEnabled)
        tap("Разблокировать")
        tap("profile.friendRequest")
        XCTAssertTrue(app.buttons["profile.friendRequest"].label.contains("Отменить"))
        tap("Назад")
        tap("profile.friend.masha")
        see("Профиль Маша")
        see("У вас в друзьях")
        XCTAssertEqual(app.buttons["profile.friendRequest"].label, "Удалить из друзей")
        tap("profile.friendRequest")
        XCTAssertEqual(app.buttons["profile.friendRequest"].label, "Добавить в друзья")
        XCTAssertFalse(app.staticTexts["У вас в друзьях"].exists)
        tap("Назад")
        see("Ваш профиль")
        XCTAssertFalse(app.buttons["profile.friend.masha"].exists)
    }

    func testRegistrationMailAndEdgeSwipe() {
        tap("Зарегистрироваться")
        see("Регистрация")
        capture("02-registration")
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.005, dy: 0.52))
        start.press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.87, dy: 0.52)))
        see("Вход")
        tap("Зарегистрироваться")
        tap("Зарегистрироваться")
        see("Проверьте почту")
        capture("05-mail")
        tap("Открыть письмо с подтверждением")
        see("Электронная почта подтверждена!")
        capture("07-verified")
        tap("Вход")
        see("Вход")
    }

    func testRecoveryAndFAQ() {
        tap("Восстановить")
        capture("03-recovery")
        tap("Отправить письмо")
        see("Изменение пароля")
        capture("04-change")
        tap("Изменить пароль")
        tap("FAQ")
        capture("09-faq")
        tap("Не пришло письмо с подтверждением")
        tap("Отправить письмо повторно")
        capture("10-resend")
        let field = app.textFields["email"]
        field.tap()
        field.typeText("abc\n")
        tap("Отправить письмо повторно")
        see("Попробуйте позже")
        capture("06-send-error")
        tap("ОК")
        XCTAssertEqual(field.value as? String, "abc")
        tap("Назад к FAQ")
        see("FAQ")
    }

    func testExpiredLinkAndResend() {
        app.open(URL(string: "shelf://mail/expired")!)
        see("Что-то пошло не так")
        capture("08-expired")
        tap("Отправить письмо заново")
        tap("Отправить письмо повторно")
        see("Проверьте почту")
        tap("Закрыть")
        see("Вход")
    }
}
