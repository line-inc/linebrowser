import SwiftUI

extension Color {
    /// Creates a color from a 0xRRGGBB integer literal, e.g. `Color(0xFF34C759)`.
    init(_ hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0
        )
    }
}
