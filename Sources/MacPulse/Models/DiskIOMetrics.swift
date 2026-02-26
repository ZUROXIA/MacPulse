import Foundation

public struct DiskIOMetrics: Sendable {
    public var readRate: Double
    public var writeRate: Double

    public static let zero = DiskIOMetrics(readRate: 0, writeRate: 0)

    public init(readRate: Double, writeRate: Double) {
        self.readRate = readRate
        self.writeRate = writeRate
    }
}
