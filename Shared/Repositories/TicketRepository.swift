import Foundation

// MARK: - Ticket Repository Protocol

protocol TicketRepositoryProtocol {
    func fetchMyTickets() async throws -> [Ticket]
    func fetchTicketDetail(id: String) async throws -> Ticket
    func cancelTicket(id: String) async throws
}

// MARK: - Mock Implementation

struct MockTicketRepository: TicketRepositoryProtocol {
    func fetchMyTickets() async throws -> [Ticket] {
        return Ticket.mocks
    }
    
    func fetchTicketDetail(id: String) async throws -> Ticket {
        if let ticket = Ticket.mocks.first(where: { $0.id == id }) {
            return ticket
        }
        throw NSError(domain: "TicketRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "Ticket not found"])
    }
    
    func cancelTicket(id: String) async throws {
        // Giả lập hủy vé thành công
    }
}
