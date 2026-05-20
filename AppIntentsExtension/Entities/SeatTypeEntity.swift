import AppIntents

@available(iOS 18.0, *)
enum SeatTypeEntity: String, AppEnum {
    case standard
    case vip
    case couple
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Loại ghế"
    
    static var caseDisplayRepresentations: [SeatTypeEntity: DisplayRepresentation] = [
        .standard: "Thường",
        .vip: "VIP",
        .couple: "Ghế đôi"
    ]
}
