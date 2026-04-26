import Foundation

public struct BluetoothPeripheral: Sendable, Identifiable {
    public let id: String // MAC Address or UUID
    public let name: String
    public let batteryLevel: Int // 0-100
    
    public init(id: String, name: String, batteryLevel: Int) {
        self.id = id
        self.name = name
        self.batteryLevel = batteryLevel
    }
}

public struct BatteryMetrics: Sendable {
    public var isPresent: Bool
    public var chargePercent: Double
    public var isCharging: Bool
    public var cycleCount: Int
    public var health: Double
    public var powerSource: String
    public var timeRemaining: Int?
    public var peripherals: [BluetoothPeripheral]

    public static let unavailable = BatteryMetrics(
        isPresent: false,
        chargePercent: 0,
        isCharging: false,
        cycleCount: 0,
        health: 0,
        powerSource: "Unknown",
        timeRemaining: nil,
        peripherals: []
    )

    public init(isPresent: Bool, chargePercent: Double, isCharging: Bool, cycleCount: Int, health: Double, powerSource: String, timeRemaining: Int?, peripherals: [BluetoothPeripheral] = []) {
        self.isPresent = isPresent
        self.chargePercent = chargePercent
        self.isCharging = isCharging
        self.cycleCount = cycleCount
        self.health = health
        self.powerSource = powerSource
        self.timeRemaining = timeRemaining
        self.peripherals = peripherals
    }
}
