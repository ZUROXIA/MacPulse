import Foundation

public struct BatteryMetrics: Sendable {
    public var isPresent: Bool
    public var chargePercent: Double
    public var isCharging: Bool
    public var cycleCount: Int
    public var health: Double
    public var powerSource: String
    public var timeRemaining: Int?

    public static let unavailable = BatteryMetrics(
        isPresent: false,
        chargePercent: 0,
        isCharging: false,
        cycleCount: 0,
        health: 0,
        powerSource: "Unknown",
        timeRemaining: nil
    )

    public init(isPresent: Bool, chargePercent: Double, isCharging: Bool, cycleCount: Int, health: Double, powerSource: String, timeRemaining: Int?) {
        self.isPresent = isPresent
        self.chargePercent = chargePercent
        self.isCharging = isCharging
        self.cycleCount = cycleCount
        self.health = health
        self.powerSource = powerSource
        self.timeRemaining = timeRemaining
    }
}
