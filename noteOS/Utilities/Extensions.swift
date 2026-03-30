// Extensions.swift
// Tido — Utilities
// Handy SwiftUI and Foundation extensions used across the app.

import SwiftUI
import AppKit

// MARK: - View Extensions

extension View {

    /// Applies a conditional modifier — useful for platform/state-based styling without extra views.
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition { transform(self) } else { self }
    }

    /// Standard row hover effect used throughout the task list.
    func tidoRowBackground(isHovered: Bool, cornerRadius: CGFloat = TidoDesign.Radius.md) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(isHovered ? TidoDesign.Color.rowHover : Color.clear)
                .padding(.horizontal, TidoDesign.Spacing.xs)
                .animation(TidoDesign.Animation.quick, value: isHovered)
        )
    }

    /// Clips content with a continuous rounded rectangle.
    func continuousRoundedCorners(_ radius: CGFloat = TidoDesign.Radius.md) -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

// MARK: - String Extensions

extension String {
    /// Trims whitespace and newlines, then checks for emptiness.
    var isBlank: Bool { trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}

// MARK: - Color Extensions

extension Color {
    /// Creates a Color from a hex string like "#6B5CE7" or "6B5CE7"
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Array Extensions

extension Array where Element: Identifiable {
    /// Removes an element by its ID without needing an index.
    mutating func remove(id: Element.ID) {
        removeAll { $0.id == id }
    }
}
