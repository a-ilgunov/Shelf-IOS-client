import SwiftUI

struct AuthView: View {
    let registering: Bool
    let flow: ProfileFlow
    @State private var email = ""
    @State private var login = ""
    @State private var password = ""
    @State private var confirmation = ""
    @State private var remember = true

    var body: some View {
        PageCanvas(centered: true) { u, _ in
            VStack(spacing: 0) {
                PageTitle(title: registering ? "Регистрация" : "Вход",
                          subtitle: registering ? "Добро пожаловать!" : "С возвращением :)")
                VStack(spacing: 18*u) {
                    if registering {
                        AccountField(title: "Электронная почта", hint: "Введите email", value: $email, required: true, email: true, id: "email")
                    }
                    AccountField(title: registering ? "Имя пользователя" : "Email или имя",
                                 hint: registering ? "Введите имя пользователя" : "Введите email или имя",
                                 value: $login, required: registering, id: "login")
                    AccountField(title: "Пароль", hint: "Введите пароль", value: $password, required: registering, secret: true, id: "password")
                    if registering {
                        AccountField(title: "Подтверждение пароля", hint: "Повторите пароль",
                                     value: $confirmation, required: true, secret: true, id: "confirmation")
                    }
                }.padding(.top, 30*u)
                if registering {
                    Button("Зарегистрироваться") { flow.sendMail(to: email) }
                        .buttonStyle(ActionStyle()).padding(.top, 28*u)
                    InlineAction(prefix: "Уже есть аккаунт?", label: "Войти", action: flow.login)
                        .padding(.top, 28*u)
                } else {
                    Button {
                        remember.toggle()
                    } label: {
                        HStack(spacing: 8*u) {
                            RoundedRectangle(cornerRadius: 5*u)
                                .fill(remember ? Palette.accent : Palette.field)
                                .overlay { RoundedRectangle(cornerRadius: 5*u).strokeBorder(Palette.accent) }
                                .overlay {
                                    if remember { Image(systemName: "checkmark").font(.system(size: 12*u, weight: .bold)).foregroundStyle(.white) }
                                }.frame(width: 18*u, height: 18*u)
                            Text("Запомнить меня").font(.system(size: 13*u, weight: .medium))
                        }.frame(minHeight: 32*u)
                    }.buttonStyle(.plain).accessibilityValue(remember ? "Включено" : "Выключено")
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 10*u)
                    HStack(spacing: 18*u) {
                        Button("FAQ") { flow.show(.faq) }.buttonStyle(ActionStyle(outlined: true)).frame(width: 56*u)
                        Button("Войти", action: flow.signIn).buttonStyle(ActionStyle()).accessibilityIdentifier("submit")
                    }.padding(.horizontal, 8*u).padding(.top, 22*u)
                    VStack(spacing: 9*u) {
                        InlineAction(prefix: "Потерял доступ к аккаунту?", label: "Восстановить") { flow.show(.recover) }
                        InlineAction(prefix: "Новый аккаунт?", label: "Зарегистрироваться") { flow.show(.register) }
                    }.padding(.top, 30*u)
                }
            }.padding(.vertical, 16*u)
        }
    }
}
