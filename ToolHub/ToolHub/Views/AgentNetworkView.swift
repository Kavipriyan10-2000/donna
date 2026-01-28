import SwiftUI

struct AgentNetworkView: View {
    @StateObject private var a2aHub = A2AHub.shared
    @State private var showingSendTask = false
    @State private var selectedAgent: Agent?
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            AgentNetworkToolbar(
                isDiscoveryRunning: a2aHub.isDiscoveryRunning,
                onStartDiscovery: { a2aHub.startDiscovery() },
                onStopDiscovery: { a2aHub.stopDiscovery() },
                onBroadcast: { showingSendTask = true }
            )
            
            Divider()
            
            // Network Visualization
            HStack {
                // Agent List
                AgentListView(
                    agents: a2aHub.registeredAgents,
                    onSelect: { agent in
                        selectedAgent = agent
                    }
                )
                .frame(width: 250)
                
                Divider()
                
                // Network Graph
                AgentNetworkGraph(
                    agents: a2aHub.registeredAgents,
                    selectedAgent: $selectedAgent
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Divider()
                
                // Task History
                TaskHistoryView(tasks: a2aHub.activeTasks)
                    .frame(width: 300)
            }
        }
        .sheet(isPresented: $showingSendTask) {
            SendTaskView()
        }
    }
}

// MARK: - Agent Network Toolbar

struct AgentNetworkToolbar: View {
    let isDiscoveryRunning: Bool
    let onStartDiscovery: () -> Void
    let onStopDiscovery: () -> Void
    let onBroadcast: () -> Void
    
    var body: some View {
        HStack {
            Text("Agent Network")
                .font(.headline)
            
            Spacer()
            
            if isDiscoveryRunning {
                Button {
                    onStopDiscovery()
                } label: {
                    Label("Stop Discovery", systemImage: "stop.fill")
                }
                .buttonStyle(.bordered)
            } else {
                Button {
                    onStartDiscovery()
                } label: {
                    Label("Start Discovery", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.bordered)
            }
            
            Button {
                onBroadcast()
            } label: {
                Label("Broadcast Task", systemImage: "antenna.radiowaves.left.and.right")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .frame(height: 44)
    }
}

// MARK: - Agent List View

struct AgentListView: View {
    let agents: [Agent]
    let onSelect: (Agent) -> Void
    
    var body: some View {
        List(agents) { agent in
            AgentRow(agent: agent)
                .contentShape(Rectangle())
                .onTapGesture {
                    onSelect(agent)
                }
        }
        .listStyle(.plain)
    }
}

// MARK: - Agent Row

struct AgentRow: View {
    let agent: Agent
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(agent.isOnline ? Color.green : Color.red)
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(agent.card.name)
                    .font(.headline)
                
                Text(agent.card.version)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if agent.activeTasks > 0 {
                    Text("\(agent.activeTasks) active tasks")
                        .font(.caption2)
                        .foregroundColor(.accentColor)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Agent Network Graph

struct AgentNetworkGraph: View {
    let agents: [Agent]
    @Binding var selectedAgent: Agent?
    
    var body: some View {
        ZStack {
            // Background
            Color(NSColor.controlBackgroundColor)
            
            if agents.isEmpty {
                Text("No agents discovered")
                    .foregroundColor(.secondary)
            } else {
                // Draw connections
                ForEach(0..<agents.count, id: \.self) { i in
                    ForEach((i+1)..<agents.count, id: \.self) { j in
                        ConnectionLine(
                            from: position(for: i, total: agents.count),
                            to: position(for: j, total: agents.count)
                        )
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    }
                }
                
                // Draw agents
                ForEach(Array(agents.enumerated()), id: \.element.id) { index, agent in
                    AgentNode(
                        agent: agent,
                        isSelected: selectedAgent?.id == agent.id,
                        position: position(for: index, total: agents.count)
                    )
                    .onTapGesture {
                        selectedAgent = agent
                    }
                }
            }
        }
    }
    
    private func position(for index: Int, total: Int) -> CGPoint {
        let center = CGPoint(x: 200, y: 200)
        let radius: CGFloat = 150
        let angle = (2 * .pi * CGFloat(index)) / CGFloat(total) - .pi / 2
        
        return CGPoint(
            x: center.x + radius * cos(angle),
            y: center.y + radius * sin(angle)
        )
    }
}

// MARK: - Connection Line

struct ConnectionLine: Shape {
    let from: CGPoint
    let to: CGPoint
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: from)
        path.addLine(to: to)
        return path
    }
}

// MARK: - Agent Node

struct AgentNode: View {
    let agent: Agent
    let isSelected: Bool
    let position: CGPoint
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(agent.isOnline ? Color.accentColor : Color.gray)
                    .frame(width: isSelected ? 60 : 50, height: isSelected ? 60 : 50)
                
                Image(systemName: "cpu")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            Text(agent.card.name)
                .font(.caption)
                .lineLimit(1)
                .frame(width: 80)
        }
        .position(position)
        .shadow(radius: isSelected ? 8 : 4)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Task History View

struct TaskHistoryView: View {
    let tasks: [AgentTask]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Task History")
                .font(.headline)
                .padding()
            
            Divider()
            
            List(tasks.sorted(by: { $0.createdAt > $1.createdAt })) { task in
                TaskRow(task: task)
            }
            .listStyle(.plain)
        }
    }
}

// MARK: - Task Row

struct TaskRow: View {
    let task: AgentTask
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                StatusBadge(status: task.status)
                
