// NoteOSApp.swift
// noteOS — Root
// Entry point: implemented with a native NSStatusItem + NSPopover for 100% reliability.

import SwiftUI
import SwiftData
import AppKit

@main
struct NoteOSApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No Settings or WindowGroup — we are a Menu Bar Only agent.
        Settings { EmptyView() }
    }
}

// MARK: - AppDelegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    
    // Lazy model container to avoid blocking launch
    private lazy var modelContainer: ModelContainer = {
        return StorageBootstrap.makeModelContainer()
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. Create the Popover
        let popover = NSPopover()
        popover.contentSize = NSSize(width: NoteOSDesign.Size.popoverWidth, height: NoteOSDesign.Size.popoverMaxHeight)
        popover.behavior = .transient // Closes when clicking outside
        
        // Inject the view with the model container
        let contentView = MenuBarView()
            .modelContainer(modelContainer)
        
        popover.contentViewController = NSHostingController(rootView: contentView)
        self.popover = popover

        // 2. Create the Status Item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "checklist", accessibilityDescription: "noteOS")
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                popover.contentViewController?.view.window?.makeKey()
            }
        }
    }
}

// MARK: - Storage Bootstrap Logic

struct StorageBootstrap {
    static func makeModelContainer() -> ModelContainer {
        let schema = Schema([TaskItem.self, SubTaskItem.self])
        let fileManager = FileManager.default

        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true)

        let storageURL = appSupportURL.appendingPathComponent("NoteOSStore.sqlite")

        do {
            let config = ModelConfiguration(url: storageURL)
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            print("noteOS: Error initializing SwiftData, falling back to memory: \(error)")
            let memoryConfig = ModelConfiguration(isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: [memoryConfig])
        }
    }
}
