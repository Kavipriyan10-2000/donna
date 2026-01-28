import Foundation

class ToolRegistry {
    static let shared = ToolRegistry()
    
    private let fileManager = FileManager.default
    private var manifestsDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("ToolHub/Manifests")
    }
    
    private let bundledManifestsDirectory: URL
    
    init() {
        // Get the bundled manifests directory
        let bundle = Bundle.main
        bundledManifestsDirectory = bundle.resourceURL?.appendingPathComponent("Manifests") ?? bundle.bundleURL
        
        // Create manifests directory if needed
        try? fileManager.createDirectory(at: manifestsDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Manifest Loading
    
    func loadAllManifests() -> [ToolManifest] {
        var manifests: [ToolManifest] = []
        
        // Load bundled manifests
        manifests.append(contentsOf: loadManifestsFromDirectory(bundledManifestsDirectory))
        
        // Load user manifests
        manifests.append(contentsOf: loadManifestsFromDirectory(manifestsDirectory))
        
        // Remove duplicates (user manifests override bundled)
        let uniqueManifests = Dictionary(grouping: manifests, by: { $0.id })
            .compactMap { _, manifests -> ToolManifest? in
                // Prefer user manifest (from app support) over bundled
                manifests.first { $0.id != "" && manifests.count > 1 } ?? manifests.first
            }
        
        return uniqueManifests
    }
    
    func loadManifest(for toolId: String) -> ToolManifest? {
        // Check user manifests first
        let userManifestURL = manifestsDirectory.appendingPathComponent("\(toolId).json")
        if fileManager.fileExists(atPath: userManifestURL.path),
           let manifest = loadManifest(from: userManifestURL) {
            return manifest
        }
        
        // Check bundled manifests
        let bundledManifestURL = bundledManifestsDirectory.appendingPathComponent("\(toolId).json")
        if let manifest = loadManifest(from: bundledManifestURL) {
            return manifest
        }
        
        return nil
    }
    
    private func loadManifestsFromDirectory(_ directory: URL) -> [ToolManifest] {
        guard let files = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else {
            return []
        }
        
        return files.compactMap { url in
            guard url.pathExtension == "json" else { return nil }
            return loadManifest(from: url)
        }
    }
    
    private func loadManifest(from url: URL) -> ToolManifest? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do {
            let manifest = try decoder.decode(ToolManifest.self, from: data)
            try validateManifest(manifest)
            return manifest
        } catch {
            print("Failed to load manifest from \(url): \(error)")
            return nil
        }
    }
    
    // MARK: - Manifest Validation
    
    func validateManifest(_ manifest: ToolManifest) throws {
        // Required fields
        guard !manifest.id.isEmpty else {
            throw ToolRegistryError.invalidManifest("Tool ID is required")
        }
        
        guard !manifest.name.isEmpty else {
            throw ToolRegistryError.invalidManifest("Tool name is required")
        }
        
        guard !manifest.install.command.isEmpty else {
            throw ToolRegistryError.invalidManifest("Install command is required")
        }
        
        guard !manifest.start.command.isEmpty else {
            throw ToolRegistryError.invalidManifest("Start command is required")
        }
        
        // Port validation
        if let port = manifest.start.port {
            guard port > 0 && port < 65536 else {
                throw ToolRegistryError.invalidManifest("Invalid port: \(port)")
            }
        }
        
        // Port range validation
        if let portRange = manifest.start.portRange {
            guard portRange.min > 0 && portRange.min < 65536 else {
                throw ToolRegistryError.invalidManifest("Invalid port range min: \(portRange.min)")
            }
            guard portRange.max > portRange.min && portRange.max < 65536 else {
                throw ToolRegistryError.invalidManifest("Invalid port range max: \(portRange.max)")
            }
        }
        
        // Must have either port or port range
        guard manifest.start.port != nil || manifest.start.portRange != nil else {
            throw ToolRegistryError.invalidManifest("Either port or portRange is required")
        }
    }
    
    // MARK: - Manifest Saving
    
    func saveManifest(_ manifest: ToolManifest) throws {
        try validateManifest(manifest)
        
        let url = manifestsDirectory.appendingPathComponent("\(manifest.id).json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.keyEncodingStrategy = .convertToSnakeCase
        
        let data = try encoder.encode(manifest)
        try data.write(to: url)
    }
    
    func deleteManifest(id: String) throws {
        let url = manifestsDirectory.appendingPathComponent("\(id).json")
        guard fileManager.fileExists(atPath: url.path) else {
            throw ToolRegistryError.manifestNotFound(id)
        }
        try fileManager.removeItem(at: url)
    }
    
    // MARK: - Catalog
    
    func getAvailableTools() -> [ToolManifest] {
        // Returns all manifests that aren't installed
        let allManifests = loadAllManifests()
        let installedIds = UserPreferences.shared.installedToolIds
        return allManifests.filter { !installedIds.contains($0.id) }
    }
}

enum ToolRegistryError: Error, LocalizedError {
    case invalidManifest(String)
    case manifestNotFound(String)
    case saveFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidManifest(let reason):
            return "Invalid manifest: \(reason)"
        case .manifestNotFound(let id):
            return "Manifest not found for tool: \(id)"
        case .saveFailed(let error):
            return "Failed to save manifest: \(error.localizedDescription)"
        }
    }
}
