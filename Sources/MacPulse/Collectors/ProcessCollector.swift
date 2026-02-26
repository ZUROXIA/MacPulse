import Foundation
import Darwin

public struct ProcessCollector: MetricsCollector {
    private var previousCPUTimes: [Int32: UInt64] = [:]
    private var previousTime: Date?
    private var cachedResult: ProcessMetrics = .empty
    private var sampleCounter = 0
    /// Only collect every Nth call (expensive: iterates all pids).
    private let collectEvery = 5

    public init() {}

    public mutating func collect() -> ProcessMetrics {
        sampleCounter += 1
        if sampleCounter < collectEvery && cachedResult.topByCPU.count > 0 {
            return cachedResult
        }
        sampleCounter = 0

        let now = Date()
        var allPids = [Int32](repeating: 0, count: 1024)
        let count = proc_listallpids(&allPids, Int32(allPids.count * MemoryLayout<Int32>.stride))

        guard count > 0 else {
            previousTime = now
            return .empty
        }

        let pidCount = Int(count)
        var currentCPUTimes: [Int32: UInt64] = Dictionary(minimumCapacity: pidCount)
        var processes: [(pid: Int32, name: String, cpuDelta: Double, memBytes: UInt64)] = []
        processes.reserveCapacity(min(pidCount, 100))

        let elapsed: TimeInterval
        if let prevTime = previousTime {
            elapsed = now.timeIntervalSince(prevTime)
        } else {
            elapsed = 0
        }

        let size = Int32(MemoryLayout<proc_taskinfo>.stride)

        for i in 0..<pidCount {
            let pid = allPids[i]
            guard pid > 0 else { continue }

            var taskInfo = proc_taskinfo()
            let result = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &taskInfo, size)

            guard result == size else { continue }

            let totalTime = taskInfo.pti_total_user + taskInfo.pti_total_system
            currentCPUTimes[pid] = totalTime

            var cpuDelta = 0.0
            if elapsed > 0, let prevTotal = previousCPUTimes[pid] {
                let deltaNs = totalTime > prevTotal ? totalTime - prevTotal : 0
                cpuDelta = Double(deltaNs) / (elapsed * 1_000_000_000)
            }

            let memBytes = UInt64(taskInfo.pti_resident_size)

            // Only get name for processes with meaningful activity
            guard cpuDelta > 0.001 || memBytes > 10_000_000 else { continue }

            var nameBuffer = [CChar](repeating: 0, count: Int(MAXPATHLEN))
            proc_name(pid, &nameBuffer, UInt32(nameBuffer.count))
            let name = String(cString: nameBuffer)

            guard !name.isEmpty else { continue }

            processes.append((pid: pid, name: name, cpuDelta: cpuDelta, memBytes: memBytes))
        }

        previousCPUTimes = currentCPUTimes
        previousTime = now

        let topByCPU = processes
            .sorted { $0.cpuDelta > $1.cpuDelta }
            .prefix(10)
            .map { ProcessInfo_(pid: $0.pid, name: $0.name, cpuUsage: $0.cpuDelta, memoryBytes: $0.memBytes) }

        let topByMemory = processes
            .sorted { $0.memBytes > $1.memBytes }
            .prefix(10)
            .map { ProcessInfo_(pid: $0.pid, name: $0.name, cpuUsage: $0.cpuDelta, memoryBytes: $0.memBytes) }

        cachedResult = ProcessMetrics(topByCPU: Array(topByCPU), topByMemory: Array(topByMemory))
        return cachedResult
    }
}
