import SwiftUI

// MARK: - SeatMapCanvas

/// Component render bản đồ ghế sử dụng SwiftUI Canvas (hiệu năng cao cho hàng trăm ghế)
/// iOS 15.0+ compatible
/// v2: Fix ghế couple render đúng kích thước 2x, cải thiện visual
struct SeatMapCanvas: View {
    let layout: SeatMapLayout
    let selectedSeatIds: Set<String>
    let onSeatTapped: (Seat) -> Void

    // MARK: - View State
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    // MARK: - Constants
    private let coupleExtraWidth: CGFloat = SeatMapLayout.seatWidth + SeatMapLayout.colSpacing

    var body: some View {
        GeometryReader { geo in
            let canvasSize = layout.mapSize
            let xOffset = max(0, (geo.size.width - canvasSize.width * scale) / 2)
            let yOffset = max(0, (geo.size.height - canvasSize.height * scale) / 2)

            ZStack(alignment: .topLeading) {
                // Background gradient
                LinearGradient(
                    colors: [Color(hex: "#0A0A14"), Color(hex: "#06060C")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                Canvas { context, size in
                    context.translateBy(x: offset.width, y: offset.height)
                    context.scaleBy(x: scale, y: scale)

                    drawScreen(context: context, width: canvasSize.width)
                    drawRowLabels(context: context)
                    drawSeats(context: context)
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .gesture(
                    MagnificationGesture()
                        .onChanged { val in
                            let delta = val / lastScale
                            lastScale = val
                            scale = min(max(scale * delta, 0.5), 3.0)
                        }
                        .onEnded { _ in lastScale = 1.0 }
                )
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { val in
                            if abs(val.translation.width) > 10 || abs(val.translation.height) > 10 {
                                offset = CGSize(
                                    width: lastOffset.width + val.translation.width,
                                    height: lastOffset.height + val.translation.height
                                )
                            }
                        }
                        .onEnded { val in
                            if abs(val.translation.width) < 10 && abs(val.translation.height) < 10 {
                                handleTap(at: val.location)
                            } else {
                                lastOffset = offset
                            }
                        }
                )
                .offset(x: xOffset, y: yOffset)
            }
            .clipped()
        }
    }

    // MARK: - Tap Handling

    private func handleTap(at location: CGPoint) {
        let tapX = (location.x - offset.width) / scale
        let tapY = (location.y - offset.height) / scale
        let point = CGPoint(x: tapX, y: tapY)

        // Kiểm tra ghế couple trước (frame rộng hơn)
        if let seat = layout.seat(at: point) {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            onSeatTapped(seat)
        }
    }

    // MARK: - Drawing: Screen

    private func drawScreen(context: GraphicsContext, width: CGFloat) {
        let leftEdge = SeatMapLayout.rowLabelWidth + SeatMapLayout.rowLabelMargin
        let screenWidth = width - leftEdge

        let screenRect = CGRect(
            x: leftEdge,
            y: 0,
            width: screenWidth,
            height: SeatMapLayout.screenCurveHeight
        )

        // Glow background
        let bgRect = CGRect(x: screenRect.minX, y: screenRect.minY + 8, width: screenRect.width, height: screenRect.height - 8)
        let bgPath = Path(roundedRect: bgRect, cornerRadius: bgRect.height / 2)
        context.fill(bgPath, with: .color(Color.white.opacity(0.05)))

        // Screen curve
        var path = Path()
        path.move(to: CGPoint(x: screenRect.minX + 12, y: screenRect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: screenRect.maxX - 12, y: screenRect.maxY),
            control: CGPoint(x: screenRect.midX, y: screenRect.minY + 4)
        )
        context.stroke(path, with: .linearGradient(
            Gradient(colors: [Color(hex: "#888888").opacity(0.3), Color(hex: "#CCCCCC"), Color(hex: "#888888").opacity(0.3)]),
            startPoint: CGPoint(x: screenRect.minX, y: 0),
            endPoint: CGPoint(x: screenRect.maxX, y: 0)
        ), style: StrokeStyle(lineWidth: 3, lineCap: .round))

        // Label
        let label = Text("MÀN HÌNH")
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundColor(Color(hex: "#666666"))
        context.draw(context.resolve(label),
                     at: CGPoint(x: screenRect.midX, y: screenRect.maxY + 10),
                     anchor: .top)
    }

    // MARK: - Drawing: Row Labels

    private func drawRowLabels(context: GraphicsContext) {
        for (rowIndex, row) in layout.rows.enumerated() {
            let yPos = SeatMapLayout.screenCurveHeight + SeatMapLayout.screenMarginBottom
                + CGFloat(rowIndex) * (SeatMapLayout.seatHeight + SeatMapLayout.rowSpacing)

            let labelRect = CGRect(
                x: 2,
                y: yPos + (SeatMapLayout.seatHeight - 24) / 2,
                width: SeatMapLayout.rowLabelWidth - 4,
                height: 24
            )

            let labelPath = Path(roundedRect: labelRect, cornerRadius: 12)
            context.fill(labelPath, with: .color(Color.white.opacity(0.07)))

            let text = Text(row)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "#888888"))
            context.draw(context.resolve(text), at: CGPoint(x: labelRect.midX, y: labelRect.midY), anchor: .center)
        }
    }

