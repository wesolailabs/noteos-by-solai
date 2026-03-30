// SearchTaskField.swift
// Tido — Components
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
        HStack(spacing: TidoDesign.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(TidoDesign.Color.accent.opacity(0.8))
                .frame(width: TidoDesign.Size.checkboxSize)

            TextField("Search tasks…", text: $text)
                .font(TidoDesign.Font.input)
                .foregroundStyle(TidoDesign.Color.textPrimary)
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
                        .foregroundStyle(TidoDesign.Color.textTertiary)
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .padding(.horizontal, TidoDesign.Spacing.md)
        .frame(minHeight: TidoDesign.Size.rowMinHeight)
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
