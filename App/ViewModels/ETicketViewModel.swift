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
        generateQRCode()
        setupScreenshotObserver()
    }
    
    // MARK: - Core Logic
    
    private func generateQRCode() {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        let data = Data(ticket.qrCodeData.utf8)
        filter.setValue(data, forKey: "inputMessage")
        // M = Medium error correction
        filter.setValue("M", forKey: "inputCorrectionLevel")
        
        guard let outputImage = filter.outputImage else { return }
        
        // Phóng to QR Code (scale x10)
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)
        
        if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
            self.qrImage = UIImage(cgImage: cgImage)
        }
    }
    
    // MARK: - UX Logic
    
    func viewDidAppear() {
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
