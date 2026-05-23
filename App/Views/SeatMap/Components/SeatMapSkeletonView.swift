import SwiftUI

struct SeatMapSkeletonView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Màn hình giả lập với hiệu ứng nhấp nháy
            VStack(spacing: 8) {
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 200, height: 6)
                
                Text("MÀN HÌNH")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.15))
            }
            .padding(.top, 40)
            
            // Grid ghế giả lập
            VStack(spacing: 10) {
                ForEach(0..<8) { rowIndex in
                    HStack(spacing: 8) {
                        // Nhãn hàng ghế bên trái
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.06))
                            .frame(width: 22, height: 22)
                        
                        Spacer().frame(width: 8)
                        
                        // Ghế
                        ForEach(0..<8) { colIndex in
                            RoundedRectangle(cornerRadius: 6)
                                .fill(colIndex % 3 == 0 ? Color.white.opacity(0.12) : Color.white.opacity(0.08))
                                .frame(width: 22, height: 22)
                        }
                        
                        Spacer().frame(width: 8)
                        
                        // Nhãn hàng ghế bên phải
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.06))
                            .frame(width: 22, height: 22)
                    }
                }
            }
            .opacity(isAnimating ? 0.35 : 0.85)
            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear {
                isAnimating = true
            }
            
            // Legend giả lập (Chú thích ghế)
            HStack(spacing: 24) {
                ForEach(0..<3) { _ in
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 14, height: 14)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.06))
                            .frame(width: 44, height: 8)
                    }
                }
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#06060C").ignoresSafeArea())
    }
}
