import SwiftUI

// MARK: - ETicketView

struct ETicketView: View {
    @StateObject private var viewModel: ETicketViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(ticket: Ticket) {
        _viewModel = StateObject(wrappedValue: ETicketViewModel(ticket: ticket))
    }
    
    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        ticketCard
                        
                        // Action buttons
                        CinematicButton(
                            " Thêm vào Apple Wallet",
                            variant: .secondary
                        ) {}
                        .disabled(true) // Phase 4: Mock
                        .overlay(
                            Text("Sắp ra mắt")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentGold)
                                .foregroundColor(.black)
                                .cornerRadius(4)
                                .offset(x: 100, y: -16)
                        )
                        .padding(.horizontal, 24)
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.viewDidAppear()
        }
        .onDisappear {
            viewModel.viewDidDisappear()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Text("Vé Điện Tử")
                .font(.headingMedium)
                .foregroundColor(.textPrimary)
            
            Spacer()
            
            // Dummy view for alignment
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 16)
        .padding(.top, 56)
        .padding(.bottom, 16)
        .background(Color(hex: "#0D0D1A"))
    }
    
    // MARK: - Ticket Card
    
    private var ticketCard: some View {
        VStack(spacing: 0) {
            // Nửa trên: Thông tin phim
            VStack(spacing: 16) {
                if let posterURL = viewModel.ticket.moviePosterURL {
                    AsyncImage(url: posterURL) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.backgroundTertiary
                    }
                    .frame(height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Text(viewModel.ticket.movieTitle)
                    .font(.headingMedium)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 24) {
                    infoBox(title: "Ngày", value: formattedDate)
                    infoBox(title: "Giờ", value: formattedTime)
                }
                
                HStack(spacing: 24) {
                    infoBox(title: "Rạp", value: viewModel.ticket.cinemaName)
                    infoBox(title: "Phòng", value: viewModel.ticket.hallName)
                }
                
                infoBox(title: "Ghế", value: seatLabels)
            }
            .padding(24)
            .background(Color.backgroundSecondary)
            
            // Cutout (rãnh răng cưa giả)
            HStack(spacing: 0) {
                Circle().fill(Color.backgroundPrimary).frame(width: 24, height: 24).offset(x: -12)
                Line()
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                    .frame(height: 1)
                    .foregroundColor(Color.white.opacity(0.2))
                Circle().fill(Color.backgroundPrimary).frame(width: 24, height: 24).offset(x: 12)
            }
            .frame(height: 24)
            .background(Color.backgroundSecondary)
            
            // Nửa dưới: QR Code
            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .frame(width: 200, height: 200)
                    
                    if let qrImage = viewModel.qrImage {
                        Image(uiImage: qrImage)
                            .resizable()
                            .interpolation(.none)
                            .frame(width: 180, height: 180)
                            .blur(radius: viewModel.isQRBlurred ? 10 : 0)
                    } else {
                        ProgressView()
                    }
                    
                    if viewModel.isQRBlurred {
                        VStack {
                            Image(systemName: "eye.slash.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.red)
                            Text("Bảo mật ảnh chụp")
                                .font(.caption)
                                .foregroundColor(.black)
                                .bold()
                        }
                    }
                }
                
                Text(viewModel.ticket.bookingId)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                
                Text("Vui lòng đưa mã này cho nhân viên soát vé.")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            .padding(.bottom, 32)
            .padding(.top, 16)
            .frame(maxWidth: .infinity)
            .background(Color.backgroundSecondary)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 24)
        .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 10)
    }
    
    // MARK: - Helpers
    
    private func infoBox(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.textSecondary)
            Text(value)
                .font(.bodyMedium)
                .foregroundColor(.textPrimary)
                .bold()
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: viewModel.ticket.showtime)
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: viewModel.ticket.showtime)
    }
    
    private var seatLabels: String {
        let labels = viewModel.ticket.seats.map { "\($0.row)\($0.number)" }
        return labels.joined(separator: ", ")
    }
}

// Helper Line shape
private struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height / 2))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height / 2))
        return path
    }
}
