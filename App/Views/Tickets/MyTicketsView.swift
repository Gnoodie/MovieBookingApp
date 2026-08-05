import SwiftUI

// MARK: - MyTicketsView

struct MyTicketsView: View {
    @StateObject private var viewModel = MyTicketsViewModel()
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var appViewModel: AppViewModel

    @State private var selectedSegment = 0 // 0: Sắp xem, 1: Lịch sử
    @State private var selectedTicket: Ticket? = nil

    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundPrimary.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    Text("Vé của tôi")
                        .font(.headingLarge)
                        .foregroundColor(.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 8)

                    if !appViewModel.isAuthenticated {
                        guestTicketsView
                    } else {
                        // Segmented Control (Custom)
                        customSegmentedControl
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)

                        // Content
                        if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                            .tint(.accentTeal)
                            .scaleEffect(1.2)
                        Spacer()
                    } else if let error = viewModel.errorMessage {
                        Spacer()
                        Text(error)
                            .font(.bodyMedium)
                            .foregroundColor(.statusError)
                            .multilineTextAlignment(.center)
                            .padding()
                        Button("Thử lại") {
                            Task { await viewModel.fetchTickets() }
                        }
                        .foregroundColor(.accentTeal)
                        Spacer()
                    } else {
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(spacing: 16) {
                                let currentTickets = selectedSegment == 0 ? viewModel.activeTickets : viewModel.historyTickets
                                
                                if currentTickets.isEmpty {
                                    emptyStateView
                                } else {
                                    ForEach(currentTickets) { ticket in
                                        TicketCardView(ticket: ticket) {
                                            selectedTicket = ticket
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 30)
                        }
                        .refreshable {
                            await viewModel.fetchTickets()
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .background(
                Group {
                    if let ticket = selectedTicket {
                        NavigationLink(
                            destination: ETicketView(ticket: ticket),
                            isActive: Binding(
                                get: { selectedTicket != nil },
                                set: { if !$0 { selectedTicket = nil } }
                            )
                        ) { EmptyView() }
                        .isDetailLink(false)
                    }
                }
            )
            .task {
                await viewModel.fetchTickets()
            }
        }
        .navigationViewStyle(.stack)
    }
    
    // MARK: - Custom Segmented Control
    
    private var customSegmentedControl: some View {
        HStack(spacing: 0) {
            segmentButton(title: "Sắp xem", index: 0)
            segmentButton(title: "Lịch sử", index: 1)
        }
        .background(Color.backgroundSecondary)
        .cornerRadius(8)
    }
    
    private func segmentButton(title: String, index: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedSegment = index
            }
        } label: {
            Text(title)
                .font(.system(size: 14, weight: selectedSegment == index ? .bold : .medium))
                .foregroundColor(selectedSegment == index ? .black : .textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(selectedSegment == index ? Color.accentTeal : Color.clear)
                        .padding(2)
                )
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "ticket")
                .font(.system(size: 60))
                .foregroundColor(.textSecondary.opacity(0.5))
            
            Text(selectedSegment == 0 ? "Bạn chưa có vé nào sắp tới" : "Chưa có lịch sử đặt vé")
                .font(.headingSmall)
                .foregroundColor(.textPrimary)
            
            Text(selectedSegment == 0 ? "Hãy đặt vé ngay để thưởng thức những bộ phim hấp dẫn nhé!" : "Các vé bạn đã xem hoặc hết hạn sẽ hiển thị ở đây.")
                .font(.bodySmall)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.top, 60)
    }

    // MARK: - Guest State

    private var guestTicketsView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(Color.accentGold)

            Text("Bạn chưa đăng nhập")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)

            Text("Đăng nhập để xem danh sách vé đã đặt và nhận thông tin ưu đãi mới nhất.")
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)

            Button {
                appViewModel.showLoginSheet = true
            } label: {
                Text("Đăng nhập / Đăng ký")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(Color.accentGold)
                    .cornerRadius(12)
            }
            .padding(.top, 8)

            Spacer()
        }
    }
}
