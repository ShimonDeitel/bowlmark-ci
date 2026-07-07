import SwiftUI

/// Bowlmark's identity: a sage-green/butter-yellow kitchen palette —
/// evokes a feeding chart taped to the fridge. Distinct from every
/// sibling app's colors (no rust/teal/plum/navy reused).
enum BMTheme {
    static let backdrop = Color(red: 0.953, green: 0.957, blue: 0.925)   // pale sage-cream
    static let surface = Color.white
    static let surfaceRaised = Color(red: 0.914, green: 0.925, blue: 0.867)
    static let ink = Color(red: 0.161, green: 0.196, blue: 0.145)        // deep pine-ink
    static let inkFaded = Color(red: 0.161, green: 0.196, blue: 0.145).opacity(0.55)
    static let rule = Color.black.opacity(0.08)

    static let sage = Color(red: 0.435, green: 0.549, blue: 0.365)      // fresh sage-green
    static let sageBright = Color(red: 0.518, green: 0.643, blue: 0.435)
    static let butter = Color(red: 0.910, green: 0.749, blue: 0.318)    // butter-yellow (bowl accent)
    static let danger = Color(red: 0.702, green: 0.267, blue: 0.196)
    static let success = Color(red: 0.435, green: 0.549, blue: 0.365)

    static let titleFont = Font.system(.title2, design: .rounded).weight(.bold)
    static let headlineFont = Font.system(.headline, design: .rounded).weight(.semibold)
}

struct DismissKeyboardOnTap: ViewModifier {
    func body(content: Content) -> some View {
        content.simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            }
        )
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTap())
    }
}
