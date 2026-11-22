import SwiftUI

struct ProfileView: View {
    let onLogout: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Мой профиль").font(.system(size: 32, weight: .bold)).accessibilityAddTraits(.isHeader)
            Button("Выйти", action: onLogout).buttonStyle(ActionStyle()).accessibilityIdentifier("logout")
        }
        .padding(.horizontal, 24).frame(maxWidth: 420)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
