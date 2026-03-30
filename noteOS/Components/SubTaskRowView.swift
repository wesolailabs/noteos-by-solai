// SubTaskRowView.swift
// Tido — Components
// A single subtask row: checkbox + inline-editable title + swipe/hover delete.

import SwiftUI

struct SubTaskRowView: View {

    // MARK: - Input

    let subtask: SubTaskItem
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onUpdate: (String) -> Void

    // MARK: - Local State

    @State private var isHovered: Bool = false
    @State private var isEditing: Bool = false
    @State private var editText: String = ""

    // MARK: - Body

    var body: some View {
        HStack(spacing: TidoDesign.Spacing.sm) {
            // Indent spacer to align under parent task content
            Spacer()
                .frame(width: TidoDesign.Size.checkboxSize + TidoDesign.Spacing.sm)

            // Checkbox
            CheckboxView(
                isCompleted: subtask.isCompleted,
                size: .subtask,
                onToggle: onToggle
            )

            // Title / edit field
            if isEditing {
                TextField("Subtask…", text: $editText)
                    .font(TidoDesign.Font.subtask)
                    .textFieldStyle(.plain)
                    .onSubmit { commitEdit() }
                    .onKeyPress(.escape) { cancelEdit(); return .handled }
                    .onAppear { editText = subtask.title }
            } else {
                Text(subtask.title)
                    .font(TidoDesign.Font.subtask)
                    .foregroundStyle(
                        subtask.isCompleted
                            ? TidoDesign.Color.textCompleted
                            : TidoDesign.Color.textPrimary
                    )
                    .strikethrough(subtask.isCompleted, color: TidoDesign.Color.textCompleted)
                    .lineLimit(2)
                    .animation(TidoDesign.Animation.quick, value: subtask.isCompleted)
                    .onTapGesture(count: 2) { startEdit() }
            }

            Spacer()

            // Delete button — shown on hover
            if isHovered && !isEditing {
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(TidoDesign.Color.textTertiary)
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale(scale: 0.7)))
            }
        }
        .padding(.horizontal, TidoDesign.Spacing.md)
        .frame(minHeight: TidoDesign.Size.subtaskMinHeight)
        .tidoRowBackground(isHovered: isHovered, cornerRadius: TidoDesign.Radius.sm)
        .onHover { isHovered = $0 }
        .animation(TidoDesign.Animation.quick, value: isHovered)
    }

    // MARK: - Edit Helpers

    private func startEdit() {
        editText = subtask.title
        isEditing = true
    }

    private func commitEdit() {
        if !editText.trimmed.isBlank {
            onUpdate(editText.trimmed)
        }
        isEditing = false
    }

    private func cancelEdit() {
        isEditing = false
    }
}
