// SubTaskRowView.swift
// noteOS — Components
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
    @FocusState private var isTextFieldFocused: Bool

    // MARK: - Body

    var body: some View {
        HStack(spacing: NoteOSDesign.Spacing.sm) {
            // Indent spacer to align under parent task content
            Spacer()
                .frame(width: NoteOSDesign.Size.checkboxSize + NoteOSDesign.Spacing.sm)

            // Checkbox
            CheckboxView(
                isCompleted: subtask.isCompleted,
                size: .subtask,
                onToggle: onToggle
            )

            // Title / edit field
            if isEditing {
                TextField("Subtask…", text: $editText)
                    .font(NoteOSDesign.Font.subtask)
                    .textFieldStyle(.plain)
                    .focused($isTextFieldFocused)
                    .onSubmit { commitEdit() }
                    .onKeyPress(.escape) { cancelEdit(); return .handled }
            } else {
                Text(subtask.title)
                    .font(NoteOSDesign.Font.subtask)
                    .foregroundStyle(
                        subtask.isCompleted
                            ? NoteOSDesign.Color.textCompleted
                            : NoteOSDesign.Color.textPrimary
                    )
                    .strikethrough(subtask.isCompleted, color: NoteOSDesign.Color.textCompleted)
                    .lineLimit(2)
                    .animation(NoteOSDesign.Animation.quick, value: subtask.isCompleted)
            }

            Spacer()

            // Delete button — shown on hover
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(NoteOSDesign.Color.textTertiary)
            }
            .buttonStyle(.plain)
            .opacity((isHovered && !isEditing) ? 1.0 : 0.0)
            .animation(NoteOSDesign.Animation.quick, value: isHovered)
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            if !isEditing { startEdit() }
        }
        .padding(.horizontal, NoteOSDesign.Spacing.md)
        .frame(minHeight: NoteOSDesign.Size.subtaskMinHeight)
        .noteOSRowBackground(isHovered: isHovered, cornerRadius: NoteOSDesign.Radius.sm)
        .onHover { isHovered = $0 }
    }

    // MARK: - Edit Helpers

    private func startEdit() {
        editText = subtask.title
        isEditing = true
        isTextFieldFocused = true
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
