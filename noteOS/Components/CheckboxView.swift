// CheckboxView.swift
// Tido — Components
// Animated checkbox that provides satisfying visual feedback when toggling completion.
// Two sizes: task-level and subtask-level.

import SwiftUI

enum CheckboxSize {
    case task, subtask

    var diameter: CGFloat {
        switch self {
        case .task:    return TidoDesign.Size.checkboxSize
        case .subtask: return TidoDesign.Size.subtaskCheckbox
        }
    }

    var strokeWidth: CGFloat {
        switch self {
        case .task:    return 1.5
        case .subtask: return 1.3
        }
    }

    var checkmarkScale: CGFloat {
        switch self {
        case .task:    return 0.55
        case .subtask: return 0.5
        }
    }
}

struct CheckboxView: View {

    // MARK: - Input

    let isCompleted: Bool
    var size: CheckboxSize = .task
    var onToggle: () -> Void

    // MARK: - Local State

    @State private var isPressed: Bool = false

    // MARK: - Body

    var body: some View {
        ZStack {
            // Invisible larger hit area
            Circle()
                .fill(Color.white.opacity(0.001))
                .frame(width: size.diameter + 8, height: size.diameter + 8)

            // Visual Checkbox
            ZStack {
                // Background circle / ring
                Circle()
                    .strokeBorder(
                        isCompleted ? TidoDesign.Color.success : TidoDesign.Color.textTertiary.opacity(0.5),
                        lineWidth: size.strokeWidth
                    )
                    .background(
                        Circle()
                            .fill(isCompleted ? TidoDesign.Color.success : Color.clear)
                    )
                    .frame(width: size.diameter, height: size.diameter)
                    .animation(TidoDesign.Animation.spring, value: isCompleted)

                // Checkmark
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: size.diameter * size.checkmarkScale, weight: .bold))
                        .foregroundStyle(.white)
                        .transition(.scale(scale: 0.3).combined(with: .opacity))
                }
            }
        }
        .contentShape(Circle())
        .onTapGesture {
            // Press animation
            withAnimation(TidoDesign.Animation.spring) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(TidoDesign.Animation.spring) { isPressed = false }
            }
            onToggle()
        }
        .scaleEffect(isPressed ? 0.85 : (isCompleted ? 1.05 : 1.0))
        .rotationEffect(.degrees(isCompleted ? 0 : -8))
        .animation(TidoDesign.Animation.spring, value: isCompleted)
        .animation(TidoDesign.Animation.spring, value: isPressed)
        .accessibilityLabel(isCompleted ? "Mark as incomplete" : "Mark as complete")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 20) {
        CheckboxView(isCompleted: false, size: .task) {}
        CheckboxView(isCompleted: true, size: .task) {}
        CheckboxView(isCompleted: false, size: .subtask) {}
        CheckboxView(isCompleted: true, size: .subtask) {}
    }
    .padding()
}
