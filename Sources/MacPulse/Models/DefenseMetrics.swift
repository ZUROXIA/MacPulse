import Foundation

public struct DefenseMetrics: Sendable {
    public let activeConnections: [NetworkConnection]
    public let firewallRules: [FirewallRule]
    public let pfEnabled: Bool

    public static let empty = DefenseMetrics(
        activeConnections: [],
        firewallRules: [],
        pfEnabled: false
    )

    public init(activeConnections: [NetworkConnection], firewallRules: [FirewallRule], pfEnabled: Bool) {
        self.activeConnections = activeConnections
        self.firewallRules = firewallRules
        self.pfEnabled = pfEnabled
    }
}
