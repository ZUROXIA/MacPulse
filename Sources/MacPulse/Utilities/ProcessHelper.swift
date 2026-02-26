import Foundation
import Darwin
import os.log

private let logger = Logger(subsystem: "com.macpulse", category: "ProcessHelper")

public enum ProcessHelper {

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

    // MARK: - Private

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
