import Foundation

public struct DefenseCollector: MetricsCollector {
    public init() {}

    public mutating func collect() -> DefenseMetrics {
        // Run our heavy network parsing asynchronously, but for a synchronous collector
        // we must block or collect quickly. ProcessHelper.getDefenseMetrics is synchronous.
        // It's reasonably fast since we cap at 50 connections.
        
        let data = ProcessHelper.getDefenseMetrics()
        
        return DefenseMetrics(
            activeConnections: data.connections,
            firewallRules: data.rules,
            pfEnabled: data.pfEnabled
        )
    }
}
