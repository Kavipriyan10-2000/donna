import SwiftUI

struct DashboardView: View {
    @StateObject private var dashboardManager = DashboardManager.shared
    @StateObject private var processManager = ProcessManager.shared
    @State private var showingAddWidget = false
    @State private var showingLayoutPicker = false
    @State private var showingConfigPicker = false
    @State private var draggedWidget: DashboardWidget?
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            DashboardToolbar(
                isEditing: $dashboardManager.isEditing,
                onAddWidget: { showingAddWidget = true },
                onChangeLayout: { showingLayoutPicker = true },
                onSwitchConfig: { showingConfigPicker = true }
            )
            
            Divider()
            
            // Dashboard Content
            if let config = dashboardManager.activeConfiguration {
                ScrollView {
                    DashboardGrid(
                        configuration: config,
                        isEditing: dashboardManager.isEditing,
                        onMove: { widget, newPosition in
                            dashboardManager.updateWidgetPosition(
                                configurationId: config.id,
                                widgetId: widget.id,
                                position: newPosition
                            )
                        },
                        onDelete: { widget in
                            dashboardManager.removeWidget(
                                from: config.id,
                                widgetId: widget.id
                            )
                        }
                    )
                    .padding()
                }
            } else {
                EmptyDashboardView()
            }
        }
        .sheet(isPresented: $showingAddWidget) {
            AddWidgetView(configurationId: dashboardManager.activeConfiguration?.id)
        }
        .sheet(isPresented: $showingLayoutPicker) {
            LayoutPickerView(
                currentLayout: dashboardManager.activeConfiguration?.layout ?? .grid2x2
            )
        }
        .sheet(isPresented: $showingConfigPicker) {
            ConfigurationPickerView()
        }
    }
}

// MARK: - Dashboard Toolbar

struct DashboardToolbar: View {
    @Binding var isEditing: Bool
    let onAddWidget: () -> Void
    let onChangeLayout: () -> Void
    let onSwitchConfig: () -> Void
    
    var body: some View {
        HStack {
            Text("Dashboard")
                .font(.headline)
            
            Spacer()
            
            Button {
                onSwitchConfig()
            } label: {
                Label("Switch", systemImage: "rectangle.stack")
            }
            
            Button {
                onChangeLayout()
            } label: {
                Label("Layout", systemImage: "grid")
            }
            
            Button {
                onAddWidget()
            } label: {
                Label("Add Widget", systemImage: "plus")
            }
            
            Toggle("Edit", isOn: $isEditing)
                .toggleStyle(.button)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .frame(height: 44)
    }
}

// MARK: - Dashboard Grid

struct DashboardGrid: View {
    let configuration: DashboardConfiguration
    let isEditing: Bool
    let onMove: (DashboardWidget, WidgetPosition) -> Void
    let onDelete: (DashboardWidget) -> Void
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(configuration.widgets) { widget in
                WidgetContainer(
                    widget: widget,
                    isEditing: isEditing,
                    onDelete: { onDelete(widget) }
                )
                .frame(height: 200)
            }
        }
    }
}

// MARK: - Widget Container

