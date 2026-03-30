// TidoApp.swift
// Tido — Premium macOS Menu Bar App
// Entry point: registers MenuBarExtra and injects the SwiftData container.

import SwiftUI
import SwiftData
import AppKit

@main
struct TidoApp: App {

    // MARK: - State

    /// Controls whether the popover is pinned (stays open when clicking outside)
    @State private var isPinned: Bool = false

    // MARK: - SwiftData container

    private let modelContainer: ModelContainer = {
        let schema = Schema([TaskItem.self, SubTaskItem.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Tido: Could not create ModelContainer — \(error)")
        }
    }()

    // MARK: - Body

    var body: some Scene {

        // MenuBarExtra: the heart of the app.
        // Uses .window style so we can control sizing precisely.
        MenuBarExtra {
            MenuBarView(isPinned: $isPinned)
                .modelContainer(modelContainer)
                .frame(width: 380)
        } label: {
            MenuBarLabel()
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - Menu Bar Label View

/// The icon shown in the system menu bar.
/// Uses SF Symbol "checklist" — semantic, readable at small size, coherent with Apple's design language.
/// Replace the Image here with a custom NSImage from Assets to ship a branded icon.
private struct MenuBarLabel: View {
    var body: some View {
        Image(systemName: "checklist")
            .symbolRenderingMode(.hierarchical)
            .imageScale(.medium)
    }
}
