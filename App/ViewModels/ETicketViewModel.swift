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
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    
    init(ticket: Ticket) {
        self.ticket = ticket
        setupScreenshotObserver()
        generateQRCode()
    }
    
    // MARK: - Core Logic
    
    private func generateQRCode() {
        let qrString = ticket.bookingId.isEmpty ? "MBK-TICKET" : ticket.bookingId
        guard let data = qrString.data(using: .utf8) else { return }
        
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        
        guard let outputImage = filter.outputImage else { return }
        
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)
        
        guard let cgImage = ciContext.createCGImage(scaledImage, from: scaledImage.extent) else {
            print("Failed to create CGImage from CIImage")
            return
        }
        self.qrImage = UIImage(cgImage: cgImage)
    }
    
    // MARK: - UX Logic
    
    func viewDidAppear() {
        // Lưu độ sáng hiện tại
        originalBrightness = UIScreen.main.brightness
        // Tăng độ sáng lên 1.0 (Tối đa) để quét QR dễ hơn
        setScreenBrightness(1.0)
    }
    
    func viewDidDisappear() {
        // Khôi phục độ sáng
        setScreenBrightness(originalBrightness)
    }
    
    private func setScreenBrightness(_ value: CGFloat) {
        // Fix warning deprecation từ iOS 16
        if #available(iOS 16.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                windowScene.screen.brightness = value
            } else {
                UIScreen.main.brightness = value
            }
        } else {
            UIScreen.main.brightness = value
        }
    }
    
    private func setupScreenshotObserver() {
        NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)
            .sink { [weak self] _ in
                self?.handleScreenshotTaken()
            }
            .store(in: &cancellables)
            
        // Chống quay màn hình (Screen recording)
        NotificationCenter.default.publisher(for: UIScreen.capturedDidChangeNotification)
            .sink { [weak self] _ in
                let isCaptured = UIScreen.main.isCaptured
                withAnimation { 
                    self?.isQRBlurred = isCaptured 
                }
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
