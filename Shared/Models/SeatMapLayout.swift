import Foundation
import CoreGraphics

// MARK: - SeatMapLayout

/// Tiện ích hỗ trợ tính toán toạ độ và kích thước cho Canvas (iOS 15+)
/// v2: Ghế couple là 2 ô riêng biệt kích thước bình thường, không gộp frame
struct SeatMapLayout {

    // MARK: - Constants

    static let seatWidth: CGFloat = 32.0
    static let seatHeight: CGFloat = 32.0
    static let seatSpacing: CGFloat = 8.0
    static let rowSpacing: CGFloat = 16.0

    static let rowLabelWidth: CGFloat = 24.0
    static let rowLabelMargin: CGFloat = 12.0

    static let screenCurveHeight: CGFloat = 40.0
    static let screenMarginBottom: CGFloat = 40.0

    // MARK: - Layout State

    let rows: [String]
    let seats: [Seat]

    private(set) var seatFrames: [String: CGRect] = [:]
    private(set) var mapSize: CGSize = .zero

    init(seatMap: SeatMap) {
        self.rows = seatMap.rows
        self.seats = seatMap.seats
        calculateLayout()
    }

    // MARK: - Calculation

    private mutating func calculateLayout() {
        var frames: [String: CGRect] = [:]

        let rowCount = rows.count
        var maxColumns = 0

        for row in rows {
            let rowSeats = seats.filter { $0.row == row }
            if let maxNum = rowSeats.map({ $0.number }).max() {
                maxColumns = max(maxColumns, maxNum)
            }
        }

        let mapWidth = Self.rowLabelWidth + Self.rowLabelMargin
            + CGFloat(maxColumns) * Self.seatWidth
            + CGFloat(maxColumns - 1) * Self.seatSpacing

        let mapHeight = Self.screenCurveHeight + Self.screenMarginBottom
            + CGFloat(rowCount) * Self.seatHeight
            + CGFloat(rowCount - 1) * Self.rowSpacing

        self.mapSize = CGSize(width: mapWidth, height: mapHeight)

        let startY = Self.screenCurveHeight + Self.screenMarginBottom
        let startX = Self.rowLabelWidth + Self.rowLabelMargin

        for (rowIndex, row) in rows.enumerated() {
            let yPos = startY + CGFloat(rowIndex) * (Self.seatHeight + Self.rowSpacing)

            let rowSeats = seats.filter { $0.row == row }
            for seat in rowSeats {
                let colIndex = CGFloat(seat.number - 1)
                let xPos = startX + colIndex * (Self.seatWidth + Self.seatSpacing)

                // ✅ Tất cả ghế đều có cùng kích thước — couple là 2 ghế riêng biệt
                let frame = CGRect(x: xPos, y: yPos, width: Self.seatWidth, height: Self.seatHeight)
                frames[seat.id] = frame
            }
        }

        self.seatFrames = frames
    }

    // MARK: - Hit Testing

    func seat(at point: CGPoint) -> Seat? {
        let hitMargin: CGFloat = 4.0

        for (seatId, frame) in seatFrames {
            let hitRect = frame.insetBy(dx: -hitMargin, dy: -hitMargin)
            if hitRect.contains(point) {
                return seats.first { $0.id == seatId }
            }
        }
        return nil
    }
}