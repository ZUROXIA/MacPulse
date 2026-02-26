import Foundation

public struct ThermalCollector: MetricsCollector {
    public init() {}

    public func collect() -> ThermalMetrics {
        ThermalMetrics(level: ThermalLevel(from: ProcessInfo.processInfo.thermalState))
    }
}