                Spacer()
                
                Text(task.createdAt, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(task.type)
                .font(.caption)
                .fontWeight(.medium)
            
            HStack {
                Text("From: \(task.fromAgent)")
                Text("→")
                Text("To: \(task.toAgent)")
            }
            .font(.caption2)
            .foregroundColor(.secondary)
            
            if let result = task.result {
                HStack {
                    Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(result.success ? .green : .red)
                    
                    if let error = result.error {
                        Text(error.message)
                            .font(.caption2)
                            .foregroundColor(.red)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: TaskStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(4)
    }
    
    private var backgroundColor: Color {
        switch status {
        case .pending: return .yellow.opacity(0.2)
        case .inProgress: return .blue.opacity(0.2)
        case .completed: return .green.opacity(0.2)
        case .failed: return .red.opacity(0.2)
        case .cancelled: return .gray.opacity(0.2)
        }
    }
    
    private var foregroundColor: Color {
        switch status {
        case .pending: return .yellow
        case .inProgress: return .blue
        case .completed: return .green
        case .failed: return .red
        case .cancelled: return .gray
        }
    }
}

// MARK: - Send Task View

struct SendTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var a2aHub = A2AHub.shared
    @State private var fromAgent = "toolhub"
    @State private var toAgent = ""
    @State private var taskType = ""
    @State private var payload = ""
    @State private var isSending = false
    @State private var resultMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("From Agent", text: $fromAgent)
                    
                    Picker("To Agent", selection: $toAgent) {
                        Text("Select agent").tag("")
                        ForEach(a2aHub.registeredAgents.filter(\.isOnline)) { agent in
                            Text(agent.card.name).tag(agent.id)
                        }
                    }
                    
                    TextField("Task Type", text: $taskType)
                }
                
                Section("Payload (JSON)") {
                    TextEditor(text: $payload)
                        .frame(height: 100)
                        .font(.system(.body, design: .monospaced))
                }
                
                if let message = resultMessage {
                    Section("Result") {
                        Text(message)
                            .foregroundColor(message.contains("success") ? .green : .red)
                    }
                }
            }
            .navigationTitle("Send Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        sendTask()
                    } label: {
                        if isSending {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text("Send")
                        }
                    }
                    .disabled(!canSend || isSending)
                }
            }
        }
        .frame(width: 500, height: 500)
    }
    
    private var canSend: Bool {
        !fromAgent.isEmpty && !toAgent.isEmpty && !taskType.isEmpty
    }
    
    private func sendTask() {
        isSending = true
        resultMessage = nil
        
        Task {
            do {
                let payloadData: [String: AnyCodable]
                if !payload.isEmpty,
                   let data = payload.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    payloadData = json.mapValues { AnyCodable($0) }
                } else {
                    payloadData = [:]
                }
                
                let taskPayload = TaskPayload(
                    action: taskType,
                    data: payloadData,
                    context: nil
                )
                
                let task = try await a2aHub.sendTask(
                    from: fromAgent,
                    to: toAgent,
                    type: taskType,
                    payload: taskPayload
                )
                
                await MainActor.run {
                    isSending = false
                    if task.status == .completed {
                        resultMessage = "Task completed successfully!"
                    } else if task.status == .failed {
                        resultMessage = "Task failed: \(task.result?.error?.message ?? "Unknown error")"
                    } else {
                        resultMessage = "Task \(task.status.displayName)"
                    }
                }
            } catch {
                await MainActor.run {
                    isSending = false
                    resultMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}