struct WidgetContainer: View {
    let widget: DashboardWidget
    let isEditing: Bool
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Widget Header
            HStack {
                Text(widget.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                if isEditing {
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Widget Content
            WidgetContent(widget: widget)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Widget Content

struct WidgetContent: View {
    let widget: DashboardWidget
    @StateObject private var processManager = ProcessManager.shared
    @StateObject private var a2aHub = A2AHub.shared
    @State private var widgetData: [String: Any] = [:]
    @State private var isLoading = false
    
    var body: some View {
        Group {
            switch widget.type {
            case .status:
                StatusWidgetContent(
                    data: widgetData,
                    toolId: widget.dataSource.toolId
                )
            case .counter:
                CounterWidgetContent(data: widgetData)
            case .chart:
                ChartWidgetContent(data: widgetData)
            case .list:
                ListWidgetContent(data: widgetData)
            }
        }
        .padding()
        .onAppear {
            loadData()
        }
        .onChange(of: widget.dataSource.toolId) { _ in
            loadData()
        }
    }
    
    private func loadData() {
        isLoading = true
        
        // Load data based on source type
        switch widget.dataSource.type {
        case .tool:
            if let toolId = widget.dataSource.toolId {
                let status = processManager.runningProcesses[toolId]?.status
                widgetData = [
                    "status": status?.rawValue ?? "stopped",
                    "port": processManager.runningProcesses[toolId]?.port ?? 0,
                    "pid": processManager.runningProcesses[toolId]?.pid ?? 0
                ]
            }
        case .agent:
            if let agentId = widget.dataSource.agentId {
                let agent = a2aHub.registeredAgents.first { $0.id == agentId }
                widgetData = [
                    "online": agent?.isOnline ?? false,
                    "activeTasks": agent?.activeTasks ?? 0
                ]
            }
        default:
            break
        }
        
        isLoading = false
    }
}

// MARK: - Status Widget

struct StatusWidgetContent: View {
    let data: [String: Any]
    let toolId: String?
    @StateObject private var processManager = ProcessManager.shared
    
    var body: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(statusColor)
                .frame(width: 24, height: 24)
            
            Text(statusText)
                .font(.headline)
            
            if let port = data["port"] as? Int, port > 0 {
                Text("Port: \(port)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var statusColor: Color {
        guard let statusString = data["status"] as? String,
              let status = ProcessStatus(rawValue: statusString) else {
            return .gray
        }
        
        switch status {
        case .running: return .green
        case .starting: return .yellow
        case .stopped: return .gray
        case .error, .crashed: return .red
        }
    }
    
    private var statusText: String {
        guard let statusString = data["status"] as? String,
              let status = ProcessStatus(rawValue: statusString) else {
            return "Unknown"
        }
        return status.displayName
    }
}

// MARK: - Counter Widget

struct CounterWidgetContent: View {
    let data: [String: Any]
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(count)")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.accentColor)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var count: Int {
        data["count"] as? Int ?? data["activeTasks"] as? Int ?? 0
    }
    
    private var label: String {
        data["label"] as? String ?? "Items"
    }
}

// MARK: - Chart Widget

struct ChartWidgetContent: View {
    let data: [String: Any]
    
    var body: some View {
        VStack {
            // Simple bar chart representation
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(0..<7) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.accentColor)
                        .frame(width: 20, height: CGFloat.random(in: 20...80))
                }
            }
            .frame(height: 100)
            
            Text("Activity Chart")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - List Widget

struct ListWidgetContent: View {
    let data: [String: Any]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(0..<min(items.count, 5), id: \.self) { index in
                HStack {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 6, height: 6)
                    Text(items[index])
                        .font(.caption)
                        .lineLimit(1)
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    private var items: [String] {
        data["items"] as? [String] ?? ["Item 1", "Item 2", "Item 3"]
    }
}

// MARK: - Empty Dashboard View

struct EmptyDashboardView: View {
    @StateObject private var dashboardManager = DashboardManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No Dashboard Selected")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create a dashboard to get started")
                .font(.body)
                .foregroundColor(.secondary)
            
            Button {
                _ = dashboardManager.createConfiguration(name: "New Dashboard")
            } label: {
                Label("Create Dashboard", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Add Widget View

struct AddWidgetView: View {
    let configurationId: String?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var toolManager = ToolManager.shared
    @StateObject private var a2aHub = A2AHub.shared
    @State private var selectedType: WidgetType = .status
    @State private var selectedSource: WidgetSource = .tool
    @State private var selectedToolId: String?
    @State private var selectedAgentId: String?
    @State private var widgetTitle = ""
    
    enum WidgetSource {
        case tool
        case agent
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Widget Type") {
                    Picker("Type", selection: $selectedType) {
                        Text("Status").tag(WidgetType.status)
                        Text("Counter").tag(WidgetType.counter)
                        Text("Chart").tag(WidgetType.chart)
                        Text("List").tag(WidgetType.list)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Data Source") {
                    Picker("Source", selection: $selectedSource) {
                        Text("Tool").tag(WidgetSource.tool)
                        Text("Agent").tag(WidgetSource.agent)
                    }
                    .pickerStyle(.segmented)
                    
                    if selectedSource == .tool {
                        Picker("Tool", selection: $selectedToolId) {
                            Text("Select a tool").tag(nil as String?)
                            ForEach(toolManager.tools) { tool in
                                Text(tool.displayName).tag(tool.id as String?)
                            }
                        }
                    } else {
                        Picker("Agent", selection: $selectedAgentId) {
                            Text("Select an agent").tag(nil as String?)
                            ForEach(a2aHub.registeredAgents) { agent in
                                Text(agent.card.name).tag(agent.id as String?)
                            }
                        }
                    }
                }
                
                Section("Title") {
                    TextField("Widget Title", text: $widgetTitle)
                }
            }
            .navigationTitle("Add Widget")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addWidget()
                    }
                    .disabled(!canAdd)
                }
            }
        }
        .frame(width: 400, height: 400)
    }
    
    private var canAdd: Bool {
        !widgetTitle.isEmpty &&
        (selectedToolId != nil || selectedAgentId != nil) &&
        configurationId != nil
    }
    
    private func addWidget() {
        guard let configId = configurationId else { return }
        
        let dataSource: WidgetDataSource
        if selectedSource == .tool, let toolId = selectedToolId {
            dataSource = WidgetDataSource(
                type: .tool,
                agentId: nil,
                toolId: toolId,
                endpoint: nil,
                method: nil,
                parameters: nil
            )
        } else if let agentId = selectedAgentId {
            dataSource = WidgetDataSource(
                type: .agent,
                agentId: agentId,
                toolId: nil,
                endpoint: nil,
                method: nil,
                parameters: nil
            )
        } else {
            return
        }
        
        DashboardManager.shared.addWidget(
            to: configId,
            type: selectedType,
            title: widgetTitle,
            dataSource: dataSource
        )
        
        dismiss()
    }
}

// MARK: - Layout Picker View

struct LayoutPickerView: View {
    let currentLayout: DashboardLayoutType
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dashboardManager = DashboardManager.shared
    
    var body: some View {
        NavigationView {
            List(DashboardLayoutType.allCases, id: \.self) { layout in
                Button {
                    if let configId = dashboardManager.activeConfigurationId {
                        dashboardManager.changeLayout(configurationId: configId, to: layout)
                    }
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: layoutIcon(for: layout))
                        Text(layout.displayName)
                        
                        Spacer()
                        
                        if layout == currentLayout {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Choose Layout")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 300, height: 400)
    }
    
    private func layoutIcon(for layout: DashboardLayoutType) -> String {
        switch layout {
        case .grid2x2: return "square.grid.2x2"
        case .grid3x2: return "square.grid.3x2"
        case .grid3x3: return "square.grid.3x3"
        case .singleColumn: return "rectangle"
        case .twoColumn: return "rectangle.split.2x1"
        case .threeColumn: return "rectangle.split.3x1"
        case .freeform: return "arrow.up.left.and.arrow.down.right"
        }
    }
}

// MARK: - Configuration Picker View

struct ConfigurationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dashboardManager = DashboardManager.shared
    @State private var newConfigName = ""
    
    var body: some View {
        NavigationView {
            List {
                Section("Dashboards") {
                    ForEach(dashboardManager.configurations) { config in
                        Button {
                            dashboardManager.setActiveConfiguration(id: config.id)
                            dismiss()
                        } label: {
                            HStack {
                                Text(config.name)
                                
                                Spacer()
                                
                                if config.id == dashboardManager.activeConfigurationId {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: deleteConfigurations)
                }
                
                Section("Create New") {
                    HStack {
                        TextField("Dashboard Name", text: $newConfigName)
                        
                        Button {
                            createConfiguration()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(newConfigName.isEmpty)
                    }
                }
            }
            .navigationTitle("Dashboards")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 350, height: 500)
    }
    
    private func deleteConfigurations(at offsets: IndexSet) {
        for index in offsets {
            let config = dashboardManager.configurations[index]
            dashboardManager.deleteConfiguration(id: config.id)
        }
    }
    
    private func createConfiguration() {
        guard !newConfigName.isEmpty else { return }
        
        let config = dashboardManager.createConfiguration(name: newConfigName)
        dashboardManager.setActiveConfiguration(id: config.id)
        newConfigName = ""
        dismiss()
    }
}
