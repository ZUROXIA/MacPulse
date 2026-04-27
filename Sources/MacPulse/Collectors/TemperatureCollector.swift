import Foundation

public struct TemperatureCollector: MetricsCollector {
    public init() {}

    public func collect() -> TemperatureMetrics {
        let cpuTemp = SMCHelper.readCPUTemperature()
        let gpuTemp = SMCHelper.readGPUTemperature()
        let power = SMCHelper.readSystemPower()
        let amps = SMCHelper.readBatteryAmperage()
        let volts = SMCHelper.readBatteryVoltage()

        let fanCount = SMCHelper.readFanCount()
        var fans: [FanInfo] = []
        for i in 0..<fanCount {
            let rpm = SMCHelper.readFanRPM(index: i)
            let minRPM = SMCHelper.readFanMinRPM(index: i)
            let maxRPM = SMCHelper.readFanMaxRPM(index: i)
            fans.append(FanInfo(index: i, rpm: rpm, minRPM: minRPM, maxRPM: maxRPM))
        }

        return TemperatureMetrics(
            cpuTemp: cpuTemp, 
            gpuTemp: gpuTemp, 
            fans: fans,
            systemWatts: power,
            batteryAmps: amps,
            batteryVolts: volts
        )
    }
}
