import SwiftUI

enum EchoTheme {
    static let background = Color(hex: 0xFFFBF5)
    static let primary = Color(hex: 0xFFCF70)
    static let text = Color(hex: 0x2F2419, opacity: 0.9)
    static let secondaryText = Color(hex: 0x8E7965)
    static let softPrimary = Color(hex: 0xFFF1E2)
    static let divider = Color(hex: 0xE8D8C6)
    static let pageBackdrop = Color.clear
    static let card = Color(hex: 0xFFFFFF, opacity: 0.84)
    static let accent = Color(hex: 0x7A4617)
    static let success = Color(hex: 0x76A880)
    static let warning = Color(hex: 0xE5A843)

    static let pagePadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 20
    static let cardRadius: CGFloat = 18
    static let controlRadius: CGFloat = 14
}

extension Color {
    init(hex: UInt, opacity: Double = 1) {
        let divisor = 255.0
        let red = Double((hex >> 16) & 0xFF) / divisor
        let green = Double((hex >> 8) & 0xFF) / divisor
        let blue = Double(hex & 0xFF) / divisor
        self.init(red: red, green: green, blue: blue, opacity: opacity)
    }
}

struct EchoCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(EchoTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: EchoTheme.cardRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.045), radius: 12, x: 0, y: 6)
    }
}

extension View {
    func echoCard() -> some View {
        modifier(EchoCardStyle())
    }
}
