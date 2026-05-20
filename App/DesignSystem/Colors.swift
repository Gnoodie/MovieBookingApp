import SwiftUI

extension Color {
    // MARK: - Background Scale
    /// Màu nền tối nhất — màn hình chính
    static let backgroundPrimary   = Color(hex: "#000000")
    /// Nền card/sheet — tối nhẹ hơn
    static let backgroundSecondary = Color(hex: "#1C1C1E")
    /// Nền raised element (popover, menu)
    static let backgroundTertiary  = Color(hex: "#2C2C2E")
    
    // MARK: - Accent (Cinematic Gold)
    /// CTA buttons, selected states
    static let accentGold  = Color(hex: "#F5C518")   // IMDb gold
    /// Link, icon active
    static let accentTeal  = Color(hex: "#00B4D8")
    
    // MARK: - Seat Map Colors
    static let seatEmpty   = Color(hex: "#3A3A3C")   // Xám trung tính
    static let seatHold    = Color(hex: "#48CAE4")   // Xanh dương nhạt — người khác đang giữ
    static let seatBooked  = Color(hex: "#6B6B6D")   // Xám tối — đã bán
    static let seatMine    = Color(hex: "#34C759")   // Xanh lá — tôi đang giữ
    static let seatVIP     = Color(hex: "#FFD60A")   // Vàng — ghế VIP
    static let seatCouple  = Color(hex: "#FF375F")   // Hồng — ghế đôi
    
    // MARK: - Text
    static let textPrimary   = Color.white
    static let textSecondary = Color(hex: "#EBEBF5").opacity(0.6)
    static let textDisabled  = Color(hex: "#EBEBF5").opacity(0.3)
    
    // MARK: - Status
    static let statusSuccess = Color(hex: "#34C759")
    static let statusError   = Color(hex: "#FF453A")
    static let statusWarning = Color(hex: "#FF9F0A")
    
    // MARK: - Hex Init Helper
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue:  Double(b) / 255,
                  opacity: Double(a) / 255)
    }
    
    // MARK: - From Name Helper
    static func fromName(_ name: String) -> Color {
        switch name {
        case "backgroundPrimary":   return .backgroundPrimary
        case "backgroundSecondary": return .backgroundSecondary
        case "backgroundTertiary":  return .backgroundTertiary
        case "accentGold":          return .accentGold
        case "accentTeal":          return .accentTeal
        case "statusSuccess":       return .statusSuccess
        case "statusError":         return .statusError
        case "statusWarning":       return .statusWarning
        default:                    return Color(name)
        }
    }
}
