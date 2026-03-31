// SearchTaskField.swift
// noteOS — Components
// Inline input field for searching tasks in the footer.
// Binds directly to the TaskStore search text.

import SwiftUI

struct SearchTaskField: View {

    @Binding var text: String
    var onCancel: (() -> Void)? = nil

    // MARK: - Local State

    @FocusState private var isFocused: Bool

    // MARK: - Body

    var body: some View {
        HStack(spacing: NoteOSDesign.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(NoteOSDesign.Color.accent.opacity(0.8))
                .frame(width: NoteOSDesign.Size.checkboxSize)

            TextField("Search tasks…", text: $text)
                .font(NoteOSDesign.Font.input)
                .foregroundStyle(NoteOSDesign.Color.textPrimary)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .onKeyPress(.escape) {
                    cancel()
                    return .handled
                }

            if !text.isBlank {
                Button {
                    cancel()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(NoteOSDesign.Color.textTertiary)
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .padding(.horizontal, NoteOSDesign.Spacing.md)
        .frame(minHeight: NoteOSDesign.Size.rowMinHeight)
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
            if !focused && text.isEmpty {
                cancel()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isFocused = true
            }
        }
    }

    private func cancel() {
        text = ""
        onCancel?()
    }
}
