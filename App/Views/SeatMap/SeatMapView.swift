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
                            // Cần release hold nếu đang hold trước khi back
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
                            
                            // Format: "19:30 - CGV Vincom" (dùng DateFormatter tuỳ ý, ở đây mock string ngắn gọn)
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
                    // Timer bar nếu đang hold
                    if viewModel.isHoldActive {
                        FloatingHoldTimerBar(
                            timeFormatted: viewModel.holdTimerFormatted,
                            isWarning: viewModel.isTimerWarning
                        )
                        .padding(.top, 100) // Đẩy xuống dưới Header
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    Spacer()
                    
                    // Mini Cart
                    MiniCartView(
                        selectedSeats: viewModel.selectedSeats,
                        totalPrice: viewModel.totalPriceFormatted,
                        onContinue: {
                            if viewModel.isHoldActive {
                                // Đã hold ghế thành công → sang chọn F&B
                                navigateToFnB = true
                            } else {
                                // Chưa hold → gọi API hold trước
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
        }
        .navigationBarHidden(true)
        .background(
            // NavigationLink ẩn — trigger khi hold thành công và user bấm "Tiếp tục"
            NavigationLink(
                destination: FnBMenuView(
                    selectedSeats: viewModel.selectedSeats,
                    showtime: viewModel.showtime,
                    movie: viewModel.movie
                ) { fnbItems in
                    // Callback: F&B đã chọn xong → chuẩn bị sang Checkout
                    self.selectedFnBItems = fnbItems
                    // TODO Phase 3: navigate sang CheckoutView
                    print("F&B done, items: \(fnbItems.count), proceeding to Checkout")
                }
                .environmentObject(router),
                isActive: $navigateToFnB
            ) { EmptyView() }
        )
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
        // Alert Conflict
        .alert(isPresented: $viewModel.showConflictAlert) {
            Alert(
                title: Text("Ghế đã bị chọn"),
                message: Text("Ghế \(viewModel.conflictSeatName) vừa bị người khác giữ. Vui lòng chọn ghế khác."),
                dismissButton: .default(Text("Đồng ý"))
            )
        }
        // Alert Timeout
        .alert(isPresented: $viewModel.showTimerExpiredAlert) {
            Alert(
                title: Text("Hết thời gian giữ ghế"),
                message: Text("Thời gian giữ ghế đã hết. Vui lòng chọn lại ghế."),
                dismissButton: .default(Text("Đồng ý")) {
                    // dismiss để về màn hình suất chiếu (theo roadmap)
                    dismiss()
                }
            )
        }
    }
}
