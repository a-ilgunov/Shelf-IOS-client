import SwiftUI

enum Palette {
    static let paper = Color(red: 1, green: 243/255, blue: 236/255)
    static let field = Color(red: 1, green: 248/255, blue: 244/255)
    static let ink = Color(red: 61/255, green: 43/255, blue: 31/255)
    static let accent = Color(red: 166/255, green: 84/255, blue: 31/255)
    static let secondary = Color(red: 156/255, green: 107/255, blue: 82/255)
    static let hint = Color(red: 196/255, green: 152/255, blue: 128/255)
    static let border = Color(red: 245/255, green: 196/255, blue: 168/255)
    static let rust = Color(red: 182/255, green: 77/255, blue: 39/255)
}

private struct LayoutUnit: EnvironmentKey { static let defaultValue: CGFloat = 1 }
extension EnvironmentValues {
    var shelfUnit: CGFloat {
        get { self[LayoutUnit.self] }
        set { self[LayoutUnit.self] = newValue }
    }
}

// Use the artboard's proportions on phones and limit line length on larger devices.
struct PageCanvas<Content: View>: View {
    var centered = false
    var inset: CGFloat = 22
    @ViewBuilder let content: (CGFloat, CGFloat) -> Content

    var body: some View {
        GeometryReader { area in
            let width = min(area.size.width, 470)
            let u = min(width / 366, 1.16)
            ScrollView {
                content(u, area.size.height)
                    .environment(\.shelfUnit, u)
                    .padding(.horizontal, inset * u)
                    .frame(maxWidth: width)
                    .frame(maxWidth: .infinity, minHeight: area.size.height, alignment: centered ? .center : .top)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}

struct PageTitle: View {
    let title: String
    var subtitle: String? = nil
    var size: CGFloat = 30
    @Environment(\.shelfUnit) private var u

    var body: some View {
        VStack(spacing: 6*u) {
            Text(title).font(.system(size: size*u, weight: .bold)).accessibilityAddTraits(.isHeader)
            if let subtitle {
                Text(subtitle).font(.system(size: 15*u)).foregroundStyle(Palette.secondary)
            }
        }
        .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
    }
}

struct ActionStyle: ButtonStyle {
    var outlined = false
    var color = Palette.accent
    var height: CGFloat = 48
    @Environment(\.shelfUnit) private var u
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 15*u, weight: .semibold)).frame(maxWidth: .infinity)
            .frame(minHeight: height*u)
            .foregroundStyle(outlined ? Palette.ink : .white)
            .background(outlined ? Palette.field : color, in: RoundedRectangle(cornerRadius: 11*u))
            .overlay { if outlined { RoundedRectangle(cornerRadius: 11*u).strokeBorder(Palette.border, lineWidth: 1) } }
            .opacity(configuration.isPressed ? 0.78 : 1)
    }
}

struct AccountField: View {
    let title: String
    let hint: String
    @Binding var value: String
    var required = false
    var secret = false
    var email = false
    var neutralBorder = false
    let id: String
    @State private var revealed = false
    @Environment(\.shelfUnit) private var u
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7*u) {
            (Text(title) + Text(required ? " *" : "").foregroundColor(Palette.accent))
                .font(.system(size: 13.5*u, weight: .medium))
            HStack(spacing: 0) {
                let prompt = Text(secret && !revealed ? "••••••••••••" : hint)
                    .foregroundColor(secret && !revealed ? Palette.ink : Palette.hint)
                Group {
                    if secret && !revealed { SecureField("", text: $value, prompt: prompt) }
                    else { TextField("", text: $value, prompt: prompt) }
                }
                .keyboardType(email ? .emailAddress : .default)
                .textInputAutocapitalization(.never).autocorrectionDisabled()
                .focused($focused).submitLabel(.done).onSubmit { focused = false }
                .font(.system(size: 15*u))
                .accessibilityLabel(title).accessibilityIdentifier(id)
                .padding(.leading, 15*u)
                if secret {
                    Button {
                        revealed.toggle()
                    } label: {
                        Image(revealed ? "EyeClosed" : "EyeOpen")
                            .resizable().scaledToFit().frame(width: 19*u, height: 19*u)
                            .frame(width: 46*u, height: 46*u)
                    }.buttonStyle(.plain)
                        .accessibilityLabel(revealed ? "Скрыть пароль" : "Показать пароль")
                        .accessibilityIdentifier(id + ".visibility")
                } else { Spacer(minLength: 12*u) }
            }
            .frame(minHeight: 48*u)
            .background(Palette.field, in: RoundedRectangle(cornerRadius: 10*u))
            .overlay {
                RoundedRectangle(cornerRadius: 10*u)
                    .strokeBorder(focused ? Palette.accent : (neutralBorder ? Color(.systemGray5) : Palette.border),
                                  lineWidth: focused ? 1.4 : 1).allowsHitTesting(false)
            }
        }
    }
}

struct InlineAction: View {
    let prefix: String
    let label: String
    let action: () -> Void
    @Environment(\.shelfUnit) private var u
    var body: some View {
        HStack(spacing: 3*u) {
            Text(prefix).foregroundStyle(Palette.secondary)
            Button(action: action) { Text(label).fontWeight(.semibold).underline() }
                .buttonStyle(.plain).foregroundStyle(Palette.accent)
        }.font(.system(size: 13*u)).frame(maxWidth: .infinity)
    }
}

struct BackLink: View {
    var title = "Назад к входу"
    let action: () -> Void
    @Environment(\.shelfUnit) private var u
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8*u) {
                Image(systemName: "arrow.left")
                Text(title).font(.system(size: 13*u, weight: .medium))
            }.frame(minHeight: 44, alignment: .leading)
        }.buttonStyle(.plain).foregroundStyle(Palette.accent)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
