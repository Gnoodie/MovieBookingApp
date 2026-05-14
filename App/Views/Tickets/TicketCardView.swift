import SwiftUI

// MARK: - TicketCardView

struct TicketCardView: View {
    let ticket: Ticket
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            GlassCardView(cornerRadius: 16) {
                HStack(spacing: 16) {
                    // Thumbnail
                    if let posterURL = ticket.moviePosterURL {
                        AsyncImage(url: posterURL) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.backgroundTertiary)
                        }
                        .frame(width: 70, height: 105)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.backgroundTertiary)
                            .frame(width: 70, height: 105)
                    }
                    
                    // Info
                    VStack(alignment: .leading, spacing: 8) {
                        // Title + Status Badge
                        HStack(alignment: .top) {
                            Text(ticket.movieTitle)
                                .font(.headingSmall)
                                .foregroundColor(.textPrimary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                            
                            statusBadge
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            // Cinema
                            HStack(spacing: 4) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 11))
                                Text("\(ticket.cinemaName) - \(ticket.hallName)")
                                    .font(.bodySmall)
                                    .lineLimit(1)
                            }
                            .foregroundColor(.textSecondary)
                            
                            // Date
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 11))
                                Text(formattedShowtime)
                                    .font(.bodySmall)
                            }
                            .foregroundColor(.textSecondary)
                            
                            // Seats
                            HStack(spacing: 4) {
                                Image(systemName: "ticket.fill")
                                    .font(.system(size: 11))
                                Text(seatLabels)
                                    .font(.bodySmall)
                                    .lineLimit(1)
                            }
                            .foregroundColor(.accentTeal)
                        }
                    }
                    
                    Spacer(minLength: 0)
                }
                .padding(16)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - Helpers
    
    private var statusBadge: some View {
        let text: String
        let color: Color
        
        switch ticket.status {
        case .active:
            text = "Hợp lệ"
            color = .statusSuccess
        case .used:
            text = "Đã xem"
            color = .textSecondary
        case .cancelled:
            text = "Đã hủy"
            color = .statusError
        case .expired:
            text = "Đã hết hạn"
            color = .textSecondary
        }
        
        return Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .cornerRadius(6)
    }
    
    private var formattedShowtime: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "dd/MM/yyyy, HH:mm"
        return formatter.string(from: ticket.showtime)
    }
    
    private var seatLabels: String {
        let labels = ticket.seats.map { "\($0.row)\($0.number)" }
        return labels.joined(separator: ", ")
    }
}
