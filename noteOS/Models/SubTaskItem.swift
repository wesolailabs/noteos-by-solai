// SubTaskItem.swift
// noteOS — Models
// Secondary data model for subtasks. Belongs to a TaskItem via inverse relationship.

import SwiftData
import Foundation

/// A subtask nested inside a TaskItem.
@Model
final class SubTaskItem {

    // MARK: - Stored Properties

    var id: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    var sortOrder: Int

    /// Back-reference to the parent task
    var task: TaskItem?

    // MARK: - Init

    init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        createdAt: Date = .now,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.sortOrder = sortOrder
    }
}
