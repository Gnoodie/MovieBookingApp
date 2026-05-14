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
        
        Task {
            await generateQRCode()
        }
    }
    
    // MARK: - Core Logic
    
    private func generateQRCode() async {
        let qrString = ticket.bookingId.isEmpty ? "MBK-TICKET" : ticket.bookingId
        
        let image = await Task.detached(priority: .userInitiated) { [weak self] () -> UIImage? in
            guard let self = self else { return nil }
            guard let data = qrString.data(using: .utf8) else {
                print("❌ Failed to encode string")
                return nil
            }
            
            guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
                print("❌ Failed to create CIFilter")
                return nil
            }
            
            filter.setValue(data, forKey: "inputMessage")
            filter.setValue("M", forKey: "inputCorrectionLevel")
            
            guard let outputImage = filter.outputImage else {
                print("❌ No output image from filter")
                return nil
            }
            
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            guard let cgImage = self.ciContext.createCGImage(scaledImage, from: scaledImage.extent) else {
                print("❌ Failed to create CGImage from CIImage")
                return nil
            }
            
            return UIImage(cgImage: cgImage)
        }.value
        
        // Gán lại trên MainActor (vì class được đánh dấu @MainActor)
        if let image = image {
            self.qrImage = image
            print("✅ QR generated successfully!")
        }
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
