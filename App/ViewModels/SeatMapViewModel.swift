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

    /// Alert hiện khi ghế bị người khác chọn trước (409 conflict từ server)
    @Published var showConflictAlert: Bool = false
    @Published var conflictSeatName: String = ""

    /// Alert hiện khi tap ghế couple nhưng partner đã booked/held
    @Published var showPartnerUnavailableAlert: Bool = false
    @Published var partnerUnavailableSeatName: String = ""

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

    /// Lưu thời điểm hết hạn để tính đúng giờ khi app bị suspend
    private var expirationDate: Date? = nil

    /// Task quản lý SSE stream
    private var sseTask: Task<Void, Never>? = nil

    // MARK: - Computed Properties

    var selectedSeats: [Seat] {
        guard let seatMap = seatMap else { return [] }
        return seatMap.seats.filter { selectedSeatIds.contains($0.id) }
    }

    var totalPrice: Decimal {
        let basePrice = showtime.basePrice
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
        cancelSSE()
    }

    // MARK: - Load Seats

    func loadSeats() {
        isLoading = true
        errorMessage = nil

        sseTask?.cancel()
        sseTask = Task {
            for await seats in seatRepository.listenToSeats(showtimeId: showtime.id) {
                let rows = Array(Set(seats.map { $0.row })).sorted()

                // Cập nhật lại danh sách đang chọn nếu có người khác lấy mất
                var updatedSelectedIds = self.selectedSeatIds
                for seat in seats {
                    if self.selectedSeatIds.contains(seat.id) {
                        if (seat.status == .held || seat.status == .booked) && !self.isHoldActive {
                            // Nếu là couple thì bỏ cả partner
                            if seat.type == .couple, let partner = self.partnerSeat(of: seat, in: seats) {
                                updatedSelectedIds.remove(partner.id)
                            }
                            updatedSelectedIds.remove(seat.id)
                        }
                    }
                }
                self.selectedSeatIds = updatedSelectedIds

                self.seatMap = SeatMap(
                    showtimeId: self.showtime.id,
                    rows: rows,
                    seats: seats,
                    screenLabel: "MÀN HÌNH"
                )
                self.isLoading = false
            }
        }
    }

    // MARK: - Seat Selection

    /// Tap vào một ghế — toggle select.
    /// Ghế couple: kiểm tra cả cặp trước khi cho chọn.
    func seatTapped(_ seat: Seat) {
        if seat.type == .couple {
            // Couple: cho phép tap vào ghế available hoặc mine
            // (guard partner ở trong handleCoupleSeatTapped)
            guard seat.status == .available || seat.status == .mine else { return }
            handleCoupleSeatTapped(seat)
        } else {
            guard seat.status == .available || seat.status == .mine else { return }
            handleSingleSeatTapped(seat)
        }
    }

    // MARK: - Private: Single Seat

    private func handleSingleSeatTapped(_ seat: Seat) {
        if selectedSeatIds.contains(seat.id) {
            selectedSeatIds.remove(seat.id)
            if selectedSeatIds.isEmpty && isHoldActive {
                Task { await releaseCurrentHold() }
            }
        } else {
            guard canSelectMoreSeats else { return }
            selectedSeatIds.insert(seat.id)
        }
    }

    // MARK: - Private: Couple Seat

    private func handleCoupleSeatTapped(_ seat: Seat) {
        guard let seats = seatMap?.seats else { return }

        // Không tìm được partner → ghế couple lỗi data, không cho chọn
        guard let partner = partnerSeat(of: seat, in: seats) else { return }

        // Nếu partner đã booked/held → cả cặp không thể chọn
        let partnerUnavailable = partner.status == .booked
            || partner.status == .held
            || partner.status == .unavailable

        if partnerUnavailable {
            // Alert riêng: partner đã bị đặt → cả cặp không thể chọn
            partnerUnavailableSeatName = "\(seat.displayName) & \(partner.displayName)"
            showPartnerUnavailableAlert = true
            return
        }

        let isCurrentlySelected = selectedSeatIds.contains(seat.id)

        if isCurrentlySelected {
            // Bỏ chọn cả 2
            selectedSeatIds.remove(seat.id)
            selectedSeatIds.remove(partner.id)

            if selectedSeatIds.isEmpty && isHoldActive {
                Task { await releaseCurrentHold() }
            }
        } else {
            // Cần đủ 2 slot trống
            guard selectedSeatIds.count + 2 <= Self.maxSeatSelection else { return }

            selectedSeatIds.insert(seat.id)
            selectedSeatIds.insert(partner.id)
        }
    }

    /// Tìm ghế partner dựa theo coupleGroupId — không dùng vị trí số.
    private func partnerSeat(of seat: Seat, in seats: [Seat]) -> Seat? {
        guard let groupId = seat.coupleGroupId else { return nil }
        return seats.first {
            $0.id != seat.id && $0.coupleGroupId == groupId
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

                self.currentHoldId = response.holdId
                self.isHoldActive = true
                self.isHoldingSeats = false

                self.updateSeatStatuses(ids: Set(response.seatIds), newStatus: .mine)
                self.startHoldTimer()

            } catch let error as SeatHoldError {
                self.isHoldingSeats = false
                switch error {
                case .conflict(let seatName):
                    self.conflictSeatName = seatName
                    self.showConflictAlert = true
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
            print("⚠️ Unhold failed (server will auto-expire): \(error)")
        }

        resetHoldState()
    }

    // MARK: - Hold Timer (AsyncStream)

    private func startHoldTimer() {
        timerTask?.cancel()
        expirationDate = Date().addingTimeInterval(TimeInterval(Self.holdDurationSeconds))
        holdTimerSeconds = Self.holdDurationSeconds

        timerTask = Task { [weak self] in
            while let self = self, !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                } catch {
                    break
                }

                guard let expire = self.expirationDate else { continue }

                let remaining = Int(expire.timeIntervalSinceNow)

                if remaining <= 0 {
                    self.holdTimerSeconds = 0
                    await self.handleTimerExpired()
                    break
                } else {
                    self.holdTimerSeconds = remaining
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

    func handleSeatUpdateEvent(_ event: SeatUpdateEvent) {
        guard let seats = seatMap?.seats else { return }

        updateSeatStatuses(ids: [event.seatId], newStatus: event.newStatus)

        if selectedSeatIds.contains(event.seatId),
           event.newStatus == .held || event.newStatus == .booked,
           !isHoldActive {
            selectedSeatIds.remove(event.seatId)

            // Nếu là couple, bỏ chọn luôn partner
            if let seat = seats.first(where: { $0.id == event.seatId }),
               seat.type == .couple,
               let partner = partnerSeat(of: seat, in: seats) {
                selectedSeatIds.remove(partner.id)
            }
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
        guard let seats = seatMap?.seats else { return }

        // Tìm ghế bị conflict theo displayName
        guard let conflictSeat = seats.first(where: { $0.displayName == seatName }) else {
            selectedSeatIds.remove(seatName) // fallback
            return
        }

        selectedSeatIds.remove(conflictSeat.id)

        // Nếu là couple, bỏ partner luôn
        if conflictSeat.type == .couple,
           let partner = partnerSeat(of: conflictSeat, in: seats) {
            selectedSeatIds.remove(partner.id)
        }
    }

    private func resetHoldState() {
        currentHoldId = nil
        isHoldActive = false
        holdTimerSeconds = nil
        expirationDate = nil
        timerTask?.cancel()
        timerTask = nil

        updateSeatStatuses(ids: selectedSeatIds, newStatus: .available)
    }
}

// MARK: - SeatHoldError

enum SeatHoldError: Error {
    case conflict(seatName: String)
    case networkError(String)
}

// MARK: - SeatUpdateEvent (SSE Payload)

struct SeatUpdateEvent {
    let seatId: String
    let newStatus: Seat.SeatStatus
    let userId: String?
}