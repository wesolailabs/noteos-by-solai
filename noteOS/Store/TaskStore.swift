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

    var id: String { rawValue }

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

    @Published var searchText: String = ""
    @Published var activeFilter: TaskFilter = .pending
    @Published var isPinned: Bool = false

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
        let nextOrder = (try? context.fetch(FetchDescriptor<TaskItem>()))?.count ?? 0

        let task = TaskItem(title: trimmed, sortOrder: nextOrder)
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

    // MARK: - Filtering / Search

    /// Applies the active filter and search query to a flat task array.
    func filtered(_ tasks: [TaskItem]) -> [TaskItem] {
        var result = tasks

        // Filter
        switch activeFilter {
        case .all:     break
        case .pending: result = result.filter { !$0.isCompleted }
        case .done:    result = result.filter { $0.isCompleted }
        }

        // Search
        let query = searchText.trimmed.lowercased()
        if !query.isEmpty {
            result = result.filter {
                $0.title.lowercased().contains(query) ||
                $0.subtasks.contains { $0.title.lowercased().contains(query) }
            }
        }

        return result
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
