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
    @AppStorage("isPinned") private var isPinned: Bool = false

    // MARK: - Init

    init(context: ModelContext) {
        _store = StateObject(wrappedValue: TaskStore(context: context))
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header Toolbar — fully symmetric: left/right slots balance the centered tabs
                HStack(spacing: 0) {
                    let headerSideSlotWidth: CGFloat = 72

                    // LEFT SLOT — Workspace Selector
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
                            (store.selectedWorkspace == nil ? Color.clear : NoteOSDesign.Color.accent.opacity(0.10))
                                .continuousRoundedCorners(NoteOSDesign.Radius.sm)
                        )
                    }
                    .buttonStyle(.plain)
                    .menuIndicator(.hidden)
                    .help("Switch Workspace")
                    .frame(width: headerSideSlotWidth, alignment: .leading)

                    // CENTER — Filter Tabs
                    let pending = allTasks.filter { !$0.isCompleted }.count
                    FilterTabBar(
                        selection: $store.activeFilter,
                        pendingCount: pending,
                        doneCount: allTasks.count - pending
                    )
                    .frame(maxWidth: .infinity, alignment: .center)

                    // RIGHT SLOT — Settings Menu (same fixed width as left slot)
                    Menu {
                        Button {
                            isPinned.toggle()
                        } label: {
                            HStack {
                                Text("Keep Window Open")
                                if isPinned {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }

                        Button(LaunchAtLoginService.shared.isEnabled ? "Disable Launch at Login" : "Launch at Login") {
                            LaunchAtLoginService.shared.toggle()
                        }
                        Divider()
                        Button("Quit noteOS", role: .destructive) {
                            NSApplication.shared.terminate(nil)
                        }
                    } label: {
                        // Mirror the workspace button dimensions
                        Image(systemName: "gearshape")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(NoteOSDesign.Color.textSecondary)
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                    .frame(width: headerSideSlotWidth, alignment: .trailing)
                }
                .padding(.horizontal, NoteOSDesign.Spacing.sm)
                .padding(.vertical, NoteOSDesign.Spacing.sm)

                // Content Separator with subtle gradient
                LinearGradient(
                    colors: [.primary.opacity(0.0), .primary.opacity(0.05), .primary.opacity(0.0)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 1)

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

                // Bottom action bar
                ZStack {
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
                        HStack(spacing: 0) {
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
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.primary.opacity(0.03))
                                .continuousRoundedCorners(NoteOSDesign.Radius.md)
                            }
                            .buttonStyle(.plain)
                            .keyboardShortcut("n", modifiers: .command)

                            Spacer(minLength: 12)

                            Button {
                                withAnimation(NoteOSDesign.Animation.spring) {
                                    showingSearchInput = true
                                }
                            } label: {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(NoteOSDesign.Color.textSecondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.primary.opacity(0.03))
                                    .continuousRoundedCorners(NoteOSDesign.Radius.md)
                            }
                            .buttonStyle(.plain)
                        }
                        .transition(.opacity)
                    }
                }
                .padding(.horizontal, NoteOSDesign.Spacing.md)
                .padding(.top, NoteOSDesign.Spacing.xs)
                .padding(.bottom, NoteOSDesign.Spacing.sm + 2)
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

            // Premium Floating Glass Alert Overlay
            if showingRenameAlert || showingNewWorkspaceAlert {
                // Scrim
                Color.black.opacity(0.35)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture { closeAlerts() }
                    .transition(.opacity)

                // Glass card
                VStack(spacing: NoteOSDesign.Spacing.md) {
                    // Title
                    HStack {
                        Text(showingRenameAlert ? "Rename Workspace" : "New Workspace")
                            .font(NoteOSDesign.Font.taskTitle.weight(.semibold))
                            .foregroundStyle(NoteOSDesign.Color.textPrimary)
                        Spacer()
                    }

                    // Input field with premium ring
                    TextField("Name (max 10 chars)", text: $workspaceNameInput)
                        .textFieldStyle(.plain)
                        .font(NoteOSDesign.Font.input)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: NoteOSDesign.Radius.sm, style: .continuous)
                                .fill(Color.primary.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: NoteOSDesign.Radius.sm, style: .continuous)
                                .strokeBorder(NoteOSDesign.Color.accent.opacity(0.45), lineWidth: 1)
                        )
                        .onSubmit { submitAlert() }

                    // Actions
                    HStack(spacing: NoteOSDesign.Spacing.sm) {
                        Button("Cancel") {
                            closeAlerts()
                        }
                        .keyboardShortcut(.escape, modifiers: [])
                        .buttonStyle(.plain)
                        .font(NoteOSDesign.Font.header)
                        .foregroundStyle(NoteOSDesign.Color.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: NoteOSDesign.Radius.sm, style: .continuous)
                                .fill(Color.primary.opacity(0.06))
                        )

                        Spacer()

                        Button(showingRenameAlert ? "Rename" : "Create") {
                            submitAlert()
                        }
                        .keyboardShortcut(.defaultAction)
                        .buttonStyle(.plain)
                        .font(NoteOSDesign.Font.header.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: NoteOSDesign.Radius.sm, style: .continuous)
                                .fill(NoteOSDesign.Color.accent)
                        )
                        .foregroundStyle(.white)
                    }
                }
                .padding(NoteOSDesign.Spacing.lg)
                .background(Material.ultraThinMaterial, in: RoundedRectangle(cornerRadius: NoteOSDesign.Radius.lg + 2, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: NoteOSDesign.Radius.lg + 2, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.18), .white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.8
                        )
                )
                .shadow(color: Color.black.opacity(0.22), radius: 24, x: 0, y: 8)
                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 1)
                .frame(width: 272)
                .transition(.scale(scale: 0.96).combined(with: .opacity))
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
        .onChange(of: isPinned) { _, newValue in
            updateWindowBehavior(pinned: newValue)
        }
        .onAppear {
            updateWindowBehavior(pinned: isPinned)
        }
    }

    private func updateWindowBehavior(pinned: Bool) {
        if let window = NSApplication.shared.windows.first(where: { $0.isKeyWindow || $0.isVisible }) {
            window.hidesOnDeactivate = !pinned
            window.level = pinned ? .floating : .popUpMenu
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
