// MenuBarView.swift
// noteOS — Views
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
        .frame(width: NoteOSDesign.Size.popoverWidth)
        .frame(minHeight: 200, maxHeight: NoteOSDesign.Size.popoverMaxHeight)
        // Deep glass: hudWindow samples everything behind the window for true premium blur
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
        // Premium inner border to define the glass edge
        .overlay(
            RoundedRectangle(cornerRadius: NoteOSDesign.Radius.xl + 2, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.16), .white.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        )
        .task {
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

        // Premium corner radius on the content view
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.cornerRadius = NoteOSDesign.Radius.xl + 2
        window.contentView?.layer?.masksToBounds = true

        // Always keep noteOS popover above other windows
        window.identifier = NSUserInterfaceItemIdentifier("wesolai.noteos.menubar.window")
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Pinning behavior is managed by the onChange observer in TaskListView now.
    }
}

// MARK: - Native Glass Effect

/// Represents an exact NSVisualEffectView wrapped for SwiftUI, guaranteeing deep macOS blurring
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
