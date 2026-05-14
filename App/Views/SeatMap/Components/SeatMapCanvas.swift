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
                .accessibilityHidden(true) // Ẩn Canvas khỏi VoiceOver
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
            // Phase 5: Thêm khả năng đọc VoiceOver cho bản đồ ghế vẽ bằng Canvas
            .accessibilityElement(children: .contain)
            .accessibilityChildren {
                ForEach(layout.seats) { seat in
                    if seat.status != .unavailable && seat.type != .unavailable {
                        Rectangle()
                            .frame(
                                width: (layout.seatFrames[seat.id]?.width ?? 0) * scale,
                                height: (layout.seatFrames[seat.id]?.height ?? 0) * scale
                            )
                            .position(
                                x: ((layout.seatFrames[seat.id]?.midX ?? 0) * scale) + offset.width + xOffset,
                                y: ((layout.seatFrames[seat.id]?.midY ?? 0) * scale) + offset.height + yOffset
                            )
                            .accessibilityLabel("Ghế \(seat.row)\(seat.number), Loại \(accessibilitySeatType(seat.type))")
                            .accessibilityValue(accessibilitySeatStatus(seat.status))
                            .accessibilityAddTraits(selectedSeatIds.contains(seat.id) ? .isSelected : [])
                            .accessibilityAction {
                                onSeatTapped(seat)
                            }
                    }
                }
            }
        }
    }
    
    // MARK: - Accessibility Helpers
    private func accessibilitySeatType(_ type: SeatType) -> String {
        switch type {
        case .standard: return "Thường"
        case .vip: return "VIP"
        case .couple: return "Đôi"
        case .wheelchair: return "Dành cho xe lăn"
        case .unavailable: return "Không khả dụng"
        }
    }
    
    private func accessibilitySeatStatus(_ status: SeatStatus) -> String {
        switch status {
        case .available: return "Còn trống. Chạm đúp để chọn."
        case .booked: return "Đã bán."
        case .held: return "Đang được người khác giữ."
        case .mine: return "Bạn đang chọn."
        case .unavailable: return "Không thể chọn."
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
            drawSingleSeat(context: context, seat: seat)

            guard !drawnPairs.contains(seat.id),
                  let groupId = seat.coupleGroupId else { continue }

            if let partner = coupleSeats.first(where: {
                $0.id != seat.id && $0.coupleGroupId == groupId
            }) {
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

    /// Vẽ dấu nối giữa 2 ghế couple: bracket phía dưới + icon ♥ ở giữa
    private func drawCoupleBracket(context: GraphicsContext, leftSeat: Seat, rightSeat: Seat) {
        guard
            let leftFrame  = layout.seatFrames[leftSeat.id],
            let rightFrame = layout.seatFrames[rightSeat.id]
        else { return }

        let isEitherSelected  = selectedSeatIds.contains(leftSeat.id) || selectedSeatIds.contains(rightSeat.id)
        let isEitherUnavailable = leftSeat.status == .booked || leftSeat.status == .held
                               || rightSeat.status == .booked || rightSeat.status == .held

        // Màu connector theo trạng thái cặp
        let accentColor: Color
        if isEitherSelected {
            accentColor = Color(hex: "#39D98A")           // Đang chọn → xanh mint
        } else if isEitherUnavailable {
            accentColor = Color(hex: "#FF6B9D").opacity(0.2) // 1 trong 2 đã đặt → mờ
        } else {
            accentColor = Color(hex: "#FF6B9D").opacity(0.7) // Cả 2 trống → hồng
        }

        let midX = (leftFrame.maxX + rightFrame.minX) / 2
        let midY = leftFrame.midY

        // Bracket phía dưới
        if scale > 0.7 {
            let bracketY = leftFrame.maxY + 3
            var bracketPath = Path()
            bracketPath.move(to: CGPoint(x: leftFrame.midX,  y: bracketY))
            bracketPath.addLine(to: CGPoint(x: leftFrame.midX,  y: bracketY + 4))
            bracketPath.addLine(to: CGPoint(x: rightFrame.midX, y: bracketY + 4))
            bracketPath.addLine(to: CGPoint(x: rightFrame.midX, y: bracketY))
            context.stroke(bracketPath,
                           with: .color(accentColor.opacity(0.6)),
                           style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
        }

        // Icon ♥
        guard scale > 0.65 else { return }
        let heartSize: CGFloat = isEitherSelected ? 12 : 10
        let heartText = Text("♥")
            .font(.system(size: heartSize, weight: .bold))
            .foregroundColor(accentColor)
        context.draw(context.resolve(heartText),
                     at: CGPoint(x: midX, y: midY),
                     anchor: .center)

        // Nếu 1 trong 2 đã booked: vẽ dấu ✕ nhỏ trên ♥ để báo không thể chọn
        if isEitherUnavailable && scale > 0.8 {
            let xText = Text("✕")
                .font(.system(size: 7, weight: .black))
                .foregroundColor(Color.red.opacity(0.6))
            context.draw(context.resolve(xText),
                         at: CGPoint(x: midX + 7, y: midY - 5),
                         anchor: .center)
        }
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