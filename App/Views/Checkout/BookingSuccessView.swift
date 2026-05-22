import SwiftUI

// MARK: - BookingSuccessView

struct BookingSuccessView: View {
    let order: Order
    let ticket: Ticket
    
    @State private var timeRemaining = 30
    @State private var navigateToHome = false
    @State private var navigateToTicket = false
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color(hex: "#0D0D1A").ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Animation/Icon
                ZStack {
                    Circle()
                        .fill(Color(hex: "#39D98A").opacity(0.1))
                        .frame(width: 120, height: 120)
                    Circle()
                        .fill(Color(hex: "#39D98A").opacity(0.2))
                        .frame(width: 90, height: 90)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color(hex: "#39D98A"))
                }
                
                // Content
                VStack(spacing: 12) {
                    Text("Đặt vé thành công!")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Mã vé: \(ticket.bookingId)")
                        .font(.system(size: 18, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color(hex: "#D4AF37"))
                    
                    Text("Cảm ơn bạn đã sử dụng dịch vụ.\nVé của bạn đã được lưu trong mục 'Vé của tôi'.")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "#888888"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    // NOTE: Siri & Apple Intelligence lồng ghép khéo léo
                    VStack(spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "#D4AF37"))
                            Text("MẸO ĐẶT VÉ NHANH")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "#D4AF37"))
                        }
                        Text("Bạn có biết: đặt vé dễ dàng qua siri và apple intelligent bằng cách nói \"Hey Siri, Đặt vé phim\"!")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#888888"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .padding(.top, 16)
                    .padding(.horizontal, 24)
                }
                
                Spacer()
                
                // Countdown & Button
                VStack(spacing: 16) {
                    Text("Tự động về trang chủ sau \(timeRemaining)s")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#888888"))
                    
                    NavigationLink(destination: ETicketView(ticket: ticket), isActive: $navigateToTicket) {
                        EmptyView()
                    }
                    .isDetailLink(false)

                    Button {
                        navigateToTicket = true
                    } label: {
                        Text("Xem vé điện tử")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.accentTeal)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)

                    Button {
                        popToRoot()
                    } label: {
                        Text("Về trang chủ ngay")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color(hex: "#D4AF37"))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
        .onReceive(timer) { _ in
            guard !navigateToTicket else { return }
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                popToRoot()
            }
        }
        .onAppear {
            HapticManager.shared.notification(type: .success)
            
            // Phase 5: Thông báo Local
            NotificationManager.shared.requestPermission()
            NotificationManager.shared.scheduleMovieReminder(for: ticket)
            NotificationManager.shared.cancelHoldReminder()
            
#if canImport(ActivityKit)
            if #available(iOS 16.2, *) {
                Task {
                    await LiveActivityManager.shared.startActivity(for: ticket)
                }
            }
#endif
        }
    }
    
    private func popToRoot() {
        NavigationUtil.popToRootView()
    }
}

// MARK: - NavigationUtil (iOS 15 Pop to Root workaround)

struct NavigationUtil {
    static func popToRootView() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        findNavigationController(viewController: window.rootViewController)?
            .popToRootViewController(animated: true)
    }

    static func findNavigationController(viewController: UIViewController?) -> UINavigationController? {
        guard let viewController = viewController else {
            return nil
        }

        if let navigationController = viewController as? UINavigationController {
            return navigationController
        }

        for childViewController in viewController.children {
            if let nav = findNavigationController(viewController: childViewController) {
                return nav
            }
        }

        return nil
    }
}
