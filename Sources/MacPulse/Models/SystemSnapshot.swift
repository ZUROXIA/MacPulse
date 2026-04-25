import Foundation

public struct SystemSnapshot: Sendable, Identifiable {
    public var id: Date { timestamp }
    public var timestamp: Date
    public var cpu: CPUMetrics
    public var memory: MemoryMetrics
    public var disk: DiskMetrics
    public var battery: BatteryMetrics
    public var network: NetworkMetrics
    public var thermal: ThermalMetrics
    public var diskIO: DiskIOMetrics
    public var temperature: TemperatureMetrics
    public var processes: ProcessMetrics
    public var gpu: GPUMetrics
    public var defense: DefenseMetrics

    public static let empty = SystemSnapshot(
        timestamp: .now,
        cpu: .zero,
        memory: .zero,
        disk: .zero,
        battery: .unavailable,
        network: .zero,
        thermal: .nominal,
        diskIO: .zero,
        temperature: .unavailable,
        processes: .empty,
        gpu: .empty,
        defense: .empty
    )

    public init(timestamp: Date, cpu: CPUMetrics, memory: MemoryMetrics, disk: DiskMetrics, battery: BatteryMetrics, network: NetworkMetrics, thermal: ThermalMetrics, diskIO: DiskIOMetrics = .zero, temperature: TemperatureMetrics = .unavailable, processes: ProcessMetrics = .empty, gpu: GPUMetrics = .empty, defense: DefenseMetrics = .empty) {
        self.timestamp = timestamp
        self.cpu = cpu
        self.memory = memory
        self.disk = disk
        self.battery = battery
        self.network = network
        self.thermal = thermal
        self.diskIO = diskIO
        self.temperature = temperature
        self.processes = processes
        self.gpu = gpu
        self.defense = defense
    }
}
