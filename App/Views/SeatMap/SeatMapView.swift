import SwiftUI

// MARK: - SeatMapView

/// Màn hình chọn ghế chính của Sprint 3
/// Tích hợp SeatMapCanvas, Legend, MiniCart và logic Hold ghế
struct SeatMapView: View {
    @StateObject private var viewModel: SeatMapViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var router: AppRouter

    /// Trigger navigation sang FnBMenuView khi hold ghế thành công
    @State private var navigateToFnB: Bool = false
    /// F&B items đã chọn (được set sau khi FnBMenuView trả về)
    @State private var selectedFnBItems: [FnBOrderItem] = []

    init(showtime: Showtime, movie: Movie) {
        _viewModel = StateObject(wrappedValue: SeatMapViewModel(showtime: showtime, movie: movie, seatRepository: FirestoreSeatRepository()))
    }

    var body: some View {
        ZStack {
            Color(hex: "#000000").ignoresSafeArea()

            if viewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView().tint(Color(hex: "#D4AF37")).scaleEffect(1.5)
                    Text("Đang tải sơ đồ rạp...").foregroundColor(.gray)
                }
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle").font(.system(size: 40)).foregroundColor(.red)
                    Text(error).foregroundColor(.white)
                    Button("Thử lại") { viewModel.loadSeats() }
                        .padding().background(Color(hex: "#D4AF37")).cornerRadius(8).foregroundColor(.black)
                }
            } else if let seatMap = viewModel.seatMap {
                let layout = SeatMapLayout(seatMap: seatMap)

                VStack(spacing: 0) {
                    // MARK: Header
                    HStack(spacing: 16) {
                        Button {
                            if viewModel.isHoldActive {
                                viewModel.cancelTimerAndRelease()
                            }
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Circle())
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.movie.title)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)

                            Text("Hôm nay - \(viewModel.showtime.cinemaName)")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 56)
                    .padding(.bottom, 16)
                    .background(Color(hex: "#1C1C1E"))

                    // MARK: Canvas
                    SeatMapCanvas(
                        layout: layout,
                        selectedSeatIds: viewModel.selectedSeatIds,
                        onSeatTapped: { seat in
                            viewModel.seatTapped(seat)
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .zIndex(1)

                    // MARK: Legend
                    SeatLegendView()
                        .padding(.bottom, 120)
                }

                // MARK: Overlays
                VStack {
                    if viewModel.isHoldActive {
                        FloatingHoldTimerBar(
                            timeFormatted: viewModel.holdTimerFormatted,
                            isWarning: viewModel.isTimerWarning
                        )
                        .padding(.top, 100)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    Spacer()

                    // Mini Cart — bấm 1 lần là đủ:
                    // Nếu chưa hold → hold, onChange tự navigate sau khi thành công
                    // Nếu đã hold → navigate ngay
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

                // Loading overlay khi đang gọi API hold
                if viewModel.isHoldingSeats {
                    Color.black.opacity(0.5).ignoresSafeArea()
                    ProgressView("Đang giữ ghế...")
                        .padding()
                        .background(Color(hex: "#1C1C1E"))
                        .cornerRadius(12)
                        .foregroundColor(.white)
                        .tint(Color(hex: "#D4AF37"))
                }
            }

            // MARK: NavigationLink ẩn
            // QUAN TRỌNG: Phải nằm trong ZStack, KHÔNG phải .background()
            // iOS 15: NavigationLink trong .background() không kích hoạt navigation
            NavigationLink(
                destination: FnBMenuView(
                    selectedSeats: viewModel.selectedSeats,
                    showtime: viewModel.showtime,
                    movie: viewModel.movie
                ) { fnbItems in
                    self.selectedFnBItems = fnbItems
                    // TODO Phase 3: navigate sang CheckoutView
                    print("✅ F&B done: \(fnbItems.count) items selected")
                }
                .environmentObject(router),
                isActive: $navigateToFnB
            ) { EmptyView() }
        }
        .navigationBarHidden(true)
        // Auto-navigate sau khi holdSelectedSeats() thành công — không cần bấm lần 2
        .onChange(of: viewModel.isHoldActive) { isActive in
            if isActive {
                navigateToFnB = true
            }
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
        .alert(isPresented: $viewModel.showTimerExpiredAlert) {
            Alert(
                title: Text("Hết thời gian giữ ghế"),
                message: Text("Thời gian giữ ghế đã hết. Vui lòng chọn lại ghế."),
                dismissButton: .default(Text("Đồng ý")) {
                    dismiss()
                }
            )
        }
    }
}
