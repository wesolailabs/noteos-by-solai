// FilterTabBar.swift
// Tido — Components
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
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: TidoDesign.Radius.md, style: .continuous)
                .fill(.primary.opacity(0.06))
        )
    }

    // MARK: - Filter Button

    @ViewBuilder
    private func filterButton(_ filter: TaskFilter) -> some View {
        let isSelected = selection == filter

        Button {
            withAnimation(TidoDesign.Animation.spring) {
                selection = filter
            }
        } label: {
            HStack(spacing: 3) {
                Image(systemName: filter.systemImage)
                    .font(.system(size: 10, weight: .semibold))

                Text(filter.rawValue)
                    .font(TidoDesign.Font.header)

                // Count badge
                if let count = badgeCount(for: filter), count > 0 {
                    Text("\(count)")
                        .font(TidoDesign.Font.badge)
                        .foregroundStyle(isSelected ? TidoDesign.Color.accent : TidoDesign.Color.textTertiary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 0.5)
                        .background(
                            Capsule()
                                .fill(isSelected
                                      ? TidoDesign.Color.accent.opacity(0.15)
                                      : Color.primary.opacity(0.07))
                        )
                }
            }
            .foregroundStyle(isSelected ? TidoDesign.Color.accent : TidoDesign.Color.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .matchedGeometryEffect(id: filter.id, in: tabNamespace, isSource: true)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: TidoDesign.Radius.sm, style: .continuous)
                            .fill(.background)
                            .matchedGeometryEffect(id: "tab_pill", in: tabNamespace, isSource: false)
                            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 1)
                    }
                }
            )
        }
        .buttonStyle(.plain)
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
