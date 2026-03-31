// FilterTabBar.swift
// noteOS — Components
// Segmented filter control: All / Pending / Done.
// Uses a custom pill-style indicator for a premium feel over the default Picker.

import SwiftUI

struct FilterTabBar: View {

    @Binding var selection: TaskFilter
    let pendingCount: Int
    let doneCount: Int

    // MARK: - Namespace

    @Namespace private var tabNamespace

    // MARK: - Body

    var body: some View {
        HStack(spacing: 1) {
            ForEach(TaskFilter.allCases) { filter in
                filterButton(filter)
            }
        }
        .padding(2.5)
        .background(
            RoundedRectangle(cornerRadius: NoteOSDesign.Radius.md, style: .continuous)
                .fill(.primary.opacity(0.07))
        )
    }

    // MARK: - Filter Button

    @ViewBuilder
    private func filterButton(_ filter: TaskFilter) -> some View {
        let isSelected = selection == filter

        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.68)) {
                selection = filter
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: filter.systemImage)
                    .font(.system(size: 9.5, weight: .semibold))

                Text(filter.rawValue)
                    .font(NoteOSDesign.Font.header)
                    .fixedSize(horizontal: true, vertical: false)

                // Count badge
                if let count = badgeCount(for: filter), count > 0 {
                    Text("\(count)")
                        .font(NoteOSDesign.Font.badge)
                        .foregroundStyle(isSelected ? NoteOSDesign.Color.accent : NoteOSDesign.Color.textTertiary)
                        .padding(.horizontal, 4.5)
                        .padding(.vertical, 1)
                        .background(
                            Capsule()
                                .fill(isSelected
                                      ? NoteOSDesign.Color.accent.opacity(0.18)
                                      : Color.primary.opacity(0.08))
                        )
                }
            }
            .foregroundStyle(isSelected ? NoteOSDesign.Color.accent : NoteOSDesign.Color.textSecondary)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(filter.rawValue))
        .accessibilityValue(Text(isSelected ? "Selected" : "Not selected"))
        .accessibilityHint(Text("Show \(filter.rawValue.lowercased()) tasks"))
        .matchedGeometryEffect(id: filter.id, in: tabNamespace, isSource: true)
        .background(
            Group {
                if isSelected {
                    RoundedRectangle(cornerRadius: NoteOSDesign.Radius.sm, style: .continuous)
                        .fill(.background)
                        .matchedGeometryEffect(id: "tab_pill", in: tabNamespace, isSource: false)
                        .shadow(color: .black.opacity(0.12), radius: 5, x: 0, y: 1.5)
                }
            }
        )
    }

    // MARK: - Helpers

    private func badgeCount(for filter: TaskFilter) -> Int? {
        switch filter {
        case .all:     return pendingCount + doneCount
        case .pending: return pendingCount
        case .done:    return doneCount
        }
    }
}
