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

    // MARK: - Local State

    @State private var showingAddInput: Bool = false
    @State private var showingSearchInput: Bool = false
    @State private var showingRenameAlert: Bool = false
    @State private var showingNewWorkspaceAlert: Bool = false
    @State private var workspaceNameInput: String = ""
    @State private var workspaceToRename: String = ""

    // MARK: - Init

    init(context: ModelContext) {
        _store = StateObject(wrappedValue: TaskStore(context: context))
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {

        VStack(spacing: 0) {

            // Header Toolbar
            ZStack {
                // Workspace Selector (Left Wing)
                HStack {
                    Menu {
                        Button {
                            store.selectedWorkspace = nil
                        } label: {
                            HStack {
                                Text("All Workspaces")
                                if store.selectedWorkspace == nil {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }

                        Divider()

                        ForEach(store.getAvailableWorkspaces(allTasks), id: \.self) { ws in
                            Menu {
                                Button {
                                    store.selectedWorkspace = ws
                                } label: {
                                    Label("Select", systemImage: "checkmark")
                                }
                                
                                Divider()
                                
                                Button {
                                    workspaceToRename = ws
                                    workspaceNameInput = ws
                                    showingRenameAlert = true
                                } label: {
                                    Label("Rename...", systemImage: "pencil")
                                }
                                
                                Button(role: .destructive) {
                                    store.deleteWorkspace(ws)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            } label: {
                                HStack {
                                    Text(ws)
                                    if store.selectedWorkspace == ws {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }

                        Divider()

                        Button {
                            workspaceNameInput = ""
                            showingNewWorkspaceAlert = true
                        } label: {
                            Label("New Workspace...", systemImage: "plus.rectangle.on.folder")
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: store.selectedWorkspace == nil ? "folder" : "folder.fill")
                                .imageScale(.medium)
                            if let selected = store.selectedWorkspace {
                                Text(selected)
                                    .font(TidoDesign.Font.caption.weight(.medium))
                                    .lineLimit(1)
                            }
                        }
                        .foregroundStyle(store.selectedWorkspace == nil ? TidoDesign.Color.textSecondary : TidoDesign.Color.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(
                            (store.selectedWorkspace == nil ? Color.clear : TidoDesign.Color.accent.opacity(0.1))
                                .continuousRoundedCorners(TidoDesign.Radius.sm)
                        )
                    }
                    .buttonStyle(.plain)
                    .menuIndicator(.hidden)
                    .help("Switch Workspace")
                    
                    Spacer()
                }

                // Filter Tabs (Center)
                FilterTabBar(
                    selection: $store.activeFilter,
                    pendingCount: allTasks.filter { !$0.isCompleted }.count,
                    doneCount: allTasks.filter { $0.isCompleted }.count
                )

                // Settings Menu (Right Wing)
                HStack {
                    Spacer()
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
                    .menuIndicator(.hidden)
                    .frame(width: 24)
                }
            }
            .padding(.horizontal, TidoDesign.Spacing.md)
            .padding(.vertical, TidoDesign.Spacing.sm)

            Divider().opacity(0.5)

            // Task List Content
            let filteredTasks = store.filtered(allTasks)

            VStack(spacing: 0) {
                if filteredTasks.isEmpty {
                    VStack {
                        Spacer()
                        EmptyStateView(filter: store.activeFilter)
                            .transition(.opacity.combined(with: .scale(scale: 0.98)))
                        Spacer()
                    }
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: TidoDesign.Spacing.xxs, pinnedViews: [.sectionHeaders]) {
                            if store.selectedWorkspace == nil {
                                // Grouped View
                                let grouped = Dictionary(grouping: filteredTasks, by: { $0.workspace })
                                let keys = grouped.keys.sorted()

                                ForEach(keys, id: \.self) { wsName in
                                    Section {
                                        ForEach(grouped[wsName] ?? []) { task in
                                            TaskRowView(task: task, store: store)
                                        }
                                    } header: {
                                        HStack {
                                            Text(wsName.uppercased())
                                                .font(TidoDesign.Font.badge)
                                                .foregroundStyle(TidoDesign.Color.textSecondary)
                                                .padding(.horizontal, TidoDesign.Spacing.md)
                                                .padding(.vertical, 4)
                                            Spacer()
                                        }
                                        .background(Material.ultraThin.opacity(0.8))
                                    }
                                }
                            } else {
                                // Single List View
                                ForEach(filteredTasks) { task in
                                    TaskRowView(task: task, store: store)
                                }
                            }
                        }
                        .padding(.vertical, TidoDesign.Spacing.sm)
                    }
                    .transition(.opacity)
                }
            }
            .animation(TidoDesign.Animation.spring, value: store.activeFilter)
            .frame(maxWidth: .infinity, maxHeight: TidoDesign.Size.popoverMaxHeight)

            Divider().opacity(0.5)

            // Bottom Add Action
            VStack {
                if showingAddInput {
                    AddTaskField(
                        placeholder: "New task…",
                        onSubmit: { title in
                            store.addTask(title: title)
                        },
                        onCancel: {
                            withAnimation(TidoDesign.Animation.spring) {
                                showingAddInput = false
                            }
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else if showingSearchInput {
                    SearchTaskField(
                        text: $store.searchText,
                        onCancel: {
                            withAnimation(TidoDesign.Animation.spring) {
                                showingSearchInput = false
                            }
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    HStack {
                        Button {
                            withAnimation(TidoDesign.Animation.spring) {
                                showingAddInput = true
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.system(size: 11, weight: .semibold))
                                Text("New Task")
                                    .font(TidoDesign.Font.taskTitle.weight(.medium))
                                Text("⌘N")
                                    .font(TidoDesign.Font.caption)
                                    .foregroundStyle(TidoDesign.Color.textTertiary)
                                    .padding(.leading, 2)
                                Spacer()
                            }
                            .foregroundStyle(TidoDesign.Color.textSecondary)
                            .padding(.vertical, TidoDesign.Spacing.sm * 0.8)
                            .padding(.horizontal, TidoDesign.Spacing.sm)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .keyboardShortcut("n", modifiers: .command)

                        Button {
                            withAnimation(TidoDesign.Animation.spring) {
                                showingSearchInput = true
                            }
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(TidoDesign.Color.textSecondary)
                                .padding(.horizontal, TidoDesign.Spacing.sm)
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(TidoDesign.Spacing.sm)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Global tap to dismiss inputs and focus
            if showingAddInput || showingSearchInput {
                withAnimation(TidoDesign.Animation.spring) {
                    showingAddInput = false
                    showingSearchInput = false
                }
            }
            NSApp.keyWindow?.makeFirstResponder(nil)
        }
        // Alerts for Workspace Management
        .alert("Rename Workspace", isPresented: $showingRenameAlert) {
            TextField("Workspace Name", text: $workspaceNameInput)
            Button("Cancel", role: .cancel) { }
            Button("Rename") {
                store.renameWorkspace(from: workspaceToRename, to: workspaceNameInput)
            }
        }
        .alert("New Workspace", isPresented: $showingNewWorkspaceAlert) {
            TextField("Workspace Name", text: $workspaceNameInput)
            Button("Cancel", role: .cancel) { }
            Button("Create") {
                if !workspaceNameInput.trimmed.isEmpty {
                    store.selectedWorkspace = workspaceNameInput.trimmed
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            LaunchAtLoginService.shared.refreshState()
        }
        .onAppear {
            if let window = NSApplication.shared.windows.first(where: { $0.isKeyWindow || $0.isVisible }) {
                window.hidesOnDeactivate = false
                window.level = .popUpMenu
            }
        }
    }
}
