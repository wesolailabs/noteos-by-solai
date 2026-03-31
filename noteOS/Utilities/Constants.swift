// Constants.swift
// noteOS — Utilities
// Design system tokens: colors, spacing, typography, animation curves.
// All design decisions live here for consistency and easy theme changes.

import SwiftUI

// MARK: - Design Tokens

enum NoteOSDesign {

    // MARK: Colors

    enum Color {
        /// Accent: a vibrant blue - modern and native to macOS
        static let accent = SwiftUI.Color(hue: 0.58, saturation: 0.70, brightness: 0.95)

        /// Accent secondary — subtle tint for backgrounds
        static let accentSubtle = SwiftUI.Color(hue: 0.58, saturation: 0.12, brightness: 0.98)

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

        /// Row hover background - very subtle
        static let rowHover = SwiftUI.Color.primary.opacity(0.05)

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
        static let sm: CGFloat  = 8
        static let md: CGFloat  = 12
        static let lg: CGFloat  = 16
        static let xl: CGFloat  = 20
    }

    // MARK: Typography

    enum Font {
        /// App-level title
        static let title      = SwiftUI.Font.system(size: 15, weight: .semibold)
        /// Section header
        static let header     = SwiftUI.Font.system(size: 12, weight: .medium)
        /// Task title
        static let taskTitle  = SwiftUI.Font.system(size: 13.5, weight: .regular)
        /// Subtask title
        static let subtask    = SwiftUI.Font.system(size: 12.5, weight: .regular)
        /// Caption / metadata
        static let caption    = SwiftUI.Font.system(size: 11, weight: .regular)
        /// Monospaced count badge
        static let badge      = SwiftUI.Font.system(size: 10.5, weight: .semibold, design: .monospaced)
        /// Input field
        static let input      = SwiftUI.Font.system(size: 13.5, weight: .regular)
    }

    // MARK: Animation

    enum Animation {
        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
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
