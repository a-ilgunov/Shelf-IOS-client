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
