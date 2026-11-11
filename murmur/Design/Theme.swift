import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    static let paper = Color(hex: 0xFFFFFF)
    static let ink = Color(hex: 0x111111)
    static let inkMuted = Color(hex: 0x6E6E6E)
    static let inkFaint = Color(hex: 0x767676)
    static let record = Color(hex: 0xE5322D)
    static let onRecord = Color(hex: 0xFFFFFF)
}

enum Metrics {
    static let tapTarget: CGFloat = 44
    static let recordButton: CGFloat = 80
    static let stopMark: CGFloat = 24
    static let dayCell: CGFloat = 60
    static let dayDot: CGFloat = 5
    static let gutter: CGFloat = 16  // side margin on every screen
    static let strokeLine: CGFloat = 2
    static let strokeFine: CGFloat = 1.8
}

extension Font {
    /// Handwritten styles use fixed sizes so they never scale with Dynamic Type.
    static let title = Font.custom("Gaegu-Bold", fixedSize: 46)
    static let dateLine = Font.custom("Gaegu-Regular", fixedSize: 15)
    static let month = Font.custom("Gaegu-Bold", fixedSize: 46)

    static let caption13 = Font.system(size: 13, weight: .regular)
    static let timer = Font.system(size: 13, weight: .medium).monospacedDigit()
    static let day = Font.system(size: 16, weight: .regular).monospacedDigit()
    static let dayToday = Font.system(size: 16, weight: .bold).monospacedDigit()
    static let weekday = Font.system(size: 11, weight: .medium)
    static let tab = Font.system(size: 14, weight: .medium)
}

extension StrokeStyle {
    static func pen(_ width: CGFloat) -> StrokeStyle {
        StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
    }
}
