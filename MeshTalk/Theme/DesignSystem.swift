import SwiftUI

// MARK: - MeshColors

struct MeshColors {
    // Backgrounds
    static let background = Color(red: 0xFA/255, green: 0xF3/255, blue: 0xE8/255)       // #FAF3E8 warm cream
    static let surface = Color.white                                                       // #FFFFFF
    static let controlBg = Color(red: 0xE8/255, green: 0xDD/255, blue: 0xD0/255)          // #E8DDD0 warm tan

    // Text
    static let primaryText = Color(red: 0x2C/255, green: 0x3E/255, blue: 0x2D/255)        // #2C3E2D dark forest green
    static let secondaryText = Color(red: 0x5A/255, green: 0x6B/255, blue: 0x5A/255)      // #5A6B5A

    // Accents
    static let accent = Color(red: 0x4A/255, green: 0x7C/255, blue: 0x59/255)             // #4A7C59 sage
    static let activeTX = Color(red: 0x3D/255, green: 0x8B/255, blue: 0x37/255)           // #3D8B37 bright green
    static let accentLight = Color(red: 0xD4/255, green: 0xE8/255, blue: 0xD0/255)        // #D4E8D0 pale sage

    // Wave layers (front to back)
    static let wave1 = Color(red: 0x8F/255, green: 0xBC/255, blue: 0x8F/255)              // #8FBC8F
    static let wave2 = Color(red: 0x6B/255, green: 0x9B/255, blue: 0x6B/255)              // #6B9B6B
    static let wave3 = Color(red: 0x4A/255, green: 0x7C/255, blue: 0x59/255)              // #4A7C59
    static let wave4 = Color(red: 0x3D/255, green: 0x6B/255, blue: 0x47/255)              // #3D6B47

    static let waveColors: [Color] = [wave1, wave2, wave3, wave4]

    // Semantic
    static let error = Color(red: 0xC7/255, green: 0x50/255, blue: 0x50/255)              // #C75050

    // Gradients
    static let pttActiveGradient = LinearGradient(
        colors: [accent, activeTX],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Shadow
    static let shadowColor = Color.black.opacity(0.08)
    static let shadowRadius: CGFloat = 8
    static let shadowY: CGFloat = 4
}

// MARK: - MeshFonts

struct MeshFonts {
    static var header: Font {
        .system(size: 28, weight: .bold, design: .rounded)
    }

    static var title: Font {
        .system(size: 20, weight: .semibold, design: .rounded)
    }

    static var body: Font {
        .system(size: 16, weight: .regular, design: .default)
    }

    static var caption: Font {
        .system(size: 12, weight: .medium, design: .default)
    }

    static var caption2: Font {
        .system(size: 10, weight: .medium, design: .default)
    }

    static var mono: Font {
        .system(size: 14, weight: .regular, design: .monospaced)
    }
}

// MARK: - MeshSpacing

struct MeshSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48

    // Screen-level horizontal padding
    static let screenH: CGFloat = 20

    // Corner radii
    static let cardRadius: CGFloat = 20
    static let buttonRadius: CGFloat = 16
}

// MARK: - View Modifiers

struct MeshCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(MeshColors.surface)
            .cornerRadius(MeshSpacing.cardRadius)
            .shadow(
                color: MeshColors.shadowColor,
                radius: MeshColors.shadowRadius,
                x: 0,
                y: MeshColors.shadowY
            )
    }
}

extension View {
    func meshCard() -> some View {
        modifier(MeshCardStyle())
    }
}
