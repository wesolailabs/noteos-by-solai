// TaskStore.swift
// Tido — Store
// Central state manager. Wraps SwiftData context operations and exposes clean,
// testable actions to the views. All mutations go through here.

import SwiftUI
import SwiftData
import Combine

// MARK: - Filter

enum TaskFilter: String, CaseIterable, Identifiable {
    case all       = "All"
    case pending   = "Pending"
    case done      = "Done"

    var id: Self { self }

    var systemImage: String {
        switch self {
        case .all:     return "tray.full"
        case .pending: return "circle"
        case .done:    return "checkmark.circle.fill"
        }
    }
}

// MARK: - TaskStore

@MainActor
final class TaskStore: ObservableObject {

    // MARK: - Published UI State

    @Published var activeFilter: TaskFilter = .pending
    @Published var selectedWorkspace: String? = nil
    @Published var searchText: String = ""

    // MARK: - Context

    private var context: ModelContext

    // MARK: - Init

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Task CRUD

    /// Creates and inserts a new task. Returns the new task so the caller can react.
    @discardableResult
    func addTask(title: String) -> TaskItem? {
        let trimmed = title.trimmed
        guard !trimmed.isBlank else { return nil }

        // Determine next sort order
        var descriptor = FetchDescriptor<TaskItem>(sortBy: [SortDescriptor(\.sortOrder, order: .reverse)])
        descriptor.fetchLimit = 1
        let maxOrder = (try? context.fetch(descriptor))?.first?.sortOrder ?? -1
        let nextOrder = maxOrder + 1

        let task = TaskItem(
            title: trimmed,
            sortOrder: nextOrder,
            workspace: selectedWorkspace ?? "Personal"
        )
        context.insert(task)
        save()
        return task
    }

    /// Toggles completion and triggers a haptic-friendly feedback flag.
    func toggleTask(_ task: TaskItem) {
        task.isCompleted.toggle()
        // If completing, also complete all subtasks for clarity
        if task.isCompleted {
            task.subtasks.forEach { $0.isCompleted = true }
        }
        save()
    }

    /// Updates the task title in place.
    func updateTask(_ task: TaskItem, title: String) {
        let trimmed = title.trimmed
        guard !trimmed.isBlank else { return }
        task.title = trimmed
        save()
    }

    /// Deletes one or more tasks by SwiftData model.
    func deleteTask(_ task: TaskItem) {
        context.delete(task)
        save()
    }

    func deleteTasks(at offsets: IndexSet, from tasks: [TaskItem]) {
        offsets.map { tasks[$0] }.forEach { context.delete($0) }
        save()
    }

