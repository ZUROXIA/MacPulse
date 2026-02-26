import Foundation

public struct FanInfo: Sendable, Identifiable {
    public var id: Int { index }
    public var index: Int
    public var rpm: Int
    public var minRPM: Int
    public var maxRPM: Int

    public init(index: Int, rpm: Int, minRPM: Int = 0, maxRPM: Int = 0) {
        self.index = index
        self.rpm = rpm
        self.minRPM = minRPM
        self.maxRPM = maxRPM
    }
}

public struct TemperatureMetrics: Sendable {
    public var cpuTemp: Double?
    public var gpuTemp: Double?
    public var fans: [FanInfo]

    public static let unavailable = TemperatureMetrics(cpuTemp: nil, gpuTemp: nil, fans: [])

    public init(cpuTemp: Double?, gpuTemp: Double?, fans: [FanInfo]) {
        self.cpuTemp = cpuTemp
        self.gpuTemp = gpuTemp
        self.fans = fans
    }
}
