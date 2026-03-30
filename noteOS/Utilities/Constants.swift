// Constants.swift
// Tido — Utilities
// Design system tokens: colors, spacing, typography, animation curves.
// All design decisions live here for consistency and easy theme changes.

import SwiftUI

// MARK: - Design Tokens

enum TidoDesign {

    // MARK: Colors

    enum Color {
        /// Accent: a warm, confident indigo-violet — modern but not aggressive
        static let accent = SwiftUI.Color(hue: 0.69, saturation: 0.72, brightness: 0.90)

        /// Accent secondary — subtle tint for backgrounds
        static let accentSubtle = SwiftUI.Color(hue: 0.69, saturation: 0.18, brightness: 0.97)

        /// Completion green — muted, not electric
        static let success = SwiftUI.Color(hue: 0.37, saturation: 0.60, brightness: 0.72)

        /// Destructive — soft red for delete
        static let destructive = SwiftUI.Color(hue: 0.02, saturation: 0.65, brightness: 0.80)

        /// Primary text — adapts to dark/light automatically
        static let textPrimary = SwiftUI.Color.primary

        /// Secondary text
        static let textSecondary = SwiftUI.Color.secondary

        /// Tertiary text — hints, placeholders
        static let textTertiary = SwiftUI.Color(white: 0.55)

        /// Separator
        static let separator = SwiftUI.Color.primary.opacity(0.07)

        /// Row hover background
        static let rowHover = SwiftUI.Color.primary.opacity(0.04)

        /// Completed task text overlay
        static let textCompleted = SwiftUI.Color.secondary.opacity(0.50)
    }

    // MARK: Spacing

    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat  = 6
        static let sm: CGFloat  = 10
        static let md: CGFloat  = 14
        static let lg: CGFloat  = 20
        static let xl: CGFloat  = 28
        static let xxl: CGFloat = 40
    }

    // MARK: Radius

    enum Radius {
        static let sm: CGFloat  = 6
        static let md: CGFloat  = 10
        static let lg: CGFloat  = 14
        static let xl: CGFloat  = 20
    }

    // MARK: Typography

    enum Font {
        /// App-level title
        static let title      = SwiftUI.Font.system(size: 15, weight: .semibold, design: .rounded)
        /// Section header
        static let header     = SwiftUI.Font.system(size: 12, weight: .semibold, design: .rounded)
        /// Task title
        static let taskTitle  = SwiftUI.Font.system(size: 13.5, weight: .regular, design: .default)
        /// Subtask title
        static let subtask    = SwiftUI.Font.system(size: 12.5, weight: .regular, design: .default)
        /// Caption / metadata
        static let caption    = SwiftUI.Font.system(size: 11, weight: .regular, design: .rounded)
        /// Monospaced count badge
        static let badge      = SwiftUI.Font.system(size: 10.5, weight: .semibold, design: .monospaced)
        /// Input field
        static let input      = SwiftUI.Font.system(size: 13.5, weight: .regular, design: .default)
    }

    // MARK: Animation

    enum Animation {
        static let spring = SwiftUI.Animation.spring(response: 0.32, dampingFraction: 0.72)
        static let quick  = SwiftUI.Animation.easeInOut(duration: 0.18)
        static let slow   = SwiftUI.Animation.easeInOut(duration: 0.30)
    }

    // MARK: Dimensions

    enum Size {
        static let checkboxSize: CGFloat     = 18
        static let subtaskCheckbox: CGFloat  = 15
        static let rowMinHeight: CGFloat     = 36
        static let subtaskMinHeight: CGFloat = 30
        static let popoverWidth: CGFloat     = 380
        static let popoverMaxHeight: CGFloat = 520
        static let toolbarHeight: CGFloat    = 48
    }
}
