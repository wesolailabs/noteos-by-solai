// TaskItem.swift
// Tido — Models
// Primary data model for a task. Uses SwiftData @Model macro for automatic persistence.

import SwiftData
import Foundation

/// A top-level task item.
/// Owns an ordered list of subtasks.
@Model
final class TaskItem {

    // MARK: - Stored Properties

    /// Unique identifier — stable across launches
    var id: UUID

    /// Task title text
    var title: String

    /// Completion state
    var isCompleted: Bool

    /// Creation timestamp for default sort order
    var createdAt: Date

    /// Optional notes / description (reserved for future use)
    var notes: String

    /// Sort index for drag-and-drop reordering
    var sortOrder: Int

    /// Relationship: subtasks owned by this task
    @Relationship(deleteRule: .cascade, inverse: \SubTaskItem.task)
    var subtasks: [SubTaskItem]

    // MARK: - Init

    init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        createdAt: Date = .now,
        notes: String = "",
        sortOrder: Int = 0
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.notes = notes
        self.sortOrder = sortOrder
        self.subtasks = []
    }

    // MARK: - Computed

    /// True if ALL subtasks are completed (used for visual feedback)
    var allSubtasksCompleted: Bool {
        guard !subtasks.isEmpty else { return false }
        return subtasks.allSatisfy(\.isCompleted)
    }

    /// Pending subtask count shown as badge
    var pendingSubtaskCount: Int {
        subtasks.filter { !$0.isCompleted }.count
    }

    /// Completed subtask count
    var completedSubtaskCount: Int {
        subtasks.filter { $0.isCompleted }.count
    }
}
