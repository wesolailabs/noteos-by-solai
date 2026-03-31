// noteOS — Root
// noteOS — Premium macOS Menu Bar App
// Entry point: registers MenuBarExtra and injects the SwiftData container.

import SwiftUI
import SwiftData
import AppKit
import Foundation

@main
struct NoteOSApp: App {


    // MARK: - SwiftData container

    private let modelContainer: ModelContainer = Self.makeModelContainer()

    // MARK: - Body

    var body: some Scene {

        // MenuBarExtra: the heart of the app.
        // Uses .window style so we can control sizing precisely.
        MenuBarExtra {
            MenuBarView()
                .modelContainer(modelContainer)
                .frame(width: NoteOSDesign.Size.popoverWidth)
        } label: {
            MenuBarLabel()
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - Storage Bootstrap

private extension NoteOSApp {
    static func makeModelContainer() -> ModelContainer {
        let schema = Schema([TaskItem.self, SubTaskItem.self])
        let fileManager = FileManager.default

        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true)

        let legacyStorageURL = appSupportURL.appendingPathComponent("TidoStore.sqlite")
        let storageURL = appSupportURL.appendingPathComponent("NoteOSStore.sqlite")

        migrateLegacyStoreIfNeeded(from: legacyStorageURL, to: storageURL, fileManager: fileManager)

        do {
            return try openContainer(schema: schema, storageURL: storageURL)
        } catch {
            print("noteOS: Could not open persistent store at \(storageURL.path): \(error.localizedDescription)")
        }

        quarantineBrokenStore(at: storageURL, fileManager: fileManager)

        do {
            print("noteOS: Retrying with a fresh persistent store.")
            return try openContainer(schema: schema, storageURL: storageURL)
        } catch {
            print("noteOS: Fresh persistent store also failed: \(error.localizedDescription)")
        }

        do {
            print("noteOS: Falling back to in-memory storage for this run.")
            let memoryConfig = ModelConfiguration(isStoredInMemoryOnly: true)
            return try ModelContainer(for: schema, configurations: [memoryConfig])
        } catch {
            fatalError("noteOS: Unable to initialize any ModelContainer. \(error.localizedDescription)")
        }
    }

    static func openContainer(schema: Schema, storageURL: URL) throws -> ModelContainer {
        let config = ModelConfiguration(url: storageURL)
        return try ModelContainer(for: schema, configurations: [config])
    }

    static func migrateLegacyStoreIfNeeded(from oldURL: URL, to newURL: URL, fileManager: FileManager) {
        guard fileManager.fileExists(atPath: oldURL.path), !fileManager.fileExists(atPath: newURL.path) else { return }

        let filesToMove = [
            (old: oldURL, new: newURL),
            (old: oldURL.appendingPathExtension("shm"), new: newURL.appendingPathExtension("shm")),
            (old: oldURL.appendingPathExtension("wal"), new: newURL.appendingPathExtension("wal"))
        ]

        for pair in filesToMove where fileManager.fileExists(atPath: pair.old.path) {
            do {
                try fileManager.moveItem(at: pair.old, to: pair.new)
            } catch {
                print("noteOS: Legacy store migration warning (\(pair.old.lastPathComponent)): \(error.localizedDescription)")
            }
        }
    }

    static func quarantineBrokenStore(at storageURL: URL, fileManager: FileManager) {
        let relatedFiles = [
            storageURL,
            storageURL.appendingPathExtension("shm"),
            storageURL.appendingPathExtension("wal")
        ]

        guard relatedFiles.contains(where: { fileManager.fileExists(atPath: $0.path) }) else { return }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        let timestamp = formatter.string(from: Date()).replacingOccurrences(of: ":", with: "-")

        let quarantineRoot = storageURL.deletingLastPathComponent().appendingPathComponent("CorruptedStores", isDirectory: true)
        let quarantineFolder = quarantineRoot.appendingPathComponent("NoteOSStore-\(timestamp)", isDirectory: true)

        do {
            try fileManager.createDirectory(at: quarantineFolder, withIntermediateDirectories: true)

            for file in relatedFiles where fileManager.fileExists(atPath: file.path) {
                let destination = quarantineFolder.appendingPathComponent(file.lastPathComponent)
                try fileManager.moveItem(at: file, to: destination)
            }

            print("noteOS: Moved broken store files to \(quarantineFolder.path)")
        } catch {
            print("noteOS: Could not quarantine broken store files: \(error.localizedDescription)")
        }
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
