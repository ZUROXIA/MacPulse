import Foundation
import Darwin
import os.log

private let logger = Logger(subsystem: "com.macpulse", category: "ProcessHelper")

public struct NetworkConnection: Sendable, Identifiable, Equatable {
    public var id: String { "\(localIP):\(localPort)-\(remoteIP):\(remotePort)" }
    public let localIP: String
    public let localPort: String
    public let remoteIP: String
    public let remotePort: String
    public let status: String
    public let time: String
    
    public init(localIP: String, localPort: String, remoteIP: String, remotePort: String, status: String, time: String) {
        self.localIP = localIP
        self.localPort = localPort
        self.remoteIP = remoteIP
        self.remotePort = remotePort
        self.status = status
        self.time = time
    }
}

public struct FirewallRule: Sendable, Identifiable, Equatable {
    public var id: String { "\(action)-\(self.protocol)-\(ip)-\(port)" }
    public let action: String
    public let `protocol`: String
    public let ip: String
    public let port: String
    
    public init(action: String, protocol: String, ip: String, port: String) {
        self.action = action
        self.`protocol` = `protocol`
        self.ip = ip
        self.port = port
    }
}

public enum ProcessHelper {

    /// Whether the app is running inside an App Sandbox container.
    public static var isSandboxed: Bool {
        ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] != nil
    }

    /// PIDs that must never be terminated (kernel, launchd).
    private static let protectedPIDs: Set<Int32> = [0, 1]

    /// Returns false for PID 0, PID 1, or the app's own PID.
    public static func isSafeToTerminate(pid: Int32) -> Bool {
        !protectedPIDs.contains(pid) && pid != getpid()
    }

    /// Sends SIGTERM to the given process. Returns true if the signal was delivered.
    /// Refuses to signal protected PIDs or the app itself.
    public static func terminateProcess(pid: Int32) -> Bool {
        guard isSafeToTerminate(pid: pid) else {
            logger.warning("Refused to terminate protected PID \(pid)")
            return false
        }
        let ok = kill(pid, SIGTERM) == 0
        if ok {
            logger.info("Sent SIGTERM to PID \(pid)")
        } else {
            logger.error("Failed to send SIGTERM to PID \(pid): errno \(errno)")
        }
        return ok
    }

    /// Sends SIGKILL to the given process. Returns true if the signal was delivered.
    /// Refuses to signal protected PIDs or the app itself.
    public static func forceKillProcess(pid: Int32) -> Bool {
        guard isSafeToTerminate(pid: pid) else {
            logger.warning("Refused to force-kill protected PID \(pid)")
            return false
        }
        let ok = kill(pid, SIGKILL) == 0
        if ok {
            logger.info("Sent SIGKILL to PID \(pid)")
        } else {
            logger.error("Failed to send SIGKILL to PID \(pid): errno \(errno)")
        }
        return ok
    }

    /// Runs `/usr/sbin/purge` to flush the disk cache and reclaim memory.
    /// Requires elevated privileges to have full effect.
    public static func purgeMemory() -> Bool {
        logger.info("Running memory purge")
        let ok = runProcess(path: "/usr/sbin/purge", arguments: [])
        logger.info("Memory purge \(ok ? "succeeded" : "failed")")
        return ok
    }

    /// Flushes the DNS cache via `dscacheutil -flushcache`.
    public static func flushDNSCache() -> Bool {
        logger.info("Flushing DNS cache")
        let ok = runProcess(path: "/usr/bin/dscacheutil", arguments: ["-flushcache"])
        logger.info("DNS flush \(ok ? "succeeded" : "failed")")
        return ok
    }

    /// Estimates the total size of the user's `~/Library/Caches/` directory in bytes.
    public static func estimateUserCacheSize() -> UInt64 {
        let cachesURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Caches")
        return directorySize(url: cachesURL)
    }

    /// Removes safe cache directories under `~/Library/Caches/`,
    /// skipping browser profiles and system-critical caches.
    /// Returns the number of bytes freed.
    public static func clearUserCaches() -> UInt64 {
        let fm = FileManager.default
        let cachesURL = fm.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Caches")

        // Skip browser caches and system-critical directories
        let skipPrefixes = [
            "com.apple.Safari",
            "com.google.Chrome",
            "org.mozilla.firefox",
            "com.microsoft.Edge",
            "com.brave.Browser",
            "com.apple.nsurlsessiond",
            "CloudKit",
        ]

        var freed: UInt64 = 0

        guard let entries = try? fm.contentsOfDirectory(
            at: cachesURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        for entry in entries {
            let name = entry.lastPathComponent
            if skipPrefixes.contains(where: { name.hasPrefix($0) }) {
                continue
            }
            let size = directorySize(url: entry)
            do {
                try fm.removeItem(at: entry)
                freed += size
            } catch {
                // Skip items we can't remove
            }
        }

        logger.info("Cleared user caches: freed \(freed) bytes")
        return freed
    }
    
    /// Queries the system for active network connections and firewall rules.
    public static func getDefenseMetrics() -> (connections: [NetworkConnection], rules: [FirewallRule], pfEnabled: Bool) {
        if isSandboxed {
            return ([], [], false) // Cannot spawn these processes effectively from Sandbox
        }
        
        var connections: [NetworkConnection] = []
        var rules: [FirewallRule] = []
        var pfEnabled = false
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let currentTime = formatter.string(from: Date())
        
        // 1. Get active TCP connections via netstat
        if let netstatOut = runCommandAndReadOutput(path: "/usr/sbin/netstat", arguments: ["-an", "-f", "inet", "-p", "tcp"]) {
            let lines = netstatOut.components(separatedBy: .newlines)
            var count = 0
            for line in lines {
                if count >= 50 { break } // Limit to top 50
                let parts = line.split(separator: " ").map(String.init)
                // typical line: tcp4       0      0  192.168.1.101.54321    104.22.14.9.443       ESTABLISHED
                if parts.count >= 6 && parts[0].starts(with: "tcp") && parts[5] != "LISTEN" && parts[5] != "CLOSED" {
                    let local = parts[3]
                    let remote = parts[4]
                    let status = parts[5]
                    
                    let localParts = splitHostPort(local)
                    let remoteParts = splitHostPort(remote)
                    
                    connections.append(NetworkConnection(
                        localIP: localParts.host,
                        localPort: localParts.port,
                        remoteIP: remoteParts.host,
                        remotePort: remoteParts.port,
                        status: status,
                        time: currentTime
                    ))
                    count += 1
                }
            }
        }
        
        // 2. Check pfctl status (requires sudo for real rules, but we can try to get status if possible, otherwise we return some defaults or empty)
        if let pfctlStatus = runCommandAndReadOutput(path: "/sbin/pfctl", arguments: ["-s", "info"]) {
            pfEnabled = pfctlStatus.contains("Status: Enabled")
        }
        
        // As a fallback/demo if pfctl rules can't be read without sudo, we check macOS App Firewall via socket filter or just provide system defaults.
        // For a true view we'd parse `pfctl -sr`. Since we might not have root, we will parse if available.
        if let pfRulesOut = runCommandAndReadOutput(path: "/sbin/pfctl", arguments: ["-sr"]) {
            let lines = pfRulesOut.components(separatedBy: .newlines)
            for line in lines {
                if line.isEmpty { continue }
                // Parse basic pf rules (block drop in all, pass out all, etc)
                let action = line.contains("block") ? "BLOCKED" : "ALLOW"
                let proto = line.contains("proto tcp") ? "TCP" : (line.contains("proto udp") ? "UDP" : "ALL")
                rules.append(FirewallRule(action: action, protocol: proto, ip: "ANY", port: "ALL"))
            }
        }
        
        return (connections, rules, pfEnabled)
    }

    // MARK: - Private
    
    private static func splitHostPort(_ string: String) -> (host: String, port: String) {
        if let lastDotIndex = string.lastIndex(of: ".") {
            let host = String(string[..<lastDotIndex])
            let port = String(string[string.index(after: lastDotIndex)...])
            return (host, port)
        }
        return (string, "")
    }

    private static func runProcess(path: String, arguments: [String]) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    private static func runCommandAndReadOutput(path: String, arguments: [String]) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            if process.terminationStatus == 0 {
                return String(data: data, encoding: .utf8)
            }
            return nil
        } catch {
            return nil
        }
    }

    private static func directorySize(url: URL) -> UInt64 {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles],
            errorHandler: nil
        ) else {
            return 0
        }

        var total: UInt64 = 0
        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]),
                  values.isRegularFile == true,
                  let size = values.fileSize else { continue }
            total += UInt64(size)
        }
        return total
    }
}
