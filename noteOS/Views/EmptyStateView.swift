// EmptyStateView.swift
// Tido — Views
// Displayed when there are no tasks matching the current filter/search.
// Premium illustration-style empty state with contextual messaging.

import SwiftUI

struct EmptyStateView: View {

    let filter: TaskFilter

    // MARK: - Computed

    private var symbol: String {
        switch filter {
        case .all:     return "checklist"
        case .pending: return "sparkles"
        case .done:    return "checkmark.seal.fill"
        }
    }

    private var title: String {
        switch filter {
        case .all:     return "All clear"
        case .pending: return "Nothing pending"
        case .done:    return "Not done yet"
        }
    }

    private var subtitle: String {
        switch filter {
        case .all:     return "Add your first task below"
        case .pending: return "Everything's taken care of ✓"
        case .done:    return "Complete a task to see it here"
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: TidoDesign.Spacing.md) {
            // Icon orb
            ZStack {
                Circle()
                    .fill(TidoDesign.Color.accent.opacity(0.08))
                    .frame(width: 64, height: 64)

                Circle()
                    .fill(TidoDesign.Color.accent.opacity(0.12))
                    .frame(width: 48, height: 48)

                Image(systemName: symbol)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(TidoDesign.Color.accent.opacity(0.7))
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(spacing: TidoDesign.Spacing.xxs) {
                Text(title)
                    .font(TidoDesign.Font.title)
                    .foregroundStyle(TidoDesign.Color.textPrimary)

                Text(subtitle)
                    .font(TidoDesign.Font.caption)
                    .foregroundStyle(TidoDesign.Color.textTertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, TidoDesign.Spacing.xl)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}
