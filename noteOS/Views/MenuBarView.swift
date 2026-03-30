// MenuBarView.swift
// Tido — Views
// The root view inside the MenuBarExtra window.
// Responsible for sizing, styling the popover background, and routing to TaskListView.

import SwiftUI
import SwiftData
import AppKit

struct MenuBarView: View {

    @Environment(\.modelContext) private var modelContext

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            TaskListView(context: modelContext)
        }
        .frame(width: TidoDesign.Size.popoverWidth)
        .frame(minHeight: 200, maxHeight: TidoDesign.Size.popoverMaxHeight)
        // ultraThin gives that high-end glassy translucency
        .background(Material.ultraThin)
        // Window styling hack using introspect
        .task {
            // Wait a tick for the window to be available before setting it up
            try? await Task.sleep(for: .milliseconds(50))
            await MainActor.run {
                setupWindow()
            }
        }
    }

    // MARK: - Native Window Styling

    /// MenuBarExtra with .window style creates a standard NSWindow.
    /// We intercept it on appear to remove the titlebar, add clipping, and set the floating level.
    private func setupWindow() {
        guard let window = NSApplication.shared.windows.first(where: { $0.isKeyWindow || $0.isVisible }) else {
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

        // Always keep Tido popover above other windows
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Pinning behavior is managed by the onChange observer in TaskListView now.
    }
}
