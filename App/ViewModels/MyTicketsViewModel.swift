import Foundation
import Combine
import CoreImage.CIFilterBuiltins
import UIKit

// MARK: - MyTicketsViewModel

@MainActor
final class MyTicketsViewModel: ObservableObject {
    @Published var activeTickets: [Ticket] = []
    @Published var historyTickets: [Ticket] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let ticketRepository: TicketRepositoryProtocol
    
    init(ticketRepository: TicketRepositoryProtocol = FirestoreTicketRepository()) {
        self.ticketRepository = ticketRepository
    }
    
    func fetchTickets() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let tickets = try await ticketRepository.fetchMyTickets()
            
            // Lọc và phân loại
            let now = Date()
            
            // Active: Vé chưa hết hạn và có trạng thái active
            self.activeTickets = tickets.filter { ticket in
                ticket.status == .active && ticket.showtime > now.addingTimeInterval(-3 * 3600) // Tính cả lúc đang chiếu (sau giờ chiếu 3 tiếng vẫn coi là active nếu chưa hết hạn)
            }.sorted { $0.showtime < $1.showtime }
            
            // History: Vé đã hết hạn, hoặc trạng thái khác
            self.historyTickets = tickets.filter { ticket in
                !(ticket.status == .active && ticket.showtime > now.addingTimeInterval(-3 * 3600))
            }.sorted { $0.showtime > $1.showtime }
            
        } catch {
            self.errorMessage = "Không thể tải danh sách vé: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
