// TaskListView.swift
// noteOS — Views
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
                                
                                if ws != "Personal" {
                                    Divider()

                                    Button {
                                        store.moveWorkspaceUp(ws)
                                    } label: {
                                        Label("Move Up", systemImage: "arrow.up")
                                    }
                                    
                                    Button {
                                        store.moveWorkspaceDown(ws)
                                    } label: {
                                        Label("Move Down", systemImage: "arrow.down")
                                    }

                                    Divider()
                                    
                                    Button {
                                        withAnimation(NoteOSDesign.Animation.quick) {
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

                        // Limit to max 10 workspaces total to prevent the dropdown from overflowing the screen
                        if store.getAvailableWorkspaces(allTasks).count < 10 {
                            Button {
                                withAnimation(NoteOSDesign.Animation.quick) {
                                    workspaceNameInput = ""
                                    showingNewWorkspaceAlert = true
                                }
                            } label: {
                                Label("New Workspace...", systemImage: "plus.rectangle.on.folder")
                            }
                        }
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: store.selectedWorkspace == nil ? "folder" : "folder.fill")
                                .font(.system(size: 13, weight: .medium))
                            Text(store.selectedWorkspace ?? "All")
                                .font(.system(size: 9, weight: .semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .truncationMode(.tail)
                        }
                        .foregroundStyle(store.selectedWorkspace == nil ? NoteOSDesign.Color.textSecondary : NoteOSDesign.Color.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            (store.selectedWorkspace == nil ? Color.clear : NoteOSDesign.Color.accent.opacity(0.1))
                                .continuousRoundedCorners(NoteOSDesign.Radius.sm)
                        )
                        .frame(minWidth: 55, maxWidth: 80) // Flexible width to fit up to 10 characters cleanly
                    }
                    .buttonStyle(.plain)
                    .menuIndicator(.hidden)
                    .help("Switch Workspace")
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Filter Tabs (Center Section)
                    let pending = allTasks.filter { !$0.isCompleted }.count
                    FilterTabBar(
                        selection: $store.activeFilter,
                        pendingCount: pending,
                        doneCount: allTasks.count - pending
                    )
                    .layoutPriority(1)

                    // Settings Menu (Right Section)
                    Menu {
                        Button(LaunchAtLoginService.shared.isEnabled ? "Disable Launch at Login" : "Launch at Login") {
                            LaunchAtLoginService.shared.toggle()
                        }
                        Divider()
                        Button("Quit noteOS", role: .destructive) {
                            NSApplication.shared.terminate(nil)
                        }
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(NoteOSDesign.Color.textSecondary)
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal, NoteOSDesign.Spacing.md)
                .padding(.vertical, NoteOSDesign.Spacing.sm)

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
                            LazyVStack(spacing: NoteOSDesign.Spacing.xxs, pinnedViews: [.sectionHeaders]) {
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
                                                    .font(NoteOSDesign.Font.badge)
                                                    .foregroundStyle(NoteOSDesign.Color.textSecondary)
                                                    .padding(.horizontal, NoteOSDesign.Spacing.md)
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
                            .padding(.vertical, NoteOSDesign.Spacing.sm)
                        }
                        .transition(.opacity)
                    }
                }
                .animation(NoteOSDesign.Animation.spring, value: store.activeFilter)
                .frame(maxWidth: .infinity, maxHeight: NoteOSDesign.Size.popoverMaxHeight)

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
                                withAnimation(NoteOSDesign.Animation.spring) {
                                    showingAddInput = false
                                }
                            }
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else if showingSearchInput {
                        SearchTaskField(
                            text: $store.searchText,
                            onCancel: {
                                withAnimation(NoteOSDesign.Animation.spring) {
                                    showingSearchInput = false
                                }
                            }
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        HStack {
                            Button {
                                withAnimation(NoteOSDesign.Animation.spring) {
                                    showingAddInput = true
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 11, weight: .semibold))
                                    Text("New Task")
                                        .font(NoteOSDesign.Font.taskTitle.weight(.medium))
                                    Text("⌘N")
                                        .font(NoteOSDesign.Font.caption)
                                        .foregroundStyle(NoteOSDesign.Color.textTertiary)
                                        .padding(.leading, 2)
                                    Spacer()
                                }
                                .foregroundStyle(NoteOSDesign.Color.textSecondary)
                                .padding(.vertical, NoteOSDesign.Spacing.sm * 0.8)
                                .padding(.horizontal, NoteOSDesign.Spacing.sm)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .keyboardShortcut("n", modifiers: .command)

                            Button {
                                withAnimation(NoteOSDesign.Animation.spring) {
                                    showingSearchInput = true
                                }
                            } label: {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(NoteOSDesign.Color.textSecondary)
                                    .padding(.horizontal, NoteOSDesign.Spacing.sm)
                                    .padding(.vertical, 8)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(NoteOSDesign.Spacing.sm)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                // Global tap to dismiss inputs and focus
                if showingAddInput || showingSearchInput {
                    withAnimation(NoteOSDesign.Animation.spring) {
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
                
                VStack(spacing: NoteOSDesign.Spacing.md) {
                    Text(showingRenameAlert ? "Rename Workspace" : "New Workspace")
                        .font(NoteOSDesign.Font.taskTitle.weight(.semibold))
                        .foregroundStyle(NoteOSDesign.Color.textPrimary)
                    
                    TextField("Workspace Name", text: $workspaceNameInput)
                        .textFieldStyle(.plain)
                        .font(NoteOSDesign.Font.input)
                        .padding(8)
                        .background(NoteOSDesign.Color.rowHover.opacity(0.5).continuousRoundedCorners(NoteOSDesign.Radius.sm))
                        .overlay(RoundedRectangle(cornerRadius: NoteOSDesign.Radius.sm).strokeBorder(NoteOSDesign.Color.separator, lineWidth: 1))
                        .onSubmit { submitAlert() }
                    
                    HStack(spacing: NoteOSDesign.Spacing.md) {
                        Button("Cancel") {
                            closeAlerts()
                        }
                        .keyboardShortcut(.escape, modifiers: [])
                        .buttonStyle(.plain)
                        .foregroundStyle(NoteOSDesign.Color.textSecondary)
                        
                        Spacer()
                        
                        Button(showingRenameAlert ? "Rename" : "Create") {
                            submitAlert()
                        }
                        .keyboardShortcut(.defaultAction)
                        .buttonStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(NoteOSDesign.Color.accent.continuousRoundedCorners(NoteOSDesign.Radius.sm))
                        .foregroundStyle(.white)
                    }
                }
                .padding(NoteOSDesign.Spacing.lg)
                .background(Material.regular, in: RoundedRectangle(cornerRadius: NoteOSDesign.Radius.lg, style: .continuous))
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
        withAnimation(NoteOSDesign.Animation.quick) {
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
                store.createWorkspace(workspaceNameInput)
            }
        }
        closeAlerts()
    }
}
