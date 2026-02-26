import Foundation

public struct CPUMetrics: Sendable {
    public var totalUsage: Double
    public var perCoreUsage: [Double]

    public static let zero = CPUMetrics(totalUsage: 0, perCoreUsage: [])

    public init(totalUsage: Double, perCoreUsage: [Double]) {
        self.totalUsage = totalUsage
        self.perCoreUsage = perCoreUsage
    }
}
