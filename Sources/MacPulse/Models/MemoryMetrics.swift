import Foundation

public enum MemoryPressureLevel: Int, Sendable, CaseIterable {
    case normal = 0
    case warning = 1
    case critical = 2

    public var label: String {
        switch self {
        case .normal: "Normal"
        case .warning: "Warning"
        case .critical: "Critical"
        }
    }
}

public struct MemoryMetrics: Sendable {
    public var total: UInt64
    public var used: UInt64
    public var free: UInt64
    public var active: UInt64
    public var wired: UInt64
    public var compressed: UInt64
    public var pressureLevel: MemoryPressureLevel

    public var usedFraction: Double {
        total > 0 ? Double(used) / Double(total) : 0
    }

    public static let zero = MemoryMetrics(total: 0, used: 0, free: 0, active: 0, wired: 0, compressed: 0, pressureLevel: .normal)

    public init(total: UInt64, used: UInt64, free: UInt64, active: UInt64, wired: UInt64, compressed: UInt64, pressureLevel: MemoryPressureLevel = .normal) {
        self.total = total
        self.used = used
        self.free = free
        self.active = active
        self.wired = wired
        self.compressed = compressed
        self.pressureLevel = pressureLevel
    }
}
