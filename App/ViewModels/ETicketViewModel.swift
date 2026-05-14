import Foundation
import UIKit
import CoreImage.CIFilterBuiltins
import Combine
import SwiftUI

// MARK: - ETicketViewModel

@MainActor
final class ETicketViewModel: ObservableObject {
    let ticket: Ticket
    
    @Published var qrImage: UIImage?
    @Published var isQRBlurred: Bool = false
    
    private var originalBrightness: CGFloat = 0.5
    private var cancellables = Set<AnyCancellable>()
    
    init(ticket: Ticket) {
        self.ticket = ticket
        setupScreenshotObserver()
    }
    
    // MARK: - Core Logic
    
    private func generateQRCode() {
        let qrString = ticket.bookingId.isEmpty ? "MBK-TICKET" : ticket.bookingId
        guard let data = qrString.data(using: .ascii) else { return }
        
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        
        guard let outputImage = filter.outputImage else { return }
        
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)
        
        let context = CIContext()
        if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
            self.qrImage = UIImage(cgImage: cgImage)
        } else {
            self.qrImage = UIImage(ciImage: scaledImage)
        }
    }
    
    // MARK: - UX Logic
    
    func viewDidAppear() {
        if qrImage == nil {
            generateQRCode()
        }
        // Lưu độ sáng hiện tại
        originalBrightness = UIScreen.main.brightness
        // Tăng độ sáng lên 1.0 (Tối đa) để quét QR dễ hơn
        UIScreen.main.brightness = 1.0
    }
    
    func viewDidDisappear() {
        // Khôi phục độ sáng
        UIScreen.main.brightness = originalBrightness
    }
    
    private func setupScreenshotObserver() {
        NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)
            .sink { [weak self] _ in
                self?.handleScreenshotTaken()
            }
            .store(in: &cancellables)
    }
    
    private func handleScreenshotTaken() {
        // Làm mờ QR
        withAnimation {
            self.isQRBlurred = true
        }
        
        // Gỡ mờ sau 3 giây
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            withAnimation {
                self?.isQRBlurred = false
            }
        }
    }
}
