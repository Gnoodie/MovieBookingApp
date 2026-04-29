import SwiftUI

/// Card với hiệu ứng kính mờ — dùng cho Mini Cart, Overlay, Badge
struct GlassCardView<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 16
    var material: Material = .ultraThinMaterial
    
    init(cornerRadius: CGFloat = 16,
         material: Material = .ultraThinMaterial,
         @ViewBuilder content: () -> Content) {
        self.content = content()
        self.cornerRadius = cornerRadius
        self.material = material
    }
    
    var body: some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(material)
                    .environment(\.colorScheme, .dark) // Ép buộc Dark mode material
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
                    .blendMode(.overlay)
            }
    }
}
