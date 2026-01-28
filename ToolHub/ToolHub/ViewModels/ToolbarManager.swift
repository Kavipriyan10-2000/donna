import Foundation
import Combine
import WebKit

@MainActor
class ToolbarManager: ObservableObject {
    static let shared = ToolbarManager()
    
    // MARK: - Published State
    @Published var currentToolbarItems: [ToolbarItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private State
    private var webView: WKWebView?
    private var toolId: String?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Toolbar Configuration
    
    func loadToolbar(for tool: Tool, webView: WKWebView) {
        self.webView = webView
        self.toolId = tool.id
        
        // Load toolbar configuration from manifest
        if let toolbarConfig = tool.manifest.ui.toolbar {
            currentToolbarItems = toolbarConfig.map { config in
                ToolbarItem(
                    id: UUID().uuidString,
                    type: config.type,
                    label: config.label,
                    icon: config.icon,
                    action: config.action,
                    options: config.options,
                    shortcut: parseShortcut(config.shortcut),
                    isEnabled: true
                )
            }
        } else {
            // Default toolbar items
            currentToolbarItems = createDefaultToolbarItems(for: tool)
        }
        
        // Setup JavaScript bridge
        setupJavaScriptBridge(webView: webView)
    }
    
    func clearToolbar() {
        currentToolbarItems = []
        webView = nil
        toolId = nil
    }
    
    // MARK: - Toolbar Actions
    
    func executeAction(_ item: ToolbarItem) {
        guard let webView = webView else {
            errorMessage = "No webview available"
            return
        }
        
        let script = """
        (function() {
            if (window.toolHub && window.toolHub.receiveAction) {
                window.toolHub.receiveAction('\(item.action)', {});
                return true;
            } else {
                // Try to dispatch custom event
                var event = new CustomEvent('toolhub:action', {
                    detail: { action: '\(item.action)' }
                });
                document.dispatchEvent(event);
                return true;
            }
        })();
        """
        
        webView.evaluateJavaScript(script) { [weak self] result, error in
            if let error = error {
                self?.errorMessage = "Failed to execute action: \(error.localizedDescription)"
            }
        }
    }
    
    func executeAction(_ item: ToolbarItem, with value: String) {
        guard let webView = webView else {
            errorMessage = "No webview available"
            return
        }
        
        let script = """
        (function() {
            if (window.toolHub && window.toolHub.receiveAction) {
                window.toolHub.receiveAction('\(item.action)', { value: '\(value)' });
                return true;
            }
        })();
        """
        
        webView.evaluateJavaScript(script) { [weak self] result, error in
            if let error = error {
                self?.errorMessage = "Failed to execute action: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - JavaScript Bridge
    
    private func setupJavaScriptBridge(webView: WKWebView) {
        let script = """
        (function() {
            window.toolHub = window.toolHub || {};
            window.toolHub.sendMessage = function(type, data) {
                window.webkit.messageHandlers.toolbar.postMessage({
                    type: type,
                    data: data
                });
            };
        })();
        """
        
        let userScript = WKUserScript(
            source: script,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        
        webView.configuration.userContentController.addUserScript(userScript)
    }
    
    // MARK: - Private Methods
    
    private func createDefaultToolbarItems(for tool: Tool) -> [ToolbarItem] {
        return [
            ToolbarItem(
                id: "refresh",
                type: .button,
                label: "Refresh",
                icon: "arrow.clockwise",
                action: "refresh",
                options: nil,
                shortcut: .init(key: "r", modifiers: .command),
                isEnabled: true
            ),
            ToolbarItem(
                id: "home",
                type: .button,
                label: "Home",
                icon: "house",
                action: "navigateHome",
                options: nil,
                shortcut: .init(key: "h", modifiers: .command),
                isEnabled: true
            )
        ]
    }
    
    private func parseShortcut(_ shortcut: String?) -> KeyboardShortcut? {
        guard let shortcut = shortcut else { return nil }
        
        let components = shortcut.split(separator: "+")
        guard let key = components.last else { return nil }
        
        var modifiers: EventModifiers = []
        for component in components.dropLast() {
            switch component.lowercased() {
            case "cmd", "command":
                modifiers.insert(.command)
            case "ctrl", "control":
                modifiers.insert(.control)
            case "opt", "option", "alt":
                modifiers.insert(.option)
            case "shift":
                modifiers.insert(.shift)
            default:
                break
            }
        }
        
        return KeyboardShortcut(KeyEquivalent(Character(String(key))), modifiers: modifiers)
    }
}

// MARK: - Toolbar Item Model

struct ToolbarItem: Identifiable, Equatable {
    let id: String
    let type: ToolbarItemType
    let label: String
    let icon: String?
    let action: String
    let options: [String]?
    let shortcut: KeyboardShortcut?
    var isEnabled: Bool
    
    static func == (lhs: ToolbarItem, rhs: ToolbarItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Toolbar View

struct AdaptiveToolbar: View {
    @StateObject private var toolbarManager = ToolbarManager.shared
    @State private var searchText = ""
    @State private var selectedDropdownValues: [String: String] = [:]
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(toolbarManager.currentToolbarItems) { item in
                toolbarItemView(for: item)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .frame(height: 44)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    @ViewBuilder
    private func toolbarItemView(for item: ToolbarItem) -> some View {
        switch item.type {
        case .button:
            Button {
                toolbarManager.executeAction(item)
            } label: {
                HStack(spacing: 4) {
                    if let icon = item.icon {
                        Image(systemName: icon)
                    }
                    Text(item.label)
                }
            }
            .buttonStyle(.bordered)
            .disabled(!item.isEnabled)
            .keyboardShortcut(item.shortcut?.key, modifiers: item.shortcut?.modifiers ?? [])
            
        case .dropdown:
            Menu {
                ForEach(item.options ?? [], id: \.self) { option in
                    Button {
                        selectedDropdownValues[item.id] = option
                        toolbarManager.executeAction(item, with: option)
                    } label: {
                        HStack {
                            Text(option)
                            if selectedDropdownValues[item.id] == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    if let icon = item.icon {
                        Image(systemName: icon)
                    }
                    Text(item.label)
                    Image(systemName: "chevron.down")
                }
            }
            .menuStyle(.borderedButton)
            .disabled(!item.isEnabled)
            
        case .search:
            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField(item.label, text: $searchText)
                    .textFieldStyle(.plain)
                    .frame(width: 150)
                if !searchText.isEmpty {
                    Button {
                        toolbarManager.executeAction(item, with: searchText)
                    } label: {
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(6)
            .disabled(!item.isEnabled)
            
        case .toggle:
            Toggle(item.label, isOn: .constant(false))
                .toggleStyle(.button)
                .disabled(!item.isEnabled)
            
        case .separator:
            Divider()
                .frame(height: 20)
        }
    }
}

// MARK: - Keyboard Shortcut Extension

extension KeyboardShortcut {
    var key: KeyEquivalent? {
        // This is a workaround since KeyboardShortcut doesn't expose its key directly
        // In a real implementation, you'd store this separately
        return nil
    }
    
    var modifiers: EventModifiers {
        // Same workaround as above
        return []
    }
}
