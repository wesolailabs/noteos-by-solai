// TaskRowView.swift
// Tido — Views
// A single top-level task row. Supports swipe actions, subtask expansion, and inline creation.

import SwiftUI

struct TaskRowView: View {

    let task: TaskItem
    @ObservedObject var store: TaskStore

    @State private var isHovered: Bool = false
    @State private var isExpanded: Bool = false
    @State private var showSubtaskInput: Bool = false
    @State private var isEditing: Bool = false
    @State private var editText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            mainContent
                .padding(.horizontal, TidoDesign.Spacing.md)
                .frame(minHeight: TidoDesign.Size.rowMinHeight)
                .tidoRowBackground(isHovered: isHovered)
                .onHover { isHovered = $0 }
                .contextMenu {
                    Button(task.isCompleted ? "Mark Incomplete" : "Mark Complete") {
                        store.toggleTask(task)
                    }
                    Button("Add Subtask") {
                        withAnimation {
                            isExpanded = true
                            showSubtaskInput = true
                        }
                    }
                    Divider()
                    Button("Delete Task", role: .destructive) {
                        store.deleteTask(task)
                    }
                }

            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(task.subtasks.sorted { $0.sortOrder < $1.sortOrder }) { subtask in
                        SubTaskRowView(
                            subtask: subtask,
                            onToggle: { store.toggleSubtask(subtask) },
                            onDelete: { store.deleteSubtask(subtask, from: task) },
                            onUpdate: { store.updateSubtask(subtask, title: $0) }
                        )
                    }

                    if showSubtaskInput {
                        AddTaskField(
                            placeholder: "New subtask…",
                            isSubtask: true,
                            onSubmit: { title in
                                store.addSubtask(to: task, title: title)
                            },
                            onCancel: {
                                withAnimation { showSubtaskInput = false }
                            }
                        )
                        .padding(.vertical, TidoDesign.Spacing.xs)
                        .padding(.horizontal, TidoDesign.Spacing.md)
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(TidoDesign.Animation.spring, value: isExpanded)
    }

    private var mainContent: some View {
        HStack(spacing: TidoDesign.Spacing.sm) {
            CheckboxView(
                isCompleted: task.isCompleted,
                size: .task,
                onToggle: { store.toggleTask(task) }
            )

            if isEditing {
                TextField("Task…", text: $editText)
                    .font(TidoDesign.Font.taskTitle)
                    .textFieldStyle(.plain)
                    .onSubmit { commitEdit() }
                    .onAppear { editText = task.title }
            } else {
                Text(task.title)
                    .font(TidoDesign.Font.taskTitle)
                    .foregroundStyle(
                        task.isCompleted
                            ? TidoDesign.Color.textCompleted
                            : TidoDesign.Color.textPrimary
                    )
                    .strikethrough(task.isCompleted, color: TidoDesign.Color.textCompleted)
                    .lineLimit(2)
                    .animation(TidoDesign.Animation.quick, value: task.isCompleted)
                    .onTapGesture(count: 2) { startEdit() }
            }

            Spacer()

            if !task.subtasks.isEmpty {
                Button {
                    withAnimation { isExpanded.toggle() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "checklist")
                            .font(.system(size: 10, weight: .semibold))
                        Text("\(task.completedSubtaskCount)/\(task.subtasks.count)")
                            .font(TidoDesign.Font.badge)
                    }
                    .foregroundStyle(
                        task.allSubtasksCompleted
                            ? TidoDesign.Color.success
                            : TidoDesign.Color.textTertiary
                    )
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.primary.opacity(0.06).continuousRoundedCorners(TidoDesign.Radius.sm))
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                Button {
                    withAnimation {
                        isExpanded = true
                        showSubtaskInput.toggle()
                    }
                } label: {
                    Image(systemName: "plus.circle")
                }

                Button(action: { store.deleteTask(task) }) {
                    Image(systemName: "trash")
                        .foregroundStyle(TidoDesign.Color.destructive.opacity(0.8))
                }
            }
            .frame(width: 50, alignment: .trailing)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(TidoDesign.Color.textSecondary)
            .buttonStyle(.plain)
            .opacity((isHovered && !isEditing) ? 1.0 : 0.0)
            .animation(TidoDesign.Animation.quick, value: isHovered)
            .animation(TidoDesign.Animation.quick, value: isEditing)
        }
        .contentShape(Rectangle())
    }

    private func startEdit() {
        editText = task.title
        isEditing = true
    }

    private func commitEdit() {
        let trimmed = editText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            store.updateTask(task, title: trimmed)
        }
        isEditing = false
    }
}
