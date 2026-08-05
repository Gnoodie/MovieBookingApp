import SwiftUI

// MARK: - CheckoutView

/// Màn hình tổng kết đơn hàng + chọn phương thức thanh toán
/// Nằm giữa FnBMenuView và BookingSuccessView trong luồng đặt vé
struct CheckoutView: View {
    @StateObject private var viewModel: CheckoutViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var appViewModel: AppViewModel

    @State private var navigateToSuccess: Bool = false

    // MARK: - Init

    init(
        selectedSeats: [Seat],
        showtime: Showtime,
        movie: Movie,
        fnbItems: [FnBOrderItem]
    ) {
        _viewModel = StateObject(wrappedValue: CheckoutViewModel(
            selectedSeats: selectedSeats,
            showtime: showtime,
            movie: movie,
            fnbItems: fnbItems
        ))
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView

                // Scrollable content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        orderSummaryCard
                        if viewModel.hasFnB { fnbSummarySection }
                        voucherSection
                        priceBreakdownSection
                        paymentMethodSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 120) // Space for bottom bar
                }
            }

            // Sticky bottom payment bar
            bottomPaymentBar

            // Processing overlay
            if viewModel.isProcessingPayment {
                paymentLoadingOverlay
            }

            // Hidden NavigationLink → Success View
            if let order = viewModel.completedOrder, let ticket = viewModel.completedTicket {
                NavigationLink(
                    destination: BookingSuccessView(order: order, ticket: ticket)
                        .environmentObject(router),
                    isActive: $navigateToSuccess
                ) { EmptyView() }
                .isDetailLink(false)
            }
        }
        .navigationBarHidden(true)
        .onChange(of: viewModel.paymentSuccess) { success in
            if success {
                HapticManager.shared.notification(type: .success)
                navigateToSuccess = true
            }
        }
        .alert(isPresented: Binding(
            get: { viewModel.paymentError != nil },
            set: { if !$0 { viewModel.paymentError = nil } }
        )) {
            Alert(
                title: Text("Lỗi thanh toán"),
                message: Text(viewModel.paymentError ?? "Đã có lỗi xảy ra."),
                dismissButton: .default(Text("Đồng ý"))
            )
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 14) {
            Button {
                guard !viewModel.isProcessingPayment else { return }
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }

            Text("Thanh toán")
                .font(.headingLarge)
                .foregroundColor(.textPrimary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 56)
        .padding(.bottom, 14)
        .background(Color(hex: "#0D0D1A"))
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1),
            alignment: .bottom
        )
    }

    // MARK: - Order Summary Card

    private var orderSummaryCard: some View {
        GlassCardView(cornerRadius: 16) {
            HStack(spacing: 14) {
                // Poster thumbnail
                if let posterURL = viewModel.movie.posterURL {
                    AsyncImage(url: posterURL) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.backgroundTertiary)
                    }
                    .frame(width: 60, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.movie.title)
                        .font(.headingMedium)
                        .foregroundColor(.textPrimary)
                        .lineLimit(2)

                    // Cinema + Hall
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 11))
                        Text("\(viewModel.showtime.cinemaName) - \(viewModel.showtime.hallName)")
                            .font(.bodySmall)
                            .lineLimit(1)
                    }
                    .foregroundColor(.textSecondary)

                    // Date + Time
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
                        Text("\(viewModel.selectedSeats.count) ghế: \(viewModel.seatLabels)")
                            .font(.bodySmall)
                    }
                    .foregroundColor(.accentTeal)
                }

                Spacer()
            }
            .padding(16)
        }
    }

    // MARK: - F&B Summary

    private var fnbSummarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Đồ ăn & Thức uống")
                .font(.headingSmall)
                .foregroundColor(.textPrimary)

            VStack(spacing: 8) {
                ForEach(viewModel.fnbItems, id: \.itemId) { item in
                    HStack {
                        Text(item.name)
                            .font(.bodySmall)
                            .foregroundColor(.textPrimary)
                        Text("×\(item.quantity)")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                        Spacer()
                        Text(item.formattedTotal)
                            .font(.bodySmall)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.backgroundSecondary)
            )
        }
    }

    // MARK: - Voucher Section

    private var voucherSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Mã giảm giá")
                .font(.headingSmall)
                .foregroundColor(.textPrimary)

            if viewModel.voucherApplied {
                // Applied state — tag with remove button
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.statusSuccess)
                    Text("Giảm \(CheckoutViewModel.formatVND(viewModel.discountAmount))")
                        .font(.bodySmall)
                        .foregroundColor(.statusSuccess)
                    Spacer()
                    Button {
                        viewModel.removeVoucher()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.textSecondary)
                            .font(.system(size: 18))
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.statusSuccess.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Color.statusSuccess.opacity(0.3), lineWidth: 1)
                        )
                )
            } else {
                // Input state
                HStack(spacing: 10) {
                    TextField("Nhập mã voucher", text: $viewModel.voucherCode)
                        .font(.bodyMedium)
                        .foregroundColor(.textPrimary)
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)

                    Button {
                        viewModel.applyVoucher()
                    } label: {
                        Text("Áp dụng")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.accentGold)
                            .cornerRadius(8)
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.backgroundSecondary)
                )

                // Error message
                if let error = viewModel.voucherError {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                        Text(error)
                            .font(.caption)
                    }
                    .foregroundColor(.statusError)
                    .padding(.leading, 4)
                }
            }
        }
        .animation(.cinematicSpring, value: viewModel.voucherApplied)
    }

    // MARK: - Price Breakdown

    private var priceBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Chi tiết giá")
                .font(.headingSmall)
                .foregroundColor(.textPrimary)

            VStack(spacing: 8) {
                // Ticket subtotal
                priceRow(
                    label: "Vé (\(viewModel.selectedSeats.count) ghế)",
                    amount: viewModel.subtotalTicket
                )

                // Format surcharge (if any)
                if viewModel.formatSurcharge > 0 {
                    priceRow(
                        label: viewModel.formatSurchargeLabel,
                        amount: viewModel.formatSurcharge
                    )
                }

                // F&B items
                ForEach(viewModel.fnbItems, id: \.itemId) { item in
                    priceRow(
                        label: "\(item.name) (×\(item.quantity))",
                        amount: item.totalPrice
                    )
                }

                // Discount (if applied)
                if viewModel.discountAmount > 0 {
                    HStack {
                        Text("Giảm giá voucher")
                            .font(.bodySmall)
                            .foregroundColor(.statusError)
                        Spacer()
                        Text("-\(CheckoutViewModel.formatVND(viewModel.discountAmount))")
                            .font(.bodySmall)
                            .foregroundColor(.statusError)
                    }
                }

                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)
                    .padding(.vertical, 4)

                // Total
                HStack {
                    Text("TỔNG CỘNG")
                        .font(.headingMedium)
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Text(viewModel.formattedTotal)
                        .font(.displayMedium)
                        .foregroundColor(.accentTeal)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.backgroundSecondary)
            )
        }
    }

    // MARK: - Payment Method Section

    private var paymentMethodSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Phương thức thanh toán")
                .font(.headingSmall)
                .foregroundColor(.textPrimary)

            VStack(spacing: 8) {
                ForEach(PaymentMethod.allCases, id: \.self) { method in
                    // Mock Pay chỉ hiện trong DEBUG
                    if method == .mockPay {
                        #if DEBUG
                        PaymentMethodCard(
                            method: method,
                            isSelected: viewModel.selectedPaymentMethod == method,
                            onTap: { viewModel.selectPaymentMethod(method) }
                        )
                        #endif
                    } else {
                        PaymentMethodCard(
                            method: method,
                            isSelected: viewModel.selectedPaymentMethod == method,
                            onTap: { viewModel.selectPaymentMethod(method) }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Bottom Payment Bar

    private var bottomPaymentBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)

            HStack(spacing: 12) {
                // Total summary
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tổng cộng")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    Text(viewModel.formattedTotal)
                        .font(.headingMedium)
                        .foregroundColor(.accentTeal)
                }

                Spacer()

                // CTA Button
                CinematicButton(
                    "Thanh toán",
                    variant: .primary,
                    isLoading: viewModel.isProcessingPayment
                ) {
                    if !appViewModel.isAuthenticated {
                        appViewModel.showLoginSheet = true
                    } else {
                        viewModel.processPayment()
                    }
                }
                .frame(width: 180)
                .disabled(!viewModel.canPay)
                .opacity(viewModel.canPay ? 1 : 0.5)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    BlurView(style: .systemUltraThinMaterialDark)
                    Color(hex: "#0D0D1A").opacity(0.7)
                }
                .ignoresSafeArea(edges: .bottom)
            )
        }
    }

    // MARK: - Payment Loading Overlay

    private var paymentLoadingOverlay: some View {
        Color.black.opacity(0.6).ignoresSafeArea()
            .overlay(
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(Color.accentTeal)
                        .scaleEffect(1.4)
                    Text("Đang xử lý thanh toán...")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(28)
                .background(Color.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            )
            .transition(.opacity)
    }

    // MARK: - Helpers

    private func priceRow(label: String, amount: Decimal) -> some View {
        HStack {
            Text(label)
                .font(.bodySmall)
                .foregroundColor(.textSecondary)
            Spacer()
            Text(CheckoutViewModel.formatVND(amount))
                .font(.bodySmall)
                .foregroundColor(.textPrimary)
        }
    }

    private var formattedShowtime: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "dd/MM/yyyy, HH:mm"
        return formatter.string(from: viewModel.showtime.startTime)
    }
}
