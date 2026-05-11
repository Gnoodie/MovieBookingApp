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
                // Pinch to Zoom
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
                                handleTap(at: val.location, xOffset: xOffset, yOffset: yOffset)
                            } else {
                                lastOffset = offset
                            }
                        }
                )
                // Áp dụng offset căn giữa nếu map nhỏ hơn màn hình
                .offset(x: xOffset, y: yOffset)
            }
            .clipped()
        }
    }
    
    // MARK: - Taps

    private func handleTap(at location: CGPoint, xOffset: CGFloat, yOffset: CGFloat) {
        let tapX = (location.x - offset.width - xOffset) / scale
        let tapY = (location.y - offset.height - yOffset) / scale
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
        
        var path = Path()
        path.move(to: CGPoint(x: screenRect.minX, y: screenRect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: screenRect.maxX, y: screenRect.maxY),
            control: CGPoint(x: screenRect.midX, y: screenRect.minY)
        )
        
        context.stroke(
            path,
            with: .color(Color(hex: "#D4AF37").opacity(0.8)),
            lineWidth: 4
        )
        
        // Chữ "MÀN HÌNH"
        let text = Text("MÀN HÌNH")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.gray)
        let resolvedText = context.resolve(text)
        context.draw(
            resolvedText,
            at: CGPoint(x: screenRect.midX, y: screenRect.maxY + 10),
            anchor: .top
        )
    }
    
    private func drawRowLabels(context: GraphicsContext) {
        for (rowIndex, row) in layout.rows.enumerated() {
            let yPos = SeatMapLayout.screenCurveHeight + SeatMapLayout.screenMarginBottom +
                       CGFloat(rowIndex) * (SeatMapLayout.seatHeight + SeatMapLayout.rowSpacing)
            
            let text = Text(row)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
            let resolvedText = context.resolve(text)
            
            context.draw(
                resolvedText,
                at: CGPoint(x: SeatMapLayout.rowLabelWidth / 2, y: yPos + SeatMapLayout.seatHeight / 2),
                anchor: .center
            )
        }
    }
    
    private func drawSeats(context: GraphicsContext) {
        for seat in layout.seats {
            guard let frame = layout.seatFrames[seat.id] else { continue }
            
            let isSelected = selectedSeatIds.contains(seat.id)
            let fillColor = seatColor(for: seat, isSelected: isSelected)
            let borderColor = isSelected ? Color(hex: "#D4AF37") : Color.clear
            
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
                    .foregroundColor(seat.status == .available || isSelected ? .black : .white.opacity(0.5))
                
                context.draw(
                    context.resolve(text),
                    at: CGPoint(x: frame.midX, y: frame.midY),
                    anchor: .center
                )
            }
            
            // Vẽ dấu X nếu đã booked
            if seat.status == .booked {
                var crossPath = Path()
                crossPath.move(to: CGPoint(x: frame.minX + 6, y: frame.minY + 6))
                crossPath.addLine(to: CGPoint(x: frame.maxX - 6, y: frame.maxY - 6))
                crossPath.move(to: CGPoint(x: frame.maxX - 6, y: frame.minY + 6))
                crossPath.addLine(to: CGPoint(x: frame.minX + 6, y: frame.maxY - 6))
                context.stroke(crossPath, with: .color(.white.opacity(0.5)), lineWidth: 2)
            }
        }
    }
    
    private func seatColor(for seat: Seat, isSelected: Bool) -> Color {
        if isSelected {
            return Color(hex: "#D4AF37") // Gold
        }
        
        switch seat.status {
        case .booked, .held:
            return Color(hex: "#333333") // Xám đậm
        case .mine:
            return Color(hex: "#D4AF37") // Vàng nhạt (đang hold)
        case .available:
            switch seat.type {
            case .standard: return Color(hex: "#E0E0E0") // Xám nhạt
            case .vip: return Color(hex: "#F0C850") // Vàng
            case .couple: return Color(hex: "#FF66CC") // Hồng
            case .wheelchair: return Color(hex: "#00C853") // Xanh lá
            case .unavailable: return .clear
            }
        case .unavailable:
            return .clear
        }
    }
}
