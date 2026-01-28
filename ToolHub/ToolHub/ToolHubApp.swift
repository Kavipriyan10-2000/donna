import SwiftUI

@main
struct ToolHubApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.titleBar)
        .commands {
            CommandMenu("Tools") {
                Button("Start Selected Tool") {
                    Task {
                        if let tool = ToolManager.shared.selectedTool {
                            await ToolManager.shared.startTool(tool)
                        }
                    }
                }
                .keyboardShortcut("r", modifiers: .command)
                
                Button("Stop Selected Tool") {
                    Task {
                        if let tool = ToolManager.shared.selectedTool {
                            await ToolManager.shared.stopTool(tool)
                        }
                    }
                }
                .keyboardShortcut(".", modifiers: .command)
                
                Divider()
                
                Button("Add Tool...") {
                    // Show catalog
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
            
            CommandGroup(after: .windowArrangement) {
                Divider()
                
                Button("Toggle Sidebar") {
                    // Toggle sidebar
                }
                .keyboardShortcut("s", modifiers: [.command, .control])
            }
        }
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Stop all running tools if configured
        if UserPreferences.shared.stopToolsOnQuit {
            Task {
                await ProcessManager.shared.stopAllProcesses()
            }
        }
    }
}
