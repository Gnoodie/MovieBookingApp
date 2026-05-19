import AppIntents

@available(iOS 17.0, *)
struct CinematicketShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: BookMovieIntent(),
            phrases: [
                "Đặt vé \(.applicationName)",
                "Mua vé phim trên \(.applicationName)"
            ],
            shortTitle: "Đặt vé",
            systemImageName: "ticket.fill"
        )
        
        AppShortcut(
            intent: CheckTicketsIntent(),
            phrases: [
                "Xem vé của tôi trên \(.applicationName)",
                "Kiểm tra vé \(.applicationName)"
            ],
            shortTitle: "Vé của tôi",
            systemImageName: "qrcode"
        )
    }
}
