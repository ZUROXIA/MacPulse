import Foundation

public struct CPUCollector: MetricsCollector {
    private var previousTicks: [MachHelpers.CPURawTicks]?

    public init() {}

    public mutating func collect() -> CPUMetrics {
        guard let currentTicks = MachHelpers.rawProcessorTicks() else {
            return .zero
        }

        defer { previousTicks = currentTicks }

        guard let prev = previousTicks, prev.count == currentTicks.count else {
            return CPUMetrics(
                totalUsage: 0,
                perCoreUsage: Array(repeating: 0, count: currentTicks.count)
            )
        }

        var perCore: [Double] = []
        var totalActive: UInt64 = 0
        var totalAll: UInt64 = 0

        for i in 0..<currentTicks.count {
            let deltaActive = currentTicks[i].active - prev[i].active
            let deltaTotal = currentTicks[i].total - prev[i].total

            let usage = deltaTotal > 0 ? Double(deltaActive) / Double(deltaTotal) : 0
            perCore.append(min(usage, 1.0))

            totalActive += deltaActive
            totalAll += deltaTotal
        }

        let overall = totalAll > 0 ? Double(totalActive) / Double(totalAll) : 0

        return CPUMetrics(
            totalUsage: min(overall, 1.0),
            perCoreUsage: perCore
        )
    }
}
