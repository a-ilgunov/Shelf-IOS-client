import SwiftUI

struct MailView: View {
    let page: AuthPage
    let flow: ProfileFlow
    @State private var deadline = Date().addingTimeInterval(3600)

    var body: some View {
        PageCanvas { u, available in
            VStack(spacing: 0) {
                if page == .mailSent || page == .sendError { BackLink(action: flow.login) }
                switch page {
                case .mailSent:
                    PageTitle(title: "Проверьте почту").padding(.top, 18*u)
                    Button {
                        flow.show(Date() < deadline ? .verified : .expired)
                    } label: {
                        Image("MailSent").resizable().scaledToFit().frame(width: 101*u, height: 96*u)
                    }.buttonStyle(.plain).accessibilityLabel("Открыть письмо с подтверждением")
                        .padding(.top, 24*u)
                    VStack(spacing: 8*u) {
                        Text("На указанный адрес электронной почты отправлено письмо с подтверждением.")
                            .fontWeight(.bold).lineLimit(nil).fixedSize(horizontal: false, vertical: true)
                        Text("Перейдите по ссылке в письме, чтобы подтвердить адрес.")
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Ссылка действительна в течение 1 часа.")
                        TimelineView(.periodic(from: .now, by: 1)) { time in
                            let seconds = max(0, Int(ceil(deadline.timeIntervalSince(time.date))))
                            Text(String(format: "%02d:%02d:%02d", seconds/3600, seconds/60%60, seconds%60))
                                .font(.system(size: 30*u, weight: .bold)).monospacedDigit()
                                .frame(width: 200*u, height: 62*u)
                                .background(Palette.field, in: RoundedRectangle(cornerRadius: 11*u))
                                .overlay { RoundedRectangle(cornerRadius: 11*u).strokeBorder(Palette.accent) }
                        }
                    }.fixedSize(horizontal: false, vertical: true).padding(.top, 20*u)
                    (Text("Если адрес не будет подтверждён в течение 7 дней, учётная запись будет ") + Text("удалена.").bold())
                        .padding(.horizontal, 12*u).padding(.top, 29*u)
                    Button("Закрыть", action: flow.login)
                        .buttonStyle(ActionStyle(color: Palette.rust)).padding(.horizontal, 20*u).padding(.top, 29*u)
                case .sendError:
                    PageTitle(title: "Не удалось отправить письмо для подтверждения адреса электронной почты", size: 23)
                        .padding(.top, 46*u)
                    badge("MailFailed", u: u).padding(.top, 28*u)
                    Text("Попробуйте позже").font(.system(size: 18*u)).padding(.top, 52*u)
                    Button("ОК", action: flow.back).buttonStyle(ActionStyle(height: 54)).padding(.top, 36*u)
                case .verified:
                    PageTitle(title: "Электронная почта подтверждена!").padding(.top, 24*u)
                    badge("MailVerified", u: u).padding(.top, 53*u)
                    Spacer(minLength: 45*u)
                    Text("Теперь вы можете войти в аккаунт").font(.system(size: 18*u))
                    Button("Вход", action: flow.login).buttonStyle(ActionStyle(height: 54)).padding(.top, 20*u)
                default:
                    PageTitle(title: "Что-то пошло не так").padding(.top, 54*u)
                    Text("Не удалось подтвердить почту.").font(.system(size: 18*u)).padding(.top, 14*u)
                    badge("MailExpired", u: u).padding(.top, 14*u)
                    Text("Возможно, срок действия ссылки истёк. Запросите новое письмо и попробуйте ещё раз.")
                        .font(.system(size: 18*u)).lineSpacing(4*u).padding(.top, 14*u)
                    Spacer(minLength: 45*u)
                    Button("Отправить письмо заново") { flow.show(.resend) }
                        .buttonStyle(ActionStyle(height: 54))
                }
            }
            .font(.system(size: 15*u)).lineSpacing(3*u).multilineTextAlignment(.center)
            .padding(.bottom, page == .verified || page == .expired ? 76*u : 18*u)
            .frame(minHeight: available, alignment: .top)
        }
    }

    private func badge(_ image: String, u: CGFloat) -> some View {
        Circle().fill(Palette.field)
            .overlay { Circle().strokeBorder(Palette.accent.opacity(0.7), lineWidth: 0.8) }
            .frame(width: 130*u, height: 130*u)
            .overlay { Image(image).resizable().scaledToFit().frame(width: (page == .sendError ? 92 : 76)*u) }
    }
}