    // MARK: - Drawing: Seats

    private func drawSeats(context: GraphicsContext) {
        // Tách ghế đơn và ghế couple để vẽ đúng thứ tự (couple sau cùng tránh bị che)
        let regularSeats = layout.seats.filter { $0.type != .couple }
        let coupleSeats  = layout.seats.filter { $0.type == .couple }

        for seat in regularSeats {
            drawSingleSeat(context: context, seat: seat)
        }
        for seat in coupleSeats {
            drawCoupleSeat(context: context, seat: seat)
        }
    }

    /// Vẽ ghế đơn (standard, VIP, wheelchair)
    private func drawSingleSeat(context: GraphicsContext, seat: Seat) {
        guard let frame = layout.seatFrames[seat.id] else { return }
        let isSelected = selectedSeatIds.contains(seat.id)
        renderSeatShape(context: context, frame: frame, seat: seat, isSelected: isSelected, isCouple: false)
    }

    /// Vẽ ghế couple — frame rộng gấp đôi, bo tròn đặc biệt, icon trái tim
    private func drawCoupleSeat(context: GraphicsContext, seat: Seat) {
        guard let baseFrame = layout.seatFrames[seat.id] else { return }

        // Mở rộng frame sang phải để bao phủ 2 vị trí ghế
        let coupleFrame = CGRect(
            x: baseFrame.minX,
            y: baseFrame.minY,
            width: baseFrame.width + coupleExtraWidth,
            height: baseFrame.height
        )

        let isSelected = selectedSeatIds.contains(seat.id)
        renderSeatShape(context: context, frame: coupleFrame, seat: seat, isSelected: isSelected, isCouple: true)
    }

    /// Render shape + màu + viền + số ghế cho 1 ô ghế
    private func renderSeatShape(context: GraphicsContext, frame: CGRect, seat: Seat, isSelected: Bool, isCouple: Bool) {
        let isUnavailable = seat.status == .unavailable || seat.type == .unavailable
        guard !isUnavailable else { return }

        let cornerRadius: CGFloat = isCouple ? 10 : 6
        let path = Path(roundedRect: frame, cornerRadius: cornerRadius)

        // --- Fill ---
        let fillColor = seatFillColor(for: seat, isSelected: isSelected)
        context.fill(path, with: .color(fillColor))

        // --- Top highlight (glassmorphism feel) ---
        if seat.status == .available || isSelected {
            let highlightRect = CGRect(x: frame.minX + 2, y: frame.minY + 1,
                                       width: frame.width - 4, height: frame.height * 0.4)
            let highlightPath = Path(roundedRect: highlightRect, cornerRadius: cornerRadius - 1)
            context.fill(highlightPath, with: .color(Color.white.opacity(0.12)))
        }

        // --- Border ---
        if isSelected {
            context.stroke(path, with: .color(Color(hex: "#39D98A")), lineWidth: 2)
        } else if isCouple && seat.status == .available {
            context.stroke(path, with: .color(Color(hex: "#FF6B9D").opacity(0.6)), lineWidth: 1)
        } else if seat.type == .vip && seat.status == .available {
            context.stroke(path, with: .color(Color(hex: "#FF9F43").opacity(0.5)), lineWidth: 1)
        }

        // --- Nội dung bên trong ---
        guard scale > 0.65 else { return }

        if isCouple {
            // Ghế couple: icon ♥ + tên ghế
            let heartText = Text("♥")
                .font(.system(size: isSelected ? 14 : 11))
                .foregroundColor(isSelected ? .white : Color(hex: "#FF6B9D").opacity(0.9))
            context.draw(context.resolve(heartText),
                         at: CGPoint(x: frame.midX, y: frame.midY - (scale > 1.2 ? 6 : 0)),
                         anchor: .center)

            if scale > 1.2 {
                let label = Text("\(seat.number)")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                context.draw(context.resolve(label),
                             at: CGPoint(x: frame.midX, y: frame.midY + 8),
                             anchor: .center)
            }
        } else {
            // Ghế thường/VIP: số ghế
            let numberText = Text("\(seat.number)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(seat.status == .booked || seat.status == .held ? Color.white.opacity(0.3) : .white)
            context.draw(context.resolve(numberText),
                         at: CGPoint(x: frame.midX, y: frame.midY),
                         anchor: .center)
        }
    }

    // MARK: - Color Logic

    private func seatFillColor(for seat: Seat, isSelected: Bool) -> Color {
        if isSelected { return Color(hex: "#39D98A") }

        switch seat.status {
        case .booked, .held:
            return Color(hex: "#2A2A3A")
        case .mine:
            return Color(hex: "#39D98A")
        case .available:
            switch seat.type {
            case .standard:    return Color(hex: "#5B8DEF")
            case .vip:         return Color(hex: "#FF9F43")
            case .couple:      return Color(hex: "#C2185B")
            case .wheelchair:  return Color(hex: "#5B8DEF")
            case .unavailable: return .clear
            }
        case .unavailable:
            return .clear
        }
    }
}