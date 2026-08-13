import Foundation
import UIKit

// MARK: - PaymentResult

enum PaymentResult {
    case success(reference: String)
    case failure(message: String)
    case cancelled
}

// MARK: - PaymentService

/// Router trung tâm điều phối luồng thanh toán cho từng phương thức
/// Sandbox/Dev: dùng mock + sandbox URL. Production: thay config trong từng hàm.
@MainActor
final class PaymentService: ObservableObject {

    // nonisolated(unsafe): cho phép dùng .shared làm default parameter value
    // trong nonisolated context mà không cần Swift 6 actor hop
    nonisolated(unsafe) static let shared = PaymentService()
    private init() {}

    // Callback được gọi khi MoMo/VNPay redirect về app
    var pendingPaymentCompletion: ((PaymentResult) -> Void)?

    // QR Demo sheet state
    @Published var isShowingQRSheet: Bool = false
    private var qrPaymentContinuation: CheckedContinuation<PaymentResult, Never>?

    // MARK: - Public API

    func pay(method: PaymentMethod, order: PendingOrderInfo) async -> PaymentResult {
        switch method {
        case .mockPay:
            return await mockPay(order: order)
        case .momo:
            return await payWithMoMo(order: order)
        case .vnpay:
            return await payWithVNPay(order: order)
        case .applePay:
            // Apple Pay cần PassKit Certificate — chưa support
            return .failure(message: "Apple Pay chưa được kích hoạt.")
        }
    }

    // MARK: - Handle URL Callback (gọi từ onOpenURL trong App)

    func handleCallback(url: URL) {
        guard url.scheme == "cinematicket",
              url.host == "payment" else { return }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let params = Dictionary(
            uniqueKeysWithValues: (components?.queryItems ?? []).compactMap { item in
                item.value.map { (item.name, $0) }
            }
        )

        // MoMo callback: cinematicket://payment/callback?resultCode=0&orderId=xxx
        if url.path == "/callback" {
            if let resultCode = params["resultCode"] {
                if resultCode == "0" {
                    let ref = params["transId"] ?? params["orderId"] ?? UUID().uuidString
                    pendingPaymentCompletion?(.success(reference: ref))
                } else if resultCode == "1006" {
                    pendingPaymentCompletion?(.cancelled)
                } else {
                    let message = params["message"] ?? "Thanh toán thất bại."
                    pendingPaymentCompletion?(.failure(message: message))
                }
            }
            // VNPay callback: cinematicket://payment/callback?vnp_ResponseCode=00
            else if let responseCode = params["vnp_ResponseCode"] {
                if responseCode == "00" {
                    let ref = params["vnp_TransactionNo"] ?? UUID().uuidString
                    pendingPaymentCompletion?(.success(reference: ref))
                } else {
                    pendingPaymentCompletion?(.failure(message: "Thanh toán VNPay thất bại (mã: \(responseCode))."))
                }
            } else {
                pendingPaymentCompletion?(.failure(message: "Phản hồi không hợp lệ."))
            }
        }

        pendingPaymentCompletion = nil
    }

    // MARK: - Private: Mock Pay (QR Demo)

    private func mockPay(order: PendingOrderInfo) async -> PaymentResult {
        // Hiển thị QR Sheet — người dùng tap "Xác nhận" để hoàn tất
        return await withCheckedContinuation { continuation in
            self.qrPaymentContinuation = continuation
            self.isShowingQRSheet = true
        }
    }

    /// Gọi khi user tap "Xác nhận thanh toán" trên QR Sheet
    func confirmQRPayment() {
        let ref = "QR-DEMO-\(UUID().uuidString.prefix(8).uppercased())"
        isShowingQRSheet = false
        qrPaymentContinuation?.resume(returning: .success(reference: ref))
        qrPaymentContinuation = nil
    }

    /// Gọi khi user đóng QR Sheet mà không xác nhận
    func cancelQRPayment() {
        isShowingQRSheet = false
        qrPaymentContinuation?.resume(returning: .cancelled)
        qrPaymentContinuation = nil
    }

    // MARK: - Private: MoMo Deep-link

    private func payWithMoMo(order: PendingOrderInfo) async -> PaymentResult {
        // Sandbox partner code (thay bằng credentials thật khi có)
        let partnerCode = "MOMO_SANDBOX"
        let returnURL = "cinematicket://payment/callback"
        let amount = NSDecimalNumber(decimal: order.totalAmount).intValue

        // Build deep-link URL theo MoMo SDK spec
        var components = URLComponents()
        components.scheme = "momo"
        components.host = "app"
        components.queryItems = [
            URLQueryItem(name: "action", value: "payWithApp"),
            URLQueryItem(name: "amount", value: "\(amount)"),
            URLQueryItem(name: "description", value: "Dat ve: \(order.movieTitle)"),
            URLQueryItem(name: "orderId", value: order.orderId),
            URLQueryItem(name: "partnerCode", value: partnerCode),
            URLQueryItem(name: "partnerName", value: "Cinematicket"),
            URLQueryItem(name: "returnUrl", value: returnURL),
        ]

        guard let momoURL = components.url else {
            return .failure(message: "Không thể tạo link thanh toán MoMo.")
        }

        // Kiểm tra MoMo đã cài chưa
        if UIApplication.shared.canOpenURL(momoURL) {
            return await withCheckedContinuation { continuation in
                self.pendingPaymentCompletion = { result in
                    continuation.resume(returning: result)
                }
                UIApplication.shared.open(momoURL)
            }
        } else {
            // Fallback: mở trang web sandbox MoMo
            guard let webURL = URL(string: "https://test-payment.momo.vn/pay?orderId=\(order.orderId)&amount=\(amount)") else {
                return .failure(message: "Không thể tạo URL thanh toán fallback.")
            }
            return await withCheckedContinuation { continuation in
                self.pendingPaymentCompletion = { result in
                    continuation.resume(returning: result)
                }
                UIApplication.shared.open(webURL)
            }
        }
    }

    // MARK: - Private: VNPay Deep-link

    private func payWithVNPay(order: PendingOrderInfo) async -> PaymentResult {
        let returnURL = "cinematicket://payment/callback"
        let amount = NSDecimalNumber(decimal: order.totalAmount).intValue * 100 // VNPay nhân 100

        // Build sandbox URL (thay bằng production URL và merchant hash khi có)
        guard var components = URLComponents(string: "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html") else {
            return .failure(message: "Lỗi cấu hình URL VNPay.")
        }
        components.queryItems = [
            URLQueryItem(name: "vnp_Version", value: "2.1.0"),
            URLQueryItem(name: "vnp_Command", value: "pay"),
            URLQueryItem(name: "vnp_TmnCode", value: "SANDBOX_TMN"),
            URLQueryItem(name: "vnp_Amount", value: "\(amount)"),
            URLQueryItem(name: "vnp_CurrCode", value: "VND"),
            URLQueryItem(name: "vnp_TxnRef", value: order.orderId),
            URLQueryItem(name: "vnp_OrderInfo", value: "Dat ve: \(order.movieTitle)"),
            URLQueryItem(name: "vnp_OrderType", value: "other"),
            URLQueryItem(name: "vnp_Locale", value: "vn"),
            URLQueryItem(name: "vnp_ReturnUrl", value: returnURL),
        ]

        guard let vnpayURL = components.url else {
            return .failure(message: "Không thể tạo link thanh toán VNPay.")
        }

        return await withCheckedContinuation { continuation in
            self.pendingPaymentCompletion = { result in
                continuation.resume(returning: result)
            }
            UIApplication.shared.open(vnpayURL)
        }
    }
}

// MARK: - PendingOrderInfo

/// Dữ liệu tối thiểu cần để tạo payment request
struct PendingOrderInfo {
    let orderId: String
    let movieTitle: String
    let totalAmount: Decimal
}
