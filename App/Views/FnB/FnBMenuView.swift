import SwiftUI

// MARK: - FnBMenuView

/// Màn hình chọn đồ ăn & thức uống (F&B)
/// Nằm giữa SeatMapView và CheckoutView trong luồng đặt vé
struct FnBMenuView: View {
    @StateObject private var viewModel: FnBViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var router: AppRouter

    /// Callback khi user bấm "Tiếp tục" (có hoặc không có F&B)
    let onContinue: ([FnBOrderItem]) -> Void

    init(
        selectedSeats: [Seat],
        showtime: Showtime,
        movie: Movie,
        onContinue: @escaping ([FnBOrderItem]) -> Void
    ) {
        _viewModel = StateObject(wrappedValue: FnBViewModel(
            selectedSeats: selectedSeats,
            showtime: showtime,
            movie: movie
        ))
        self.onContinue = onContinue
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "#000000").ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: Header
                headerView

                // MARK: Category Tabs
                categoryTabsView
                    .padding(.top, 12)

                // MARK: Item Grid
                if viewModel.isLoading {
                    loadingView
                } else {
                    itemGridView
                }

                // Bottom padding for cart bar
                Spacer().frame(height: 100)
            }

            // MARK: Bottom Cart Bar
            bottomCartBar
        }
        .navigationBarHidden(true)
        .onAppear { viewModel.onAppear() }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(alignment: .center) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }

            Spacer()

            VStack(spacing: 2) {
                Text("Đồ ăn & thức uống")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                Text(viewModel.movie.title)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }

            Spacer()

            // Nút Bỏ qua
            Button {
                onContinue([]) // Bỏ qua F&B — truyền giỏ rỗng
            } label: {
                Text("Bỏ qua")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#00D2D3"))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 56)
        .padding(.bottom, 12)
        .background(Color(hex: "#1C1C1E"))
    }

    // MARK: - Category Tabs

    private var categoryTabsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FnBCategory.allCases, id: \.self) { category in
                    let isSelected = viewModel.selectedCategory == category
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectCategory(category)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(category.icon)
                                .font(.system(size: 14))
                            Text(category.displayName)
                                .font(.system(size: 14, weight: isSelected ? .bold : .regular))
                                .foregroundColor(isSelected ? Color(hex: "#000000") : .white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            isSelected
                                ? Color(hex: "#00D2D3")
                                : Color(hex: "#1C1C1E")
                        )
                        .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Item Grid

    private var itemGridView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.filteredItems) { item in
                    FnBItemCard(
                        item: item,
                        quantity: viewModel.quantity(for: item.id),
                        onIncrease: { viewModel.increaseQuantity(for: item) },
                        onDecrease: { viewModel.decreaseQuantity(for: item) }
                    )
                }
            }
            .padding(16)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .tint(Color(hex: "#00D2D3"))
                .scaleEffect(1.5)
            Text("Đang tải menu...")
                .foregroundColor(.gray)
                .font(.system(size: 14))
                .padding(.top, 12)
            Spacer()
        }
    }

    // MARK: - Bottom Cart Bar

    private var bottomCartBar: some View {
        VStack(spacing: 0) {
            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)

            HStack(spacing: 12) {
                // Cart summary
                VStack(alignment: .leading, spacing: 2) {
                    if viewModel.totalQuantity == 0 {
                        Text("Chưa chọn gì")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    } else {
                        Text("\(viewModel.totalQuantity) món")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        Text(viewModel.formattedTotalFnB)
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#00D2D3"))
                    }
                }

                Spacer()

                // CTA Button
                Button {
                    onContinue(viewModel.cartItems)
                } label: {
                    HStack(spacing: 6) {
                        Text("Tiếp tục")
                            .font(.system(size: 15, weight: .bold))
                        if viewModel.totalQuantity > 0 {
                            Text("(\(viewModel.totalQuantity))")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(hex: "#00D2D3"))
                    .cornerRadius(12)
                }
            }
            .padding(16)
            .background(
                Color(hex: "#1C1C1E").opacity(0.95)
                    .background(BlurView(style: .systemThinMaterialDark))
                    .ignoresSafeArea(edges: .bottom)
            )
        }
    }
}

// MARK: - FnBItemCard

private struct FnBItemCard: View {
    let item: FnBItem
    let quantity: Int
    let onIncrease: () -> Void
    let onDecrease: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Ảnh / Emoji placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "#1C1C1E"))
                    .frame(height: 100)

                if let url = item.imageURL {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        categoryEmoji
                    }
                    .frame(height: 100)
                    .clipped()
                    .cornerRadius(10)
                } else {
                    categoryEmoji
                }
            }

            // Tên + Mô tả
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(item.description)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }

            // Giá + Stepper
            HStack {
                Text(item.formattedPrice)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "#00D2D3"))

                Spacer()

                // Stepper
                HStack(spacing: 8) {
                    if quantity > 0 {
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                onDecrease()
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(Color(hex: "#FF6B6B"))
                        }

                        Text("\(quantity)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(minWidth: 20)
                            .transition(.scale)
                    }

                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            onIncrease()
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color(hex: "#00D2D3"))
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#1C1C1E"))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            quantity > 0 ? Color(hex: "#00D2D3").opacity(0.6) : Color.clear,
                            lineWidth: 1.5
                        )
                )
        )
        .animation(.easeInOut(duration: 0.2), value: quantity)
    }

    private var categoryEmoji: some View {
        Text(item.category.icon)
            .font(.system(size: 36))
    }
}
