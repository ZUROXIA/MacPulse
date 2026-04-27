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
    public var systemWatts: Double?
    public var batteryAmps: Double?
    public var batteryVolts: Double?

    public static let unavailable = TemperatureMetrics(cpuTemp: nil, gpuTemp: nil, fans: [], systemWatts: nil, batteryAmps: nil, batteryVolts: nil)

    public init(cpuTemp: Double?, gpuTemp: Double?, fans: [FanInfo], systemWatts: Double? = nil, batteryAmps: Double? = nil, batteryVolts: Double? = nil) {
        self.cpuTemp = cpuTemp
        self.gpuTemp = gpuTemp
        self.fans = fans
        self.systemWatts = systemWatts
        self.batteryAmps = batteryAmps
        self.batteryVolts = batteryVolts
    }
}
