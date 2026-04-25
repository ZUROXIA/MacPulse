import Foundation
import SwiftUI

@Observable
@MainActor
public final class LogStreamService {
    public private(set) var logs: [LogEntry] = []
    public private(set) var isStreaming: Bool = false
    
    private var process: Process?
    private var pipe: Pipe?
    private var task: Task<Void, Never>?
    
    public struct LogEntry: Identifiable, Sendable {
        public let id = UUID()
        public let timestamp: String
        public let message: String
        public let isWarning: Bool
    }
    
    public init() {}
    
    public func startStreaming() {
        guard !isStreaming else { return }
        isStreaming = true
        logs.removeAll()
        
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/log")
        // Stream system-level updates
        p.arguments = [
            "stream", 
            "--style", "compact", 
            "--color", "never",
            "--predicate", "process == \"kernel_task\" OR process == \"syslogd\" OR process == \"MacPulse\"", 
            "--info"
        ]
        
        let pip = Pipe()
        p.standardOutput = pip
        
        self.process = p
        self.pipe = pip
        
        do {
            try p.run()
            
            task = Task.detached { [weak self] in
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm:ss"
                
                do {
                    for try await line in pip.fileHandleForReading.bytes.lines {
                        let time = formatter.string(from: Date())
                        let isWarn = line.lowercased().contains("error") || line.lowercased().contains("fault") || line.lowercased().contains("warning")
                        let entry = LogEntry(timestamp: time, message: line.trimmingCharacters(in: .whitespacesAndNewlines), isWarning: isWarn)
                        
                        await MainActor.run {
                            guard let self = self else { return }
                            self.logs.insert(entry, at: 0)
                            if self.logs.count > 100 {
                                self.logs.removeLast()
                            }
                        }
                    }
                } catch {
                    // ignore termination errors
                }
            }
        } catch {
            let entry = LogEntry(timestamp: "00:00:00", message: "[SYSTEM ERROR] Failed to initialize log stream.", isWarning: true)
            logs.insert(entry, at: 0)
            isStreaming = false
        }
    }
    
    public func stopStreaming() {
        task?.cancel()
        task = nil
        process?.terminate()
        process = nil
        pipe = nil
        isStreaming = false
    }
}