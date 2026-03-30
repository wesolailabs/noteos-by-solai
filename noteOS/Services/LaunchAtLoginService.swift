// LaunchAtLoginService.swift
// Tido — Services
// Manages "Launch at Login" using ServiceManagement framework (macOS 13+).
// SMAppService is the modern, sandboxed-safe replacement for the deprecated LSSharedFileList API.

import Foundation
import ServiceManagement
import Combine

@MainActor
final class LaunchAtLoginService: ObservableObject {

    // MARK: - Singleton

    static let shared = LaunchAtLoginService()

    // MARK: - Published State

    @Published var isEnabled: Bool = false

    // MARK: - Init

    private init() {
        refreshState()
    }

    // MARK: - Public Interface

    func refreshState() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }

    func toggle() {
        if isEnabled {
            disable()
        } else {
            enable()
        }
    }

    // MARK: - Private

    private func enable() {
        do {
            try SMAppService.mainApp.register()
            isEnabled = true
        } catch {
            print("Tido: Could not enable launch at login — \(error.localizedDescription)")
        }
    }

    private func disable() {
        do {
            try SMAppService.mainApp.unregister()
            isEnabled = false
        } catch {
            print("Tido: Could not disable launch at login — \(error.localizedDescription)")
        }
    }
}
