import Foundation

public struct MetricsHistory {
    private var buffer: [SystemSnapshot]
    private let capacity: Int
    private var writeIndex: Int = 0
    private var isFull: Bool = false

    /// Cached ordered view of the ring buffer, rebuilt once per `append()`.
    private var _orderedSnapshots: [SystemSnapshot] = []

    // Pre-computed history arrays — rebuilt once per append, read many times per render.
    private var _cpuHistory: [(Date, Double)] = []
    private var _memoryHistory: [(Date, Double)] = []
    private var _networkSendHistory: [(Date, Double)] = []
    private var _networkReceiveHistory: [(Date, Double)] = []
    private var _batteryHistory: [(Date, Double)] = []
    private var _thermalHistory: [(Date, Int)] = []
    private var _diskReadHistory: [(Date, Double)] = []
    private var _diskWriteHistory: [(Date, Double)] = []
    private var _cpuTempHistory: [(Date, Double)] = []
    private var _gpuUtilizationHistory: [(Date, Double)] = []
    private var _memoryPressureHistory: [(Date, Int)] = []
    private var _fanRPMHistory: [[(Date, Double)]] = []

    public init(capacity: Int = 300) {
        self.capacity = capacity
        self.buffer = []
        self.buffer.reserveCapacity(capacity)
    }

    public mutating func append(_ snapshot: SystemSnapshot) {
        if buffer.count < capacity {
            buffer.append(snapshot)
        } else {
            buffer[writeIndex] = snapshot
            isFull = true
        }
        writeIndex = (writeIndex + 1) % capacity

        // Rebuild ordered cache once per sample
        if !isFull {
            _orderedSnapshots = buffer
        } else {
            _orderedSnapshots = Array(buffer[writeIndex...]) + Array(buffer[..<writeIndex])
        }

        rebuildHistoryCache()
    }

    private mutating func rebuildHistoryCache() {
        let snaps = _orderedSnapshots
        _cpuHistory = snaps.map { ($0.timestamp, $0.cpu.totalUsage) }
        _memoryHistory = snaps.map { ($0.timestamp, $0.memory.usedFraction) }
        _networkSendHistory = snaps.map { ($0.timestamp, $0.network.totalSendRate) }
        _networkReceiveHistory = snaps.map { ($0.timestamp, $0.network.totalReceiveRate) }
        _batteryHistory = snaps.map { ($0.timestamp, $0.battery.chargePercent) }
        _diskReadHistory = snaps.map { ($0.timestamp, $0.diskIO.readRate) }
        _diskWriteHistory = snaps.map { ($0.timestamp, $0.diskIO.writeRate) }
        _memoryPressureHistory = snaps.map { ($0.timestamp, $0.memory.pressureLevel.rawValue) }

        _thermalHistory = snaps.map { snapshot in
            let value: Int
            switch snapshot.thermal.level {
            case .nominal: value = 0
            case .fair: value = 1
            case .serious: value = 2
            case .critical: value = 3
            }
            return (snapshot.timestamp, value)
        }

        _cpuTempHistory = snaps.compactMap { s in
            guard let temp = s.temperature.cpuTemp else { return nil }
            return (s.timestamp, temp)
        }

        _gpuUtilizationHistory = snaps.compactMap { s in
            guard let util = s.gpu.gpus.first?.utilization else { return nil }
            return (s.timestamp, util)
        }

        // Build per-fan RPM history
        let maxFanCount = snaps.map { $0.temperature.fans.count }.max() ?? 0
        _fanRPMHistory = (0..<maxFanCount).map { fanIndex in
            snaps.compactMap { s in
                guard fanIndex < s.temperature.fans.count else { return nil }
                return (s.timestamp, Double(s.temperature.fans[fanIndex].rpm))
            }
        }
    }

    public var snapshots: [SystemSnapshot] { _orderedSnapshots }
    public var count: Int { buffer.count }

    public var cpuHistory: [(Date, Double)] { _cpuHistory }
    public var memoryHistory: [(Date, Double)] { _memoryHistory }
    public var networkSendHistory: [(Date, Double)] { _networkSendHistory }
    public var networkReceiveHistory: [(Date, Double)] { _networkReceiveHistory }
    public var batteryHistory: [(Date, Double)] { _batteryHistory }
    public var thermalHistory: [(Date, Int)] { _thermalHistory }
    public var diskReadHistory: [(Date, Double)] { _diskReadHistory }
    public var diskWriteHistory: [(Date, Double)] { _diskWriteHistory }
    public var cpuTempHistory: [(Date, Double)] { _cpuTempHistory }
    public var gpuUtilizationHistory: [(Date, Double)] { _gpuUtilizationHistory }
    public var memoryPressureHistory: [(Date, Int)] { _memoryPressureHistory }
    public var fanRPMHistory: [[(Date, Double)]] { _fanRPMHistory }
}
