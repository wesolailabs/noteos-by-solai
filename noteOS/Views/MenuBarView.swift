// MenuBarView.swift
// noteOS — Views
// The root view inside the NSPopover.

import SwiftUI
import SwiftData

struct MenuBarView: View {

    @Environment(\.modelContext) private var modelContext

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            TaskListView(context: modelContext)
        }
        .padding(8)
        .frame(width: NoteOSDesign.Size.popoverWidth)
        .frame(minHeight: 200, maxHeight: NoteOSDesign.Size.popoverMaxHeight)
        // NSPopover provides its own background, but we add our glass touch on top
        .background(Material.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: NoteOSDesign.Radius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: NoteOSDesign.Radius.xl, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.12), .white.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        )
    }
}
