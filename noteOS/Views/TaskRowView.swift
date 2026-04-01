// TaskRowView.swift
// noteOS — Views
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
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            mainContent
                .padding(.horizontal, NoteOSDesign.Spacing.md)
                .frame(minHeight: NoteOSDesign.Size.rowMinHeight)
                .noteOSRowBackground(isHovered: isHovered)
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
                                withAnimation(.spring) { showSubtaskInput = false }
                            },
                            onCancel: {
                                withAnimation { showSubtaskInput = false }
                            }
                        )
                        .padding(.vertical, NoteOSDesign.Spacing.xs)
                        .padding(.horizontal, NoteOSDesign.Spacing.md)
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(NoteOSDesign.Animation.spring, value: isExpanded)
    }

    private var mainContent: some View {
        HStack(spacing: NoteOSDesign.Spacing.sm) {
            CheckboxView(
                isCompleted: task.isCompleted,
                size: .task,
                onToggle: { store.toggleTask(task) }
            )

            if isEditing {
                TextField("Task…", text: $editText)
                    .font(NoteOSDesign.Font.taskTitle)
                    .textFieldStyle(.plain)
                    .focused($isTextFieldFocused)
                    .onSubmit { commitEdit() }
                    .onKeyPress(.escape) { cancelEdit(); return .handled }
            } else {
                Text(task.title)
                    .font(NoteOSDesign.Font.taskTitle)
                    .foregroundStyle(
                        task.isCompleted
                            ? NoteOSDesign.Color.textCompleted
                            : NoteOSDesign.Color.textPrimary
                    )
                    .strikethrough(task.isCompleted, color: NoteOSDesign.Color.textCompleted)
                    .lineLimit(2)
                    .animation(NoteOSDesign.Animation.quick, value: task.isCompleted)
            }

            Spacer()

            if !task.subtasks.isEmpty {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { isExpanded.toggle() }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "checklist")
                            .font(.system(size: 9.5, weight: .bold))
                        Text("\(task.completedSubtaskCount)/\(task.subtasks.count)")
                            .font(NoteOSDesign.Font.badge)
                    }
                    .foregroundStyle(
                        task.allSubtasksCompleted
                            ? NoteOSDesign.Color.success
                            : NoteOSDesign.Color.textSecondary
                    )
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(
                        ZStack {
                            if task.allSubtasksCompleted {
                                NoteOSDesign.Color.success.opacity(0.12)
                            } else {
                                Color.primary.opacity(0.06)
                            }
                        }
                    )
                    .continuousRoundedCorners(NoteOSDesign.Radius.sm - 2)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 10) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isExpanded = true
                        showSubtaskInput.toggle()
                    }
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 13, weight: .medium))
                }

                Button(action: { store.deleteTask(task) }) {
                    Image(systemName: "trash")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(NoteOSDesign.Color.destructive.opacity(0.85))
                }
            }
            .padding(.trailing, 8)
            .foregroundStyle(NoteOSDesign.Color.textSecondary.opacity(0.8))
            .buttonStyle(.plain)
            .opacity((isHovered && !isEditing) ? 1.0 : 0.0)
            .animation(NoteOSDesign.Animation.quick, value: isHovered)
            .animation(NoteOSDesign.Animation.quick, value: isEditing)
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            if !isEditing { startEdit() }
        }
    }

    private func startEdit() {
        editText = task.title
        isEditing = true
        isTextFieldFocused = true
    }

    private func commitEdit() {
        let trimmed = editText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            store.updateTask(task, title: trimmed)
        }
        isEditing = false
    }

    private func cancelEdit() {
        isEditing = false
    }
}
