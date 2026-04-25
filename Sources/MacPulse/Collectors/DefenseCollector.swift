import Foundation

public struct DefenseCollector: MetricsCollector {
    private final class Cache: @unchecked Sendable {
        var lastMetrics: DefenseMetrics = .empty
        var isFetching = false
    }
    
    private let cache = Cache()

    public init() {}

    public mutating func collect() -> DefenseMetrics {
        if !cache.isFetching {
            cache.isFetching = true
            let c = cache
            Task.detached {
                let data = ProcessHelper.getDefenseMetrics()
                c.lastMetrics = DefenseMetrics(
                    activeConnections: data.connections,
                    firewallRules: data.rules,
                    pfEnabled: data.pfEnabled
                )
                c.isFetching = false
            }
        }
        return cache.lastMetrics
    }
}
