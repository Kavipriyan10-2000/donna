import Foundation

class PortFinder {
    static let shared = PortFinder()
    
    private var reservedPorts: Set<Int> = []
    
    /// Find an available port in the given range
    func findAvailablePort(min: Int = 10000, max: Int = 65000) -> Int? {
        for port in min...max {
            if isPortAvailable(port) && !reservedPorts.contains(port) {
                reservePort(port)
                return port
            }
        }
        return nil
    }
    
    /// Check if a specific port is available
    func isPortAvailable(_ port: Int) -> Bool {
        let socket = socket(AF_INET, SOCK_STREAM, 0)
        guard socket >= 0 else { return false }
        defer { close(socket) }
        
        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_addr.s_addr = INADDR_ANY
        addr.sin_port = in_port_t(port).bigEndian
        
        let bindResult = withUnsafePointer(to: &addr) { addrPtr in
            addrPtr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockAddrPtr in
                bind(socket, sockAddrPtr, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        
        return bindResult == 0
    }
    
    /// Reserve a port to prevent reuse
    func reservePort(_ port: Int) {
        reservedPorts.insert(port)
    }
    
    /// Release a reserved port
    func releasePort(_ port: Int) {
        reservedPorts.remove(port)
    }
    
    /// Get port from a tool's configuration
    func getPort(for tool: Tool) -> Int? {
        // If tool has fixed port, use it
        if let fixedPort = tool.manifest.start.port {
            return isPortAvailable(fixedPort) ? fixedPort : findAvailablePort()
        }
        
        // If tool has port range, find available in range
        if let portRange = tool.manifest.start.portRange {
            for port in portRange.min...portRange.max {
                if isPortAvailable(port) && !reservedPorts.contains(port) {
                    reservePort(port)
                    return port
                }
            }
        }
        
        // Fallback to any available port
        return findAvailablePort()
    }
}

import Darwin.POSIX.sys.socket
import Darwin.POSIX.netinet.in
import Darwin.POSIX.unistd
