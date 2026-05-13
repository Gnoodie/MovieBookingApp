import SwiftUI

// MARK: - SeatMapView

/// Màn hình chọn ghế chính của Sprint 3
/// v2: Header cải thiện, animation mượt, layout tổng thể đẹp hơn
struct SeatMapView: View {
    @StateObject private var viewModel: SeatMapViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var router: AppRouter

    @State private var navigateToFnB: Bool = false
    @State private var selectedFnBItems: [FnBOrderItem] = []

    init(showtime: Showtime, movie: Movie) {
        _viewModel = StateObject(wrappedValue: SeatMapViewModel(
            showtime: showtime,
            movie: movie,
            seatRepository: FirestoreSeatRepository()
        ))
    }

    var body: some View {
        ZStack {
            Color(hex: "#06060C").ignoresSafeArea()

            if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.errorMessage {
                errorView(error)
            } else if let seatMap = viewModel.seatMap {
                let layout = SeatMapLayout(seatMap: seatMap)
                mainContent(layout: layout)
            }

            // NavigationLink ẩn
            NavigationLink(
                destination: FnBMenuView(
                    selectedSeats: viewModel.selectedSeats,
                    showtime: viewModel.showtime,
                    movie: viewModel.movie
                ) { fnbItems in
                    self.selectedFnBItems = fnbItems
                    print("✅ F&B done: \(fnbItems.count) items selected")
                }
                .environmentObject(router),
                isActive: $navigateToFnB
            ) { EmptyView() }
        }
        .navigationBarHidden(true)
        .onChange(of: viewModel.isHoldActive) { isActive in
            if isActive { navigateToFnB = true }
        }
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
        .alert(isPresented: $viewModel.showConflictAlert) {
            Alert(
                title: Text("Ghế đã bị chọn"),
                message: Text("Ghế \(viewModel.conflictSeatName) vừa bị người khác giữ. Vui lòng chọn ghế khác."),
                dismissButton: .default(Text("Đồng ý"))
            )
        }
        .alert("Cặp ghế không khả dụng", isPresented: $viewModel.showPartnerUnavailableAlert) {
            Button("Đồng ý", role: .cancel) {}
        } message: {
            Text("Ghế \(viewModel.partnerUnavailableSeatName) đã được đặt. Vui lòng chọn cặp ghế khác.")
        }
        .alert(isPresented: $viewModel.showTimerExpiredAlert) {
            Alert(
                title: Text("Hết thời gian giữ ghế"),
                message: Text("Thời gian giữ ghế đã hết. Vui lòng chọn lại ghế."),
                dismissButton: .default(Text("Đồng ý")) { dismiss() }
            )
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color(hex: "#1C1C2E"), lineWidth: 4)
                    .frame(width: 56, height: 56)
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color(hex: "#D4AF37"), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: UUID())
            }
            Text("Đang tải sơ đồ rạp...")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(Color(hex: "#888888"))
        }
    }

    // MARK: - Error View

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 44))
                .foregroundColor(Color(hex: "#FF6B6B"))
            Text(error)
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(Color(hex: "#888888"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("Thử lại") { viewModel.loadSeats() }
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .padding(.horizontal, 28)
                .padding(.vertical, 13)
                .background(Color(hex: "#D4AF37"))
                .clipShape(Capsule())
        }
    }

    // MARK: - Main Content

    private func mainContent(layout: SeatMapLayout) -> some View {
        ZStack {
            VStack(spacing: 0) {
                headerView
                    .background(Color(hex: "#0D0D1A"))

                SeatMapCanvas(
                    layout: layout,
                    selectedSeatIds: viewModel.selectedSeatIds,
                    onSeatTapped: { seat in viewModel.seatTapped(seat) }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                SeatLegendView()
                    .padding(.bottom, 100)
            }

            // Overlays
            VStack {
                if viewModel.isHoldActive {
                    FloatingHoldTimerBar(
                        timeFormatted: viewModel.holdTimerFormatted,
                        isWarning: viewModel.isTimerWarning
                    )
                    .padding(.top, 110)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isHoldActive)
                }

                Spacer()

                MiniCartView(
                    selectedSeats: viewModel.selectedSeats,
                    totalPrice: viewModel.totalPriceFormatted,
                    onContinue: {
                        if viewModel.isHoldActive {
                            navigateToFnB = true
                        } else {
                            viewModel.holdSelectedSeats()
                        }
                    }
                )
            }

            // Hold loading overlay
            if viewModel.isHoldingSeats {
                Color.black.opacity(0.6).ignoresSafeArea()
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(Color(hex: "#39D98A"))
                        .scaleEffect(1.4)
                    Text("Đang giữ ghế...")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(28)
                .background(Color(hex: "#1C1C2E"))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 14) {
            Button {
                if viewModel.isHoldActive { viewModel.cancelTimerAndRelease() }
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(viewModel.movie.title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#888888"))
                    Text(viewModel.showtime.cinemaName)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(Color(hex: "#888888"))
                }
            }

            Spacer()

            // Số ghế đã chọn
            if !viewModel.selectedSeats.isEmpty {
                Text("\(viewModel.selectedSeats.count) ghế")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(hex: "#39D98A"))
                    .clipShape(Capsule())
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.selectedSeats.count)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 56)
        .padding(.bottom, 14)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1),
            alignment: .bottom
        )
    }
}