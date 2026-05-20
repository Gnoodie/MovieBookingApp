import AppIntents

/// Enum thay thế Bool cho tham số F&B
/// Siri sẽ hiển thị menu 3 lựa chọn thay vì hỏi yes/no không rõ ràng
@available(iOS 18.0, *)
enum FnBOptionEntity: String, AppEnum {
    case none
    case coupleCombo
    case familyCombo

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Combo đồ ăn"

    static var caseDisplayRepresentations: [FnBOptionEntity: DisplayRepresentation] = [
        .none:        "Không cần",
        .coupleCombo: "Combo Couple – 2 Bắp + 2 Nước (150.000đ)",
        .familyCombo: "Combo Gia đình – 3 Bắp + 4 Nước (250.000đ)"
    ]

    /// Số tiền tương ứng với từng lựa chọn
    var amount: Int {
        switch self {
        case .none:        return 0
        case .coupleCombo: return 150_000
        case .familyCombo: return 250_000
        }
    }

    /// Tên hiển thị ngắn gọn
    var displayName: String {
        switch self {
        case .none:        return "Không có F&B"
        case .coupleCombo: return "Combo Couple"
        case .familyCombo: return "Combo Gia đình"
        }
    }
}
