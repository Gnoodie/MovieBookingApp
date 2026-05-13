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
    // Không cần tính thêm — SeatMapLayout.calculateLayout() đã set frame couple = seatWidth*2 + seatSpacing

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
        let regularSeats = layout.seats.filter { $0.type != .couple }
        let coupleSeats  = layout.seats.filter { $0.type == .couple }

        for seat in regularSeats {
            drawSingleSeat(context: context, seat: seat)
        }

        // Vẽ couple theo cặp — mỗi cặp chỉ vẽ connector 1 lần
        var drawnPairs = Set<String>()
        for seat in coupleSeats {
            drawSingleSeat(context: context, seat: seat) // vẽ ghế như bình thường

            // Vẽ connector ♥ giữa 2 ghế — chỉ 1 lần cho mỗi cặp
            guard !drawnPairs.contains(seat.id) else { continue }
            if let partner = coupleSeats.first(where: {
                $0.id != seat.id
                && $0.row == seat.row
                && abs($0.number - seat.number) == 1
            }) {
                // Đánh dấu cả 2 đã xử lý
                drawnPairs.insert(seat.id)
                drawnPairs.insert(partner.id)

                let leftSeat  = seat.number < partner.number ? seat : partner
                let rightSeat = seat.number < partner.number ? partner : seat

                drawCoupleBracket(context: context, leftSeat: leftSeat, rightSeat: rightSeat)
            }
        }
    }

    /// Vẽ ghế đơn — dùng chung cho tất cả loại ghế kể cả couple (mỗi ghế là 1 ô riêng)
    private func drawSingleSeat(context: GraphicsContext, seat: Seat) {
        guard let frame = layout.seatFrames[seat.id] else { return }
        let isSelected = selectedSeatIds.contains(seat.id)
        renderSeatShape(context: context, frame: frame, seat: seat, isSelected: isSelected)
    }

    /// Vẽ dấu nối giữa 2 ghế couple: đường bracket phía dưới + icon ♥ ở giữa
    private func drawCoupleBracket(context: GraphicsContext, leftSeat: Seat, rightSeat: Seat) {
        guard
            let leftFrame  = layout.seatFrames[leftSeat.id],
            let rightFrame = layout.seatFrames[rightSeat.id]
        else { return }

        let isEitherSelected = selectedSeatIds.contains(leftSeat.id) || selectedSeatIds.contains(rightSeat.id)
        let isBooked = leftSeat.status == .booked || leftSeat.status == .held

        let accentColor: Color = isEitherSelected
            ? Color(hex: "#39D98A")
            : isBooked
                ? Color(hex: "#FF6B9D").opacity(0.2)
                : Color(hex: "#FF6B9D").opacity(0.7)

        // Khoảng giữa 2 ghế
        let gapMinX = leftFrame.maxX
        let gapMaxX = rightFrame.minX
        let midX    = (gapMinX + gapMaxX) / 2
        let midY    = leftFrame.midY

        // Bracket phía dưới nối 2 ghế
        if scale > 0.7 {
            let bracketY = leftFrame.maxY + 3
            var bracketPath = Path()
            bracketPath.move(to: CGPoint(x: leftFrame.midX, y: bracketY))
            bracketPath.addLine(to: CGPoint(x: leftFrame.midX, y: bracketY + 4))
            bracketPath.addLine(to: CGPoint(x: rightFrame.midX, y: bracketY + 4))
            bracketPath.addLine(to: CGPoint(x: rightFrame.midX, y: bracketY))
            context.stroke(bracketPath, with: .color(accentColor.opacity(0.6)),
                           style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
        }

        // Icon ♥ ở giữa khoảng gap
        guard scale > 0.65 else { return }
        let heartSize: CGFloat = isEitherSelected ? 12 : 10
        let heartText = Text("♥")
            .font(.system(size: heartSize, weight: .bold))
            .foregroundColor(accentColor)
        context.draw(context.resolve(heartText),
                     at: CGPoint(x: midX, y: midY),
                     anchor: .center)
    }

    /// Render shape + màu + viền + số ghế cho 1 ô ghế
    private func renderSeatShape(context: GraphicsContext, frame: CGRect, seat: Seat, isSelected: Bool) {
        let isUnavailable = seat.status == .unavailable || seat.type == .unavailable
        guard !isUnavailable else { return }

        let cornerRadius: CGFloat = 6
        let path = Path(roundedRect: frame, cornerRadius: cornerRadius)

        // --- Fill ---
        let fillColor = seatFillColor(for: seat, isSelected: isSelected)
        context.fill(path, with: .color(fillColor))

        // --- Top highlight ---
        if seat.status == .available || isSelected {
            let highlightRect = CGRect(x: frame.minX + 2, y: frame.minY + 1,
                                       width: frame.width - 4, height: frame.height * 0.4)
            let highlightPath = Path(roundedRect: highlightRect, cornerRadius: 5)
            context.fill(highlightPath, with: .color(Color.white.opacity(0.12)))
        }

        // --- Border ---
        if isSelected {
            context.stroke(path, with: .color(Color(hex: "#39D98A")), lineWidth: 2)
        } else if seat.type == .couple && seat.status == .available {
            context.stroke(path, with: .color(Color(hex: "#FF6B9D").opacity(0.5)), lineWidth: 1)
        } else if seat.type == .vip && seat.status == .available {
            context.stroke(path, with: .color(Color(hex: "#FF9F43").opacity(0.5)), lineWidth: 1)
        }

        // --- Số ghế bên trong ---
        guard scale > 0.65 else { return }

        let numberText = Text("\(seat.number)")
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundColor(
                seat.status == .booked || seat.status == .held
                    ? Color.white.opacity(0.25)
                    : .white
            )
        context.draw(context.resolve(numberText),
                     at: CGPoint(x: frame.midX, y: frame.midY),
                     anchor: .center)
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