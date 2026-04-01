// EmptyStateView.swift
// noteOS — Views
// Displayed when there are no tasks matching the current filter/search.
// Premium illustration-style empty state with contextual messaging.

import SwiftUI

struct EmptyStateView: View {

    let filter: TaskFilter

    @State private var isPulsing: Bool = false

    // MARK: - Computed

    private var symbol: String {
        switch filter {
        case .all:     return "checklist"
        case .pending: return "tray"
        case .done:    return "checkmark.seal.fill"
        }
    }

    private var title: String {
        switch filter {
        case .all:     return "All clear"
        case .pending: return "No active tasks"
        case .done:    return "Not done yet"
        }
    }

    private var subtitle: String {
        switch filter {
        case .all:     return "Add your first task below"
        case .pending: return "Take a break, or add a new one"
        case .done:    return "Complete a task to see it here"
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 14) {
            // Animated orb
            ZStack {
                // Outer pulse ring
                Circle()
                    .fill(NoteOSDesign.Color.accent.opacity(0.06))
                    .frame(width: isPulsing ? 68 : 58, height: isPulsing ? 68 : 58)
                    .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: isPulsing)

                // Middle ring with gradient stroke
                Circle()
                    .strokeBorder(
                        AngularGradient(
                            colors: [
                                NoteOSDesign.Color.accent.opacity(0.35),
                                NoteOSDesign.Color.accent.opacity(0.08),
                                NoteOSDesign.Color.accent.opacity(0.35)
                            ],
                            center: .center
                        ),
                        lineWidth: 1
                    )
                    .frame(width: 50, height: 50)

                // Inner fill circle
                Circle()
                    .fill(NoteOSDesign.Color.accent.opacity(0.10))
                    .frame(width: 44, height: 44)

                // Icon
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(NoteOSDesign.Color.accent.opacity(0.75))
                    .symbolRenderingMode(.hierarchical)
            }
            .onAppear { isPulsing = true }

            VStack(spacing: 5) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(NoteOSDesign.Color.textPrimary)

                Text(subtitle)
                    .font(.system(size: 11.5, weight: .regular))
                    .foregroundStyle(NoteOSDesign.Color.textTertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, NoteOSDesign.Spacing.lg)
        .offset(y: -10)
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }
}

