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
                            .scaleEffect(isCompleted ? 1.0 : 0.001)
                    )
                    .frame(width: size.diameter, height: size.diameter)
                    .animation(TidoDesign.Animation.spring, value: isCompleted)

                // Checkmark
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: size.diameter * size.checkmarkScale, weight: .bold))
                        .foregroundStyle(.white)
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.1).combined(with: .opacity).animation(.spring(response: 0.35, dampingFraction: 0.4)),
                                removal: .scale(scale: 0.1).combined(with: .opacity).animation(.easeIn(duration: 0.1))
                            )
                        )
                }
            }
        }
        .contentShape(Circle())
        .onTapGesture {
            // Press animation
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) { isPressed = false }
            }
            onToggle()
        }
        .scaleEffect(isPressed ? 0.75 : (isCompleted ? 1.15 : 1.0))
        .rotationEffect(.degrees(isPressed ? -15 : (isCompleted ? 0 : -5)))
        .animation(.spring(response: 0.4, dampingFraction: 0.45), value: isCompleted)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
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
