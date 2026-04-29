import SwiftUI

struct CinematicButton: View {
    enum Variant {
        case primary      // Nền vàng (accentGold), chữ đen
        case secondary    // Nền glass mờ, chữ trắng
        case destructive  // Nền đỏ, chữ trắng
    }
    
    let title: String
    let variant: Variant
    let isLoading: Bool
    let action: () -> Void
    
    init(_ title: String,
         variant: Variant = .primary,
         isLoading: Bool = false,
         action: @escaping () -> Void) {
        self.title = title
        self.variant = variant
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            HapticManager.shared.impact(style: .medium)
            action()
        }) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(variant == .primary ? .black : .white)
                } else {
                    Text(title)
                        .font(.headingMedium)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(backgroundView)
            .foregroundColor(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: shadowColor, radius: 10, x: 0, y: 4)
        }
        .disabled(isLoading)
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - Styles
    @ViewBuilder
    private var backgroundView: some View {
        switch variant {
        case .primary:
            Color.accentGold
        case .secondary:
            Color.white.opacity(0.1)
                .background(.ultraThinMaterial)
        case .destructive:
            Color.statusError
        }
    }
    
    private var foregroundColor: Color {
        switch variant {
        case .primary:   return .black
        case .secondary: return .white
        case .destructive: return .white
        }
    }
    
    private var shadowColor: Color {
        switch variant {
        case .primary:
            return Color.accentGold.opacity(0.3)
        case .secondary, .destructive:
            return Color.clear
        }
    }
}

// MARK: - Button Style (Bấm vào thì thu nhỏ lại 1 chút)
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.cinematicSpring, value: configuration.isPressed)
            .opacity(configuration.isPressed ? 0.9 : 1)
    }
}
