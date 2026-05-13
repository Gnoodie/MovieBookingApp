import SwiftUI

// MARK: - SeatMapCanvas

/// Component render bản đồ ghế sử dụng SwiftUI Canvas (hiệu năng cao cho hàng trăm ghế)
/// iOS 15.0+ compatible
struct SeatMapCanvas: View {
    let layout: SeatMapLayout
    let selectedSeatIds: Set<String>
    let onSeatTapped: (Seat) -> Void
    
    // MARK: - View State
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geo in
            let canvasSize = layout.mapSize
            
            // Căn giữa map khi zoom out
            let xOffset = max(0, (geo.size.width - (canvasSize.width * scale)) / 2)
            let yOffset = max(0, (geo.size.height - (canvasSize.height * scale)) / 2)
            
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#0D0D1A"), Color(hex: "#09090C")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: geo.size.width, height: geo.size.height)
                    .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 8)

                Canvas { context, size in
                    // 1. Áp dụng transform cho zoom và pan
                    context.translateBy(x: offset.width, y: offset.height)
                    context.scaleBy(x: scale, y: scale)
                    
                    // 2. Vẽ màn hình (Screen Curve)
                    drawScreen(context: context, width: canvasSize.width)
                    
                    // 3. Vẽ nhãn hàng (A, B, C)
                    drawRowLabels(context: context)
                    
                    // 4. Vẽ tất cả các ghế
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
                        .onEnded { _ in
                            lastScale = 1.0
                        }
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
                                // ✅ KHÔNG truyền xOffset/yOffset vào đây
                                // vì Canvas đã bị .offset() bởi SwiftUI,
                                // DragGesture.location đã tính theo vị trí thực của Canvas
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
    
    // MARK: - Taps

    private func handleTap(at location: CGPoint) {
        let tapX = (location.x - offset.width) / scale
        let tapY = (location.y - offset.height) / scale
        let point = CGPoint(x: tapX, y: tapY)

        if let seat = layout.seat(at: point) {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            onSeatTapped(seat)
        }
    }

    // MARK: - Drawing Functions
    
    private func drawScreen(context: GraphicsContext, width: CGFloat) {
        let screenRect = CGRect(
            x: SeatMapLayout.rowLabelWidth + SeatMapLayout.rowLabelMargin,
            y: 0,
            width: width - (SeatMapLayout.rowLabelWidth + SeatMapLayout.rowLabelMargin),
            height: SeatMapLayout.screenCurveHeight
        )
        
        let screenBackground = CGRect(
            x: screenRect.minX,
            y: screenRect.minY + 6,
            width: screenRect.width,
            height: screenRect.height - 6
        )
        let backgroundPath = Path(roundedRect: screenBackground, cornerRadius: screenBackground.height / 2)
        context.fill(
            backgroundPath,
            with: .color(Color.white.opacity(0.08))
        )

        var path = Path()
        path.move(to: CGPoint(x: screenRect.minX, y: screenRect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: screenRect.maxX, y: screenRect.maxY),
            control: CGPoint(x: screenRect.midX, y: screenRect.minY)
        )
        
        context.stroke(
            path,
            with: .color(Color(hex: "#888888")),
            style: StrokeStyle(lineWidth: 6, lineCap: .round)
        )
        
        let text = Text("MÀN HÌNH")
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.gray)
        let resolvedText = context.resolve(text)
        context.draw(
            resolvedText,
            at: CGPoint(x: screenRect.midX, y: screenRect.maxY + 12),
            anchor: .top
        )
    }
    
    private func drawRowLabels(context: GraphicsContext) {
        for (rowIndex, row) in layout.rows.enumerated() {
            let yPos = SeatMapLayout.screenCurveHeight + SeatMapLayout.screenMarginBottom +
                       CGFloat(rowIndex) * (SeatMapLayout.seatHeight + SeatMapLayout.rowSpacing)
            
            let labelRect = CGRect(
                x: 0,
                y: yPos + (SeatMapLayout.seatHeight - 28) / 2,
                width: SeatMapLayout.rowLabelWidth,
                height: 28
            )
            let labelPath = Path(roundedRect: labelRect, cornerRadius: 14)
            context.fill(
                labelPath,
                with: .color(Color.white.opacity(0.08))
            )

            let text = Text(row)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            let resolvedText = context.resolve(text)

            context.draw(
                resolvedText,
                at: CGPoint(x: labelRect.midX, y: labelRect.midY),
                anchor: .center
            )
        }
    }
    
    private func drawSeats(context: GraphicsContext) {
        for seat in layout.seats {
            guard let frame = layout.seatFrames[seat.id] else { continue }
            
            let isSelected = selectedSeatIds.contains(seat.id)
            let fillColor = seatColor(for: seat, isSelected: isSelected)
            let borderColor = isSelected ? Color(hex: "#00D2D3") : Color.clear
            
            let path = Path(roundedRect: frame, cornerRadius: 6)
            
            // Vẽ nền ghế
            context.fill(path, with: .color(fillColor))
            
            // Vẽ viền nếu đang chọn
            if isSelected {
                context.stroke(path, with: .color(borderColor), lineWidth: 2)
            }
            
            // Vẽ số ghế (chỉ hiện khi zoom đủ lớn)
            if scale > 0.8 {
                let text = Text("\(seat.number)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                
                context.draw(
                    context.resolve(text),
                    at: CGPoint(x: frame.midX, y: frame.midY),
                    anchor: .center
                )
            }
        }
    }
    
    private func seatColor(for seat: Seat, isSelected: Bool) -> Color {
        if isSelected {
            return Color(hex: "#00D2D3") // Mint
        }
        
        switch seat.status {
        case .booked, .held:
            return Color(hex: "#57606F") // Gray
        case .mine:
            return Color(hex: "#00D2D3")
        case .available:
            switch seat.type {
            case .standard: return Color(hex: "#5B8DEF") // Navy
            case .vip: return Color(hex: "#FF9F43") // Amber
            case .couple: return Color(hex: "#FF6B9D") // Pink
            case .wheelchair: return Color(hex: "#5B8DEF")
            case .unavailable: return .clear
            }
        case .unavailable:
            return .clear
        }
    }
}
