import Foundation

public struct GPUInfo: Sendable, Identifiable {
    public var id: String { name }
    public var name: String
    public var utilization: Double?
    public var vramUsed: UInt64?
    public var vramTotal: UInt64?

    public var vramFraction: Double? {
        guard let used = vramUsed, let total = vramTotal, total > 0 else { return nil }
        return Double(used) / Double(total)
    }

    public init(name: String, utilization: Double?, vramUsed: UInt64?, vramTotal: UInt64?) {
        self.name = name
        self.utilization = utilization
        self.vramUsed = vramUsed
        self.vramTotal = vramTotal
    }
}

public struct GPUMetrics: Sendable {
    public var gpus: [GPUInfo]

    public static let empty = GPUMetrics(gpus: [])

    public init(gpus: [GPUInfo]) {
        self.gpus = gpus
    }
}
