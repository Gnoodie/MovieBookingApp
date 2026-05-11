import Foundation
import Combine

// MARK: - SeatMapViewModel

/// ViewModel cho màn hình chọn ghế (Sprint 3)
/// iOS 15.2 compatible — dùng ObservableObject + AsyncStream
@MainActor
final class SeatMapViewModel: ObservableObject {

    // MARK: - Published State

    @Published var seatMap: SeatMap?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    /// Danh sách ghế user đang chọn (max 6)
    @Published var selectedSeatIds: Set<String> = []

    /// Hold timer — đếm ngược từ 600 (10 phút), nil = chưa bắt đầu
    @Published var holdTimerSeconds: Int? = nil

    /// true khi đang trong trạng thái hold (đã gọi POST /seats/hold thành công)
    @Published var isHoldActive: Bool = false

    /// Alert hiện khi ghế bị người khác chọn trước (409 conflict)
    @Published var showConflictAlert: Bool = false
    @Published var conflictSeatName: String = ""

    /// Alert hiện khi hold timer hết giờ
    @Published var showTimerExpiredAlert: Bool = false

    /// true khi đang gửi request hold/unhold
    @Published var isHoldingSeats: Bool = false

    // MARK: - Constants

    static let maxSeatSelection = 6
    static let holdDurationSeconds = 600 // 10 phút

    // MARK: - Dependencies

    let showtime: Showtime
    let movie: Movie
    private let seatRepository: SeatRepositoryProtocol

    /// holdId nhận được sau khi POST /seats/hold thành công
    private var currentHoldId: String? = nil

    /// Task quản lý hold timer AsyncStream
    private var timerTask: Task<Void, Never>? = nil

    /// Task quản lý SSE stream
    private var sseTask: Task<Void, Never>? = nil

    // MARK: - Computed Properties

    var selectedSeats: [Seat] {
        guard let seatMap = seatMap else { return [] }
        return seatMap.seats.filter { selectedSeatIds.contains($0.id) }
    }

    var totalPrice: Decimal {
        let basePrice = Decimal(showtime.basePrice)
        return selectedSeats.reduce(Decimal(0)) { $0 + $1.price(basePrice: basePrice) }
    }