    /// Reorders tasks by updating sortOrder indices.
    func moveTasks(from source: IndexSet, to destination: Int, in tasks: [TaskItem]) {
        var reordered = tasks
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, task) in reordered.enumerated() {
            task.sortOrder = index
        }
        save()
    }

    // MARK: - Workspace Management
    
    private let customWorkspacesKey = "tido_custom_workspaces"
    
    private var savedWorkspaces: [String] {
        get {
            let array = UserDefaults.standard.stringArray(forKey: customWorkspacesKey) ?? []
            // Preserve order while removing duplicates and 'Personal'
            var unique: [String] = []
            for ws in array {
                if ws != "Personal", !unique.contains(ws) {
                    unique.append(ws)
                }
            }
            return unique
        }
        set {
            UserDefaults.standard.set(newValue, forKey: customWorkspacesKey)
            objectWillChange.send()
        }
    }
    
    func createWorkspace(_ name: String) {
        let trimmed = name.trimmed
        guard !trimmed.isBlank else { return }
        
        var ws = savedWorkspaces
        if !ws.contains(trimmed) && trimmed != "Personal" {
            ws.append(trimmed)
            savedWorkspaces = ws
        }
        
        selectedWorkspace = trimmed
    }

    func renameWorkspace(from oldName: String, to newName: String) {
        let trimmed = newName.trimmed
        guard !trimmed.isBlank, trimmed != oldName else { return }
        
        // Prevent renaming the default "Personal" workspace
        guard oldName != "Personal" else { return }

        // Fetch ALL tasks globally to catch those hidden by filters (Done tasks)
        let descriptor = FetchDescriptor<TaskItem>()
        if let allTasks = try? context.fetch(descriptor) {
            allTasks.filter { $0.workspace == oldName }.forEach {
                $0.workspace = trimmed
            }
        }
        
        // Update UserDefaults
        var ws = savedWorkspaces
        if let index = ws.firstIndex(of: oldName) {
            ws[index] = trimmed // Swap in-place to preserve order
        } else if !ws.contains(trimmed) {
            ws.append(trimmed)
        }
        savedWorkspaces = ws
        
        // Update current selection if it matches
        if selectedWorkspace == oldName {
            selectedWorkspace = trimmed
        }
        
        save()
    }

    func deleteWorkspace(_ name: String) {
        // Prevent deleting the default "Personal" workspace
        guard name != "Personal" else { return }
        
        // Fetch ALL tasks globally to catch hidden ones
        let descriptor = FetchDescriptor<TaskItem>()
        if let allTasks = try? context.fetch(descriptor) {
            allTasks.filter { $0.workspace == name }.forEach {
                context.delete($0)
            }
        }
        
        // Update UserDefaults
        var ws = savedWorkspaces
        ws.removeAll { $0 == name }
        savedWorkspaces = ws
        
        // Reset selection if it was the deleted workspace
        if selectedWorkspace == name {
            selectedWorkspace = nil
        }
        
        save()
    }
    
    func moveWorkspaceUp(_ name: String) {
        guard name != "Personal" else { return }
        var ws = savedWorkspaces
        if let idx = ws.firstIndex(of: name), idx > 0 {
            ws.swapAt(idx, idx - 1)
            savedWorkspaces = ws
        }
    }

    func moveWorkspaceDown(_ name: String) {
        guard name != "Personal" else { return }
        var ws = savedWorkspaces
        if let idx = ws.firstIndex(of: name), idx < ws.count - 1 {
            ws.swapAt(idx, idx + 1)
            savedWorkspaces = ws
        }
    }

    // MARK: - Subtask CRUD

    @discardableResult
    func addSubtask(to task: TaskItem, title: String) -> SubTaskItem? {
        let trimmed = title.trimmed
        guard !trimmed.isBlank else { return nil }

        let nextOrder = task.subtasks.count
        let subtask = SubTaskItem(title: trimmed, sortOrder: nextOrder)
        subtask.task = task
        task.subtasks.append(subtask)
        context.insert(subtask)
        save()
        return subtask
    }

    func toggleSubtask(_ subtask: SubTaskItem) {
        subtask.isCompleted.toggle()
        save()
    }

    func updateSubtask(_ subtask: SubTaskItem, title: String) {
        let trimmed = title.trimmed
        guard !trimmed.isBlank else { return }
        subtask.title = trimmed
        save()
    }

    func deleteSubtask(_ subtask: SubTaskItem, from task: TaskItem) {
        task.subtasks.removeAll { $0.id == subtask.id }
        context.delete(subtask)
        save()
    }

    /// Applies the active filter and search text.
    func filtered(_ tasks: [TaskItem]) -> [TaskItem] {
        var result = tasks

        // Workspace Filter
        if let workspace = selectedWorkspace {
            result = result.filter { $0.workspace == workspace }
        }

        // Status Filter
        switch activeFilter {
        case .all:     break
        case .pending: result = result.filter { !$0.isCompleted }
        case .done:    result = result.filter { $0.isCompleted }
        }

        // Search Filter
        let query = searchText.trimmed.lowercased()
        if !query.isEmpty {
            result = result.filter {
                $0.title.lowercased().contains(query) ||
                $0.subtasks.contains { $0.title.lowercased().contains(query) }
            }
        }

        return result
    }

    /// Dynamic list of workspaces based on existing tasks and saved custom empty ones
    func getAvailableWorkspaces(_ tasks: [TaskItem]) -> [String] {
        var ordered = ["Personal"]
        let saved = savedWorkspaces
        ordered.append(contentsOf: saved)
        
        // Include workspaces found in tasks or selection that aren't naturally tracked
        var runtimeFound = Set(tasks.map(\.workspace))
        if let selected = selectedWorkspace {
            runtimeFound.insert(selected)
        }
        runtimeFound.remove("Personal")
        
        let unsaved = runtimeFound.subtracting(Set(saved)).sorted()
        ordered.append(contentsOf: unsaved)
        
        return ordered
    }

    // MARK: - Private

    private func save() {
        do {
            try context.save()
        } catch {
            print("Tido: SwiftData save error — \(error.localizedDescription)")
        }
    }
}
