// noteOS — Root
// noteOS — Premium macOS Menu Bar App
// Entry point: registers MenuBarExtra and injects the SwiftData container.

import SwiftUI
import SwiftData
import AppKit

@main
struct NoteOSApp: App {


    // MARK: - SwiftData container

    private let modelContainer: ModelContainer = {
        let schema = Schema([TaskItem.self, SubTaskItem.self])

        // 1. Define explicit URLs for migration and storage
        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let oldStorageURL = appSupportURL.appendingPathComponent("TidoStore.sqlite")
        let storageURL = appSupportURL.appendingPathComponent("NoteOSStore.sqlite")
        
        // Data Migration logic: Move old Tido storage to new NoteOS storage if it exists
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: oldStorageURL.path) && !fileManager.fileExists(atPath: storageURL.path) {
            let filesToMove = [
                (old: oldStorageURL, new: storageURL),
                (old: oldStorageURL.appendingPathExtension("shm"), new: storageURL.appendingPathExtension("shm")),
                (old: oldStorageURL.appendingPathExtension("wal"), new: storageURL.appendingPathExtension("wal"))
            ]
            for pair in filesToMove {
                try? fileManager.moveItem(at: pair.old, to: pair.new)
            }
        }

        let config = ModelConfiguration(url: storageURL)

        func clearStorage() {
            // Delete the explicit Store
            let storeFiles = [
                storageURL,
                storageURL.appendingPathExtension("shm"),
                storageURL.appendingPathExtension("wal"),
                oldStorageURL,
                oldStorageURL.appendingPathExtension("shm"),
                oldStorageURL.appendingPathExtension("wal")
            ]
            for url in storeFiles {
                try? fileManager.removeItem(at: url)
            }

            // Also search for the default SwiftData location just in case
            let bundleID = Bundle.main.bundleIdentifier ?? "noteOS"
            let defaultFolder = appSupportURL.appendingPathComponent(bundleID)
            let defaultFiles = ["default.store", "default.store-shm", "default.store-wal"]
            for file in defaultFiles {
                try? fileManager.removeItem(at: defaultFolder.appendingPathComponent(file))
                try? fileManager.removeItem(at: defaultFolder.appendingPathComponent("SwiftData").appendingPathComponent(file))
            }
        }

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            print("noteOS: Storage initialization failed. Wiping data for fresh start...")
            clearStorage()

            do {
                // Secondary attempt with a fresh, empty store
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                // Last ditch effort: Try in-memory if disk is truly broken
                print("noteOS: Disk storage is unusable. Falling back to in-memory.")
                let memConfig = ModelConfiguration(isStoredInMemoryOnly: true)
                return try! ModelContainer(for: schema, configurations: [memConfig])
            }
        }
    }();

    // MARK: - Body

    var body: some Scene {

        // MenuBarExtra: the heart of the app.
        // Uses .window style so we can control sizing precisely.
        MenuBarExtra {
            MenuBarView()
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
