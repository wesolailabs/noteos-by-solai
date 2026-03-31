// AddTaskField.swift
// noteOS — Components
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
    @State private var didSubmit: Bool = false

    // MARK: - Body

    var body: some View {
        HStack(spacing: NoteOSDesign.Spacing.sm) {
            // Left icon — differentiates task vs subtask visually
            Image(systemName: isSubtask ? "arrow.turn.down.right" : "plus")
                .font(.system(size: isSubtask ? 10 : 12, weight: .semibold))
                .foregroundStyle(NoteOSDesign.Color.accent.opacity(0.8))
                .frame(width: isSubtask ? NoteOSDesign.Size.subtaskCheckbox : NoteOSDesign.Size.checkboxSize)

            // Text field
            TextField(placeholder, text: $text)
                .font(isSubtask ? NoteOSDesign.Font.subtask : NoteOSDesign.Font.input)
                .foregroundStyle(NoteOSDesign.Color.textPrimary)
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
                    .font(NoteOSDesign.Font.caption)
                    .foregroundStyle(NoteOSDesign.Color.textTertiary)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .padding(.horizontal, NoteOSDesign.Spacing.md)
        .frame(
            minHeight: isSubtask
                ? NoteOSDesign.Size.subtaskMinHeight
                : NoteOSDesign.Size.rowMinHeight
        )
        .background(
            RoundedRectangle(cornerRadius: NoteOSDesign.Radius.md, style: .continuous)
                .fill(NoteOSDesign.Color.accent.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: NoteOSDesign.Radius.md, style: .continuous)
                        .strokeBorder(
                            isFocused
                                ? NoteOSDesign.Color.accent.opacity(0.35)
                                : NoteOSDesign.Color.separator,
                            lineWidth: 1
                        )
                )
        )
        .animation(NoteOSDesign.Animation.quick, value: text)
        .animation(NoteOSDesign.Animation.quick, value: isFocused)
        .onChange(of: isFocused) { _, focused in
            if !focused && !didSubmit {
                cancel()
            }
            didSubmit = false
        }
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
        guard !submitted.isBlank else {
            cancel()
            return
        }
        didSubmit = true
        text = ""
        onSubmit(submitted)
    }

    private func cancel() {
        text = ""
        onCancel?()
    }
}
