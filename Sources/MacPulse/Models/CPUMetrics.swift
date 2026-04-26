import Foundation

public struct CPUMetrics: Sendable {
    public var totalUsage: Double
    public var perCoreUsage: [Double]
    public var loadAverage: (Double, Double, Double)
    public var uptime: TimeInterval

    public static let zero = CPUMetrics(totalUsage: 0, perCoreUsage: [], loadAverage: (0, 0, 0), uptime: 0)

    public init(totalUsage: Double, perCoreUsage: [Double], loadAverage: (Double, Double, Double) = (0, 0, 0), uptime: TimeInterval = 0) {
        self.totalUsage = totalUsage
        self.perCoreUsage = perCoreUsage
        self.loadAverage = loadAverage
        self.uptime = uptime
    }
}
