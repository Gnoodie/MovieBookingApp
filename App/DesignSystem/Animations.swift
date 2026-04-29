import SwiftUI

extension Animation {
    /// Animation chuẩn cho các tương tác chọn ghế, thả tim
    static let cinematicSpring = Animation.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0)
    
    /// Animation khi present các sheet (như mini cart, bộ lọc)
    static let sheetPresent = Animation.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.4)
    
    /// Animation nhấp nháy cho skeleton loading
    static let shimmer = Animation.linear(duration: 1.5).repeatForever(autoreverses: false)
}
