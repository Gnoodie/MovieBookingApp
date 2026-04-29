import SwiftUI

extension Font {
    // MARK: - Display (Poster titles, Hero text)
    static let displayLarge  = Font.system(size: 34, weight: .bold,   design: .rounded)
    static let displayMedium = Font.system(size: 28, weight: .bold,   design: .rounded)
    
    // MARK: - Heading
    static let headingLarge  = Font.system(size: 22, weight: .semibold, design: .default)
    static let headingMedium = Font.system(size: 17, weight: .semibold, design: .default)
    static let headingSmall  = Font.system(size: 15, weight: .medium,   design: .default)
    
    // MARK: - Body
    static let bodyLarge     = Font.system(size: 17, weight: .regular, design: .default)
    static let bodyMedium    = Font.system(size: 15, weight: .regular, design: .default)
    static let bodySmall     = Font.system(size: 13, weight: .regular, design: .default)
    
    // MARK: - Caption / Label
    static let caption       = Font.system(size: 12, weight: .regular, design: .default)
    static let label         = Font.system(size: 11, weight: .medium,  design: .default)
    
    // MARK: - Seat Map (compact)
    static let seatLabel     = Font.system(size: 9,  weight: .semibold, design: .monospaced)
}

// MARK: - ViewModifier shortcuts
extension View {
    func cinematicTitle() -> some View {
        self.font(.displayLarge).foregroundStyle(Color.textPrimary)
    }
    
    func sectionHeader() -> some View {
        self.font(.headingMedium).foregroundStyle(Color.textPrimary)
    }
    
    func bodyText() -> some View {
        self.font(.bodyMedium).foregroundStyle(Color.textSecondary)
    }
}
