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
        ZStack {
            VStack(spacing: 0) {
                // Header Toolbar
                HStack(spacing: 0) {
                    // Workspace Selector (Left Section)
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
                                    withAnimation(TidoDesign.Animation.quick) {
                                        workspaceToRename = ws
                                        workspaceNameInput = ws
                                        showingRenameAlert = true
                                    }
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

                        // Limit to max 5 workspaces total
                        if store.getAvailableWorkspaces(allTasks).count < 5 {
                            Button {
                                withAnimation(TidoDesign.Animation.quick) {
                                    workspaceNameInput = ""
                                    showingNewWorkspaceAlert = true
                                }
                            } label: {
                                Label("New Workspace...", systemImage: "plus.rectangle.on.folder")
                            }
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
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Filter Tabs (Center Section)
                    FilterTabBar(
                        selection: $store.activeFilter,
                        pendingCount: allTasks.filter { !$0.isCompleted }.count,
                        doneCount: allTasks.filter { $0.isCompleted }.count
                    )
                    .layoutPriority(1)

                    // Settings Menu (Right Section)
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
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal, TidoDesign.Spacing.md)
                .padding(.vertical, TidoDesign.Spacing.sm)

                Color.clear.frame(height: 1)

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

                Color.clear.frame(height: 1)

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

            // Custom Inline Alert Overlay
            if showingRenameAlert || showingNewWorkspaceAlert {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture { closeAlerts() }
                
                VStack(spacing: TidoDesign.Spacing.md) {
                    Text(showingRenameAlert ? "Rename Workspace" : "New Workspace")
                        .font(TidoDesign.Font.taskTitle.weight(.semibold))
                        .foregroundStyle(TidoDesign.Color.textPrimary)
                    
                    TextField("Workspace Name", text: $workspaceNameInput)
                        .textFieldStyle(.plain)
                        .font(TidoDesign.Font.input)
                        .padding(8)
                        .background(TidoDesign.Color.rowHover.opacity(0.5).continuousRoundedCorners(TidoDesign.Radius.sm))
                        .overlay(RoundedRectangle(cornerRadius: TidoDesign.Radius.sm).strokeBorder(TidoDesign.Color.separator, lineWidth: 1))
                        .onSubmit { submitAlert() }
                    
                    HStack(spacing: TidoDesign.Spacing.md) {
                        Button("Cancel") {
                            closeAlerts()
                        }
                        .keyboardShortcut(.escape, modifiers: [])
                        .buttonStyle(.plain)
                        .foregroundStyle(TidoDesign.Color.textSecondary)
                        
                        Spacer()
                        
                        Button(showingRenameAlert ? "Rename" : "Create") {
                            submitAlert()
                        }
                        .keyboardShortcut(.defaultAction)
                        .buttonStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(TidoDesign.Color.accent.continuousRoundedCorners(TidoDesign.Radius.sm))
                        .foregroundStyle(.white)
                    }
                }
                .padding(TidoDesign.Spacing.lg)
                .background(Material.regular, in: RoundedRectangle(cornerRadius: TidoDesign.Radius.lg, style: .continuous))
                .shadow(color: Color.black.opacity(0.15), radius: 10, y: 4)
                .frame(width: 260)
                .transition(.scale(scale: 0.95).combined(with: .opacity))
                .zIndex(100)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            LaunchAtLoginService.shared.refreshState()
        }
        .onChange(of: workspaceNameInput) { _, newValue in
            if newValue.count > 10 {
                workspaceNameInput = String(newValue.prefix(10))
            }
        }
        .onAppear {
            if let window = NSApplication.shared.windows.first(where: { $0.isKeyWindow || $0.isVisible }) {
                window.hidesOnDeactivate = false
                window.level = .popUpMenu
            }
        }
    }

    // MARK: - Custom Alert Helpers

    private func closeAlerts() {
        withAnimation(TidoDesign.Animation.quick) {
            showingRenameAlert = false
            showingNewWorkspaceAlert = false
        }
        NSApp.keyWindow?.makeFirstResponder(nil)
    }

    private func submitAlert() {
        if showingRenameAlert {
            store.renameWorkspace(from: workspaceToRename, to: workspaceNameInput)
        } else if showingNewWorkspaceAlert {
            if !workspaceNameInput.trimmed.isEmpty {
                store.selectedWorkspace = workspaceNameInput.trimmed
            }
        }
        closeAlerts()
    }
}
