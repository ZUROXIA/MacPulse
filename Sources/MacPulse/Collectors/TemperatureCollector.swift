import Foundation

public struct TemperatureCollector: MetricsCollector {
    public init() {}

    public func collect() -> TemperatureMetrics {
        let cpuTemp = SMCHelper.readCPUTemperature()
        let gpuTemp = SMCHelper.readGPUTemperature()

        let fanCount = SMCHelper.readFanCount()
        var fans: [FanInfo] = []
        for i in 0..<fanCount {
            let rpm = SMCHelper.readFanRPM(index: i)
            fans.append(FanInfo(index: i, rpm: rpm))
        }

        return TemperatureMetrics(cpuTemp: cpuTemp, gpuTemp: gpuTemp, fans: fans)
    }
}
