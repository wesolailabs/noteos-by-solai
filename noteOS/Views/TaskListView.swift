// TaskListView.swift
// Tido — Views
// The main list displaying filtered tasks, search, and new task input.

import SwiftUI
import SwiftData

struct TaskListView: View {

    // MARK: - Input

    @Environment(\.modelContext) private var context
    @Query(sort: \TaskItem.sortOrder) private var allTasks: [TaskItem]
    @StateObject private var store: TaskStore

    // MARK: - Local State

    @State private var showingAddInput: Bool = false

    // MARK: - Init

    init(context: ModelContext) {
        _store = StateObject(wrappedValue: TaskStore(context: context))
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {

            // Header Toolbar
            HStack {
                // Pin Button
                Button {
                    store.isPinned.toggle()
                } label: {
                    Image(systemName: store.isPinned ? "pin.fill" : "pin")
                        .rotationEffect(.degrees(store.isPinned ? 0 : 45))
                        .foregroundStyle(store.isPinned ? TidoDesign.Color.accent : TidoDesign.Color.textSecondary)
                        .padding(6)
                        .background(
                            store.isPinned
                                ? TidoDesign.Color.accent.opacity(0.1)
                                : Color.clear
                        )
                        .continuousRoundedCorners(TidoDesign.Radius.sm)
                }
                .buttonStyle(.plain)
                .help("Pin window to stay above other apps")

                Spacer()

                // Filter Tabs
                FilterTabBar(
                    selection: $store.activeFilter,
                    pendingCount: allTasks.filter { !$0.isCompleted }.count,
                    doneCount: allTasks.filter { $0.isCompleted }.count
                )

                Spacer()

                // Settings Menu
                Menu {
                    Button(LaunchAtLoginService.shared.isEnabled ? "Disable Launch at Login" : "Launch at Login") {
                        LaunchAtLoginService.shared.toggle()
                    }
                    Divider()
                    Button("Quit Tido", role: .destructive) {
                        NSApplication.shared.terminate(nil)
                    }
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(TidoDesign.Color.textSecondary)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 24)
            }
            .padding(.horizontal, TidoDesign.Spacing.md)
            .padding(.vertical, TidoDesign.Spacing.sm)

            // Search Bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(TidoDesign.Color.textTertiary)
                TextField("Search tasks…", text: $store.searchText)
                    .textFieldStyle(.plain)
                    .font(TidoDesign.Font.input)

                if !store.searchText.isEmpty {
                    Button {
                        store.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(TidoDesign.Color.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, TidoDesign.Spacing.sm)
            .padding(.vertical, 8)
            .background(Color.primary.opacity(0.04).continuousRoundedCorners(TidoDesign.Radius.md))
            .padding(.horizontal, TidoDesign.Spacing.md)
            .padding(.bottom, TidoDesign.Spacing.sm)

            Divider().opacity(0.5)

            // Task List Content
            let filteredTasks = store.filtered(allTasks)

            ScrollView(.vertical, showsIndicators: false) {
                if filteredTasks.isEmpty {
                    EmptyStateView(filter: store.activeFilter, searchText: store.searchText)
                } else {
                    LazyVStack(spacing: TidoDesign.Spacing.xxs) {
                        ForEach(filteredTasks) { task in
                            TaskRowView(task: task, store: store)
                        }
                    }
                    .padding(.vertical, TidoDesign.Spacing.sm)
                }
            }
            .frame(maxHeight: TidoDesign.Size.popoverMaxHeight)

            Divider().opacity(0.5)

            // Bottom Add Action
            VStack {
                if showingAddInput {
                    AddTaskField(
                        placeholder: "New task…",
                        onSubmit: { title in
                            store.addTask(title: title)
                            // Keep adding rapid-fire
                        },
                        onCancel: {
                            withAnimation(TidoDesign.Animation.spring) {
                                showingAddInput = false
                            }
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    Button {
                        withAnimation(TidoDesign.Animation.spring) {
                            showingAddInput = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                            Text("New Task")
                            Spacer()
                            Text("⌘N")
                                .font(TidoDesign.Font.caption)
                        }
                        .font(TidoDesign.Font.title)
                        .foregroundStyle(TidoDesign.Color.textSecondary)
                        .padding(.vertical, TidoDesign.Spacing.sm)
                        .padding(.horizontal, TidoDesign.Spacing.md)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(TidoDesign.Spacing.sm)
        }
        // Keyboard Shortcuts
        .onKeyPress(keys: [.return], phases: .down) { _ in
            // CMD+Enter toggles focus to the add field if not searching
            if !showingAddInput {
                showingAddInput = true
                return .handled
            }
            return .ignored
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            // Refresh login state when app comes to foreground
            LaunchAtLoginService.shared.refreshState()
        }
        // Propagate the pinned state to the App level wrapper if needed
        .onChange(of: store.isPinned) {
            // (You could use a preference key or binding to control the popover behavior natively)
        }
    }
}
