import SwiftUI

struct HelpView: View {
    let page: AuthPage
    let flow: ProfileFlow
    let fromFAQ: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var confirmation = ""
    @State private var firstExpanded = false
    @State private var secondExpanded = true
    @State private var support = false

    var body: some View {
        PageCanvas { u, available in
            VStack(spacing: 0) {
                BackLink(title: page == .resend ? (fromFAQ ? "Назад к FAQ" : "Назад") : "Назад к входу") {
                    if page == .resend { flow.back() } else { flow.login() }
                }
                let top = max(14*u, min(available * 0.12, 98*u))
                switch page {
                case .faq:
                    PageTitle(title: "FAQ").padding(.top, top)
                    VStack(spacing: 14*u) {
                        question("Не пришло письмо с подтверждением", expanded: $firstExpanded, u: u) {
                            Text("Проверьте папку «Спам». Если письма нет, запросите новое.")
                            Button("Отправить письмо повторно") { flow.show(.resend) }.underline()
                        }
                        question("Не помню адрес электронной почты", expanded: $secondExpanded, u: u) {
                            Text("Войдите по имени пользователя. Если вы не помните и его, обратитесь в [службу поддержки](shelf-help://support).")
                                .environment(\.openURL, OpenURLAction { _ in support = true; return .handled })
                        }
                    }.padding(.top, 28*u)
                case .changePassword:
                    PageTitle(title: "Изменение пароля", subtitle: "Придумайте новый пароль").padding(.top, top)
                    VStack(spacing: 22*u) {
                        AccountField(title: "Новый пароль", hint: "Введите пароль", value: $password,
                                     required: true, secret: true, neutralBorder: true, id: "newPassword")
                        AccountField(title: "Подтверждение нового пароля", hint: "Повторите пароль", value: $confirmation,
                                     required: true, secret: true, neutralBorder: true, id: "confirmNewPassword")
                        Button("Изменить пароль", action: flow.login).buttonStyle(ActionStyle())
                    }.padding(.top, 54*u)
                default:
                    let resend = page == .resend
                    PageTitle(title: resend ? "Подтверждение\nпочты" : "Восстановление\nдоступа",
                              subtitle: resend ? "Отправьте письмо ещё раз" : "Отправьте письмо для восстановления\nдоступа к аккаунту")
                        .padding(.top, top)
                    AccountField(title: "Электронная почта", hint: "Введите адрес электронной почты",
                                 value: $email, required: !resend, email: true, id: "email")
                        .padding(.top, 30*u)
                    Button(resend ? "Отправить письмо повторно" : "Отправить письмо") {
                        flow.sendMail(to: email, recovery: !resend)
                    }.buttonStyle(ActionStyle()).padding(.top, 28*u)
                    if resend {
                        VStack(spacing: 22*u) {
                            Image("MailSent").resizable().scaledToFit().frame(width: 63*u, height: 63*u)
                            Text("Если адрес связан с неподтвержденной учетной записью, на него будет отправлено письмо")
                                .font(.system(size: 15*u)).multilineTextAlignment(.center).lineSpacing(4*u)
                        }
                        .padding(.horizontal, 30*u).padding(.vertical, 30*u)
                        .frame(maxWidth: .infinity)
                        .background(.white, in: RoundedRectangle(cornerRadius: 25*u))
                        .shadow(color: .black.opacity(0.2), radius: 2, y: 3)
                        .padding(.horizontal, 6*u).padding(.top, 55*u)
                    }
                }
            }.padding(.bottom, 20*u)
        }
        .alert("Служба поддержки", isPresented: $support) {
            Button("ОК", role: .cancel) {}
        } message: { Text("Контакт службы поддержки появится после подключения сервера.") }
    }

    private func question<Answer: View>(_ title: String, expanded: Binding<Bool>, u: CGFloat,
                                        @ViewBuilder answer: () -> Answer) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { expanded.wrappedValue.toggle() }
            } label: {
                HStack {
                    Text(title).font(.system(size: 15*u, weight: .semibold))
                        .frame(maxWidth: .infinity, alignment: .leading).multilineTextAlignment(.leading)
                    Image(systemName: expanded.wrappedValue ? "chevron.up" : "chevron.right")
                        .font(.system(size: 13*u, weight: .semibold))
                }.padding(15*u).contentShape(Rectangle())
            }.buttonStyle(.plain).foregroundStyle(Palette.accent)
            if expanded.wrappedValue {
                VStack(alignment: .leading, spacing: 6*u) { answer() }
                    .font(.system(size: 15*u)).lineSpacing(3*u)
                    .padding(.horizontal, 15*u).padding(.bottom, 15*u)
            }
        }
        .background(Palette.field, in: RoundedRectangle(cornerRadius: 10*u))
        .overlay { RoundedRectangle(cornerRadius: 10*u).strokeBorder(Palette.border) }
    }
}
