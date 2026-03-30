// MenuBarView.swift
// Tido — Views
// The root view inside the MenuBarExtra window.
// Responsible for sizing, styling the popover background, and routing to TaskListView.

import SwiftUI
import SwiftData
import AppKit

struct MenuBarView: View {

    @Binding var isPinned: Bool
    @Environment(\.modelContext) private var modelContext

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            TaskListView(context: modelContext)
        }
        .frame(width: TidoDesign.Size.popoverWidth)
        .frame(minHeight: 200, maxHeight: TidoDesign.Size.popoverMaxHeight)
        // ultraThinMaterial gives that native macOS glassy translucency
        .background(Material.ultraThin)
        // A subtle overlay to ensure contrast on very bright/dark backgrounds
        .background(Color(.windowBackgroundColor).opacity(0.15))
        // Window styling hack using introspect
        .onAppear {
            setupWindow()
        }
    }

    // MARK: - Native Window Styling

    /// MenuBarExtra with .window style creates a standard NSWindow.
    /// We intercept it on appear to remove the titlebar, add clipping, and set the floating level.
    private func setupWindow() {
        guard let window = NSApplication.shared.windows.first(where: { $0.isVisible && $0.title.isEmpty }) else {
            return
        }

        // Remove title bar and traffic lights
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true

        // Optionally set corner radius on the content view
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.cornerRadius = TidoDesign.Radius.xl
        window.contentView?.layer?.masksToBounds = true

        // Pinming behavior: Keeps window above everything else if pinned
        if isPinned {
            window.level = .floating
        } else {
            window.level = .normal
        }

        // Optional: observe 'isPinned' changes to update window level on the fly
        // (This would require an NSWindowController or deeper bridging, but for a simple approach we rely on re-renders)
    }
}
