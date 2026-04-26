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
    public var swapUsed: UInt64
    public var swapTotal: UInt64

    public var usedFraction: Double {
        total > 0 ? Double(used) / Double(total) : 0
    }

    public static let zero = MemoryMetrics(
        total: 0, used: 0, free: 0, active: 0, wired: 0, compressed: 0, pressureLevel: .normal, swapUsed: 0, swapTotal: 0
    )

    public init(total: UInt64, used: UInt64, free: UInt64, active: UInt64, wired: UInt64, compressed: UInt64, pressureLevel: MemoryPressureLevel, swapUsed: UInt64 = 0, swapTotal: UInt64 = 0) {
        self.total = total
        self.used = used
        self.free = free
        self.active = active
        self.wired = wired
        self.compressed = compressed
        self.pressureLevel = pressureLevel
        self.swapUsed = swapUsed
        self.swapTotal = swapTotal
    }
}
