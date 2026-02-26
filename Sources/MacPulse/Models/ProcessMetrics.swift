import Foundation

public struct ProcessInfo_: Sendable, Identifiable {
    public var id: Int32 { pid }
    public var pid: Int32
    public var name: String
    public var cpuUsage: Double
    public var memoryBytes: UInt64

    public init(pid: Int32, name: String, cpuUsage: Double, memoryBytes: UInt64) {
        self.pid = pid
        self.name = name
        self.cpuUsage = cpuUsage
        self.memoryBytes = memoryBytes
    }
}

public struct ProcessMetrics: Sendable {
    public var topByCPU: [ProcessInfo_]
    public var topByMemory: [ProcessInfo_]

    public static let empty = ProcessMetrics(topByCPU: [], topByMemory: [])

    public init(topByCPU: [ProcessInfo_], topByMemory: [ProcessInfo_]) {
        self.topByCPU = topByCPU
        self.topByMemory = topByMemory
    }
}
