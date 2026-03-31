// CheckboxView.swift
// noteOS — Components
// Animated checkbox that provides satisfying visual feedback when toggling completion.
// Two sizes: task-level and subtask-level.

import SwiftUI

enum CheckboxSize {
    case task, subtask

    var diameter: CGFloat {
        switch self {
        case .task:    return NoteOSDesign.Size.checkboxSize
        case .subtask: return NoteOSDesign.Size.subtaskCheckbox
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
    @State private var visualCompleted: Bool = false

    // MARK: - Body

    var body: some View {
        Button(action: handleTap) {
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
                            visualCompleted ? NoteOSDesign.Color.success : NoteOSDesign.Color.textTertiary.opacity(0.5),
                            lineWidth: size.strokeWidth
                        )
                        .background(
                            Circle()
                                .fill(visualCompleted ? NoteOSDesign.Color.success : Color.clear)
                                .scaleEffect(visualCompleted ? 1.0 : 0.001)
                        )
                        .frame(width: size.diameter, height: size.diameter)
                        .animation(NoteOSDesign.Animation.spring, value: visualCompleted)

                    // Checkmark
                    if visualCompleted {
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
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .scaleEffect(isPressed ? 0.75 : (visualCompleted ? 1.15 : 1.0))
        .rotationEffect(.degrees(isPressed ? -15 : (visualCompleted ? 0 : -5)))
        .animation(.spring(response: 0.4, dampingFraction: 0.45), value: visualCompleted)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .onAppear {
            visualCompleted = isCompleted
        }
        .onChange(of: isCompleted) { _, newValue in
            visualCompleted = newValue
        }
        .accessibilityLabel(visualCompleted ? "Mark as incomplete" : "Mark as complete")
        .accessibilityAddTraits(.isButton)
    }

    private func handleTap() {
        // Immediate visual response, independent from persistence latency.
        withAnimation(.spring(response: 0.25, dampingFraction: 0.62)) {
            visualCompleted.toggle()
            isPressed = true
        }

        Task {
            try? await Task.sleep(nanoseconds: 80_000_000)
            await MainActor.run {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) { isPressed = false }
                onToggle()
            }
        }
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