    var totalPriceFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.maximumFractionDigits = 0
        let number = NSDecimalNumber(decimal: totalPrice)
        return (formatter.string(from: number) ?? "0") + "đ"
    }

    var canSelectMoreSeats: Bool {
        selectedSeatIds.count < Self.maxSeatSelection
    }

    var canProceedToCheckout: Bool {
        !selectedSeatIds.isEmpty && isHoldActive
    }

    /// Thời gian còn lại format MM:SS
    var holdTimerFormatted: String {
        guard let seconds = holdTimerSeconds else { return "10:00" }
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    /// Cảnh báo khi dưới 2 phút
    var isTimerWarning: Bool {
        guard let seconds = holdTimerSeconds else { return false }
        return seconds <= 120
    }

    // MARK: - Init

    init(
        showtime: Showtime,
        movie: Movie,
        seatRepository: SeatRepositoryProtocol = MockSeatRepository()
    ) {
        self.showtime = showtime
        self.movie = movie
        self.seatRepository = seatRepository
    }

    // MARK: - Lifecycle

    func onAppear() {
        loadSeats()
    }

    func onDisappear() {
        // Huỷ SSE khi rời màn hình
        cancelSSE()
    }

    // MARK: - Load Seats

    func loadSeats() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let seats = try await seatRepository.fetchSeats(showtimeId: showtime.id)
                // Build SeatMap từ flat array seats
                let rows = Array(Set(seats.map { $0.row })).sorted()
                self.seatMap = SeatMap(
                    showtimeId: showtime.id,
                    rows: rows,
                    seats: seats,
                    screenLabel: "MÀN HÌNH"
                )
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    // MARK: - Seat Selection

    /// Tap vào một ghế — toggle select nếu available/mine, bỏ qua nếu held/booked
    func seatTapped(_ seat: Seat) {
        guard seat.status == .available || seat.status == .mine else { return }

        if selectedSeatIds.contains(seat.id) {
            // Bỏ chọn ghế
            selectedSeatIds.remove(seat.id)

            // Nếu không còn ghế nào được chọn → huỷ hold
            if selectedSeatIds.isEmpty && isHoldActive {
                Task { await releaseCurrentHold() }
            }
        } else {
            // Kiểm tra giới hạn 6 ghế
            guard canSelectMoreSeats else { return }
            selectedSeatIds.insert(seat.id)
        }
    }

    // MARK: - Hold Logic

    /// Gọi POST /seats/hold — được trigger khi user nhấn "Tiếp tục" trên MiniCart
    func holdSelectedSeats() {
        guard !selectedSeatIds.isEmpty, !isHoldingSeats else { return }

        isHoldingSeats = true

        Task {
            do {
                let seatIds = Array(selectedSeatIds)
                let response = try await seatRepository.holdSeats(
                    showtimeId: showtime.id,
                    seatIds: seatIds
                )

                // Hold thành công
                self.currentHoldId = response.holdId
                self.isHoldActive = true
                self.isHoldingSeats = false

                // Cập nhật status ghế → .mine
                self.updateSeatStatuses(ids: Set(response.seatIds), newStatus: .mine)

                // Bắt đầu hold timer
                self.startHoldTimer()

            } catch let error as SeatHoldError {
                self.isHoldingSeats = false
                switch error {
                case .conflict(let seatName):
                    // 409 — ghế bị người khác chọn trước
                    self.conflictSeatName = seatName
                    self.showConflictAlert = true
                    // Bỏ ghế conflict khỏi selection
                    self.removeConflictSeat(named: seatName)
                case .networkError(let msg):
                    self.errorMessage = msg
                }
            } catch {
                self.isHoldingSeats = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    /// Huỷ hold hiện tại (user thoát hoặc timer hết giờ)
    func releaseCurrentHold() async {
        guard let holdId = currentHoldId else { return }

        do {
            try await seatRepository.releaseSeats(holdId: holdId)
        } catch {
            // Bỏ qua lỗi unhold — server sẽ tự timeout sau 10 phút
            print("⚠️ Unhold failed (server will auto-expire): \(error)")
        }

        // Reset trạng thái dù có lỗi hay không
        resetHoldState()
    }

    // MARK: - Hold Timer (AsyncStream)

    private func startHoldTimer() {
        timerTask?.cancel()
        holdTimerSeconds = Self.holdDurationSeconds

        timerTask = Task { [weak self] in
            while let self = self, !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                } catch {
                    break
                }

                guard let remaining = self.holdTimerSeconds, remaining > 0 else {
                    continue
                }

                self.holdTimerSeconds = remaining - 1

                if self.holdTimerSeconds == 0 {
                    await self.handleTimerExpired()
                    break
                }
            }
        }
    }

    private func handleTimerExpired() async {
        await releaseCurrentHold()
        showTimerExpiredAlert = true
    }

    func cancelTimerAndRelease() {
        timerTask?.cancel()
        timerTask = nil
        Task { await releaseCurrentHold() }
    }

    // MARK: - SSE Integration

    /// Nhận event từ SSE stream và cập nhật trạng thái ghế
    /// Được gọi bởi SSEClient khi có event mới
    func handleSeatUpdateEvent(_ event: SeatUpdateEvent) {
        updateSeatStatuses(ids: [event.seatId], newStatus: event.newStatus)

        // Nếu ghế mình đang chọn bị người khác hold → conflict
        if selectedSeatIds.contains(event.seatId),
           event.newStatus == .held || event.newStatus == .booked,
           !isHoldActive {
            selectedSeatIds.remove(event.seatId)
        }
    }

    func cancelSSE() {
        sseTask?.cancel()
        sseTask = nil
    }

    // MARK: - Private Helpers

    private func updateSeatStatuses(ids: Set<String>, newStatus: Seat.SeatStatus) {
        guard var currentSeatMap = seatMap else { return }
        let updatedSeats = currentSeatMap.seats.map { seat -> Seat in
            guard ids.contains(seat.id) else { return seat }
            var updated = seat
            updated.status = newStatus
            return updated
        }
        currentSeatMap = SeatMap(
            showtimeId: currentSeatMap.showtimeId,
            rows: currentSeatMap.rows,
            seats: updatedSeats,
            screenLabel: currentSeatMap.screenLabel
        )
        seatMap = currentSeatMap
    }

    private func removeConflictSeat(named seatName: String) {
        selectedSeatIds.remove(seatName)
    }

    private func resetHoldState() {
        currentHoldId = nil
        isHoldActive = false
        holdTimerSeconds = nil
        timerTask?.cancel()
        timerTask = nil

        // Ghế trạng thái .mine → trở về .available
        updateSeatStatuses(
            ids: selectedSeatIds,
            newStatus: .available
        )
    }
}

// MARK: - SeatHoldError

enum SeatHoldError: Error {
    case conflict(seatName: String)
    case networkError(String)
}

// MARK: - SeatUpdateEvent (SSE Payload)

/// Model nhận từ SSE stream: { seatId, newStatus }
struct SeatUpdateEvent {
    let seatId: String
    let newStatus: Seat.SeatStatus
    let userId: String?
}
