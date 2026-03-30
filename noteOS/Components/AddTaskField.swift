// AddTaskField.swift
// Tido — Components
// Inline input field for creating new tasks or subtasks.
// Auto-focuses, submits on Return, dismisses on Escape.

import SwiftUI

struct AddTaskField: View {

    // MARK: - Configuration

    var placeholder: String = "New task…"
    var isSubtask: Bool = false
    var onSubmit: (String) -> Void
    var onCancel: (() -> Void)? = nil

    // MARK: - Local State

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    // MARK: - Body

    var body: some View {
        HStack(spacing: TidoDesign.Spacing.sm) {
            // Left icon — differentiates task vs subtask visually
            Image(systemName: isSubtask ? "arrow.turn.down.right" : "plus")
                .font(.system(size: isSubtask ? 10 : 12, weight: .semibold))
                .foregroundStyle(TidoDesign.Color.accent.opacity(0.8))
                .frame(width: isSubtask ? TidoDesign.Size.subtaskCheckbox : TidoDesign.Size.checkboxSize)

            // Text field
            TextField(placeholder, text: $text)
                .font(isSubtask ? TidoDesign.Font.subtask : TidoDesign.Font.input)
                .foregroundStyle(TidoDesign.Color.textPrimary)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .onSubmit { submit() }
                .onKeyPress(.escape) {
                    cancel()
                    return .handled
                }

            // Submit hint
            if !text.isBlank {
                Text("↩")
                    .font(TidoDesign.Font.caption)
                    .foregroundStyle(TidoDesign.Color.textTertiary)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .padding(.horizontal, TidoDesign.Spacing.md)
        .frame(
            minHeight: isSubtask
                ? TidoDesign.Size.subtaskMinHeight
                : TidoDesign.Size.rowMinHeight
        )
        .background(
            RoundedRectangle(cornerRadius: TidoDesign.Radius.md, style: .continuous)
                .fill(TidoDesign.Color.accent.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: TidoDesign.Radius.md, style: .continuous)
                        .strokeBorder(
                            isFocused
                                ? TidoDesign.Color.accent.opacity(0.35)
                                : TidoDesign.Color.separator,
                            lineWidth: 1
                        )
                )
        )
        .animation(TidoDesign.Animation.quick, value: text)
        .animation(TidoDesign.Animation.quick, value: isFocused)
        .onAppear {
            // Slight delay so the view is fully laid out before focusing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isFocused = true
            }
        }
    }

    // MARK: - Actions

    private func submit() {
        let submitted = text.trimmed
        text = ""
        guard !submitted.isBlank else {
            cancel()
            return
        }
        onSubmit(submitted)
    }

    private func cancel() {
        text = ""
        onCancel?()
    }
}
