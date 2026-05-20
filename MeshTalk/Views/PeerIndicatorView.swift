import SwiftUI

struct PeerIndicatorView: View {
    let peerNames: [String]

    var body: some View {
        Group {
            if peerNames.isEmpty {
                noPeersView
            } else {
                peersRow
            }
        }
    }

    private var noPeersView: some View {
        HStack(spacing: MeshSpacing.xs) {
            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                .font(.system(size: 14))
                .foregroundColor(MeshColors.secondaryText)

            Text("No peers connected")
                .font(MeshFonts.caption)
                .foregroundColor(MeshColors.secondaryText)
        }
        .padding(.vertical, MeshSpacing.xs)
    }

    private var peersRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MeshSpacing.xs) {
                ForEach(peerNames, id: \.self) { name in
                    PeerPill(name: name)
                }
            }
            .padding(.horizontal, MeshSpacing.md)
        }
    }
}

private struct PeerPill: View {
    let name: String

    private var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    var body: some View {
        HStack(spacing: MeshSpacing.xs) {
            // Initials circle
            ZStack {
                Circle()
                    .fill(MeshColors.accent.opacity(0.2))
                    .frame(width: 26, height: 26)

                Text(initials)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(MeshColors.accent)
            }

            Text(name)
                .font(MeshFonts.caption)
                .foregroundColor(MeshColors.primaryText)
                .lineLimit(1)
        }
        .padding(.horizontal, MeshSpacing.sm)
        .padding(.vertical, MeshSpacing.xxs + 2)
        .background(MeshColors.accentLight.opacity(0.6))
        .cornerRadius(20)
    }
}

#if DEBUG
struct PeerIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            PeerIndicatorView(peerNames: [])
            PeerIndicatorView(peerNames: ["Alice", "Bob Chen", "Charlie"])
        }
        .padding()
        .background(MeshColors.background)
    }
}
#endif
