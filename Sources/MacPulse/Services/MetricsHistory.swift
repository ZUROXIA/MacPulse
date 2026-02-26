import Foundation

public struct MetricsHistory {
    private var buffer: [SystemSnapshot]
    private let capacity: Int
    private var writeIndex: Int = 0
    private var isFull: Bool = false

    /// Cached ordered view of the ring buffer, rebuilt once per `append()`.
    private var _orderedSnapshots: [SystemSnapshot] = []

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
    }

    public var snapshots: [SystemSnapshot] {
        _orderedSnapshots
    }

    public var count: Int {
        buffer.count
    }

    public var cpuHistory: [(Date, Double)] {
        _orderedSnapshots.map { ($0.timestamp, $0.cpu.totalUsage) }
    }

    public var memoryHistory: [(Date, Double)] {
        _orderedSnapshots.map { ($0.timestamp, $0.memory.usedFraction) }
    }

    public var networkSendHistory: [(Date, Double)] {
        _orderedSnapshots.map { ($0.timestamp, $0.network.totalSendRate) }
    }

    public var networkReceiveHistory: [(Date, Double)] {
        _orderedSnapshots.map { ($0.timestamp, $0.network.totalReceiveRate) }
    }

    public var batteryHistory: [(Date, Double)] {
        _orderedSnapshots.map { ($0.timestamp, $0.battery.chargePercent) }
    }

    public var thermalHistory: [(Date, Int)] {
        _orderedSnapshots.map { snapshot in
            let value: Int
            switch snapshot.thermal.level {
            case .nominal: value = 0
            case .fair: value = 1
            case .serious: value = 2
            case .critical: value = 3
            }
            return (snapshot.timestamp, value)
        }
    }

    public var diskReadHistory: [(Date, Double)] {
        _orderedSnapshots.map { ($0.timestamp, $0.diskIO.readRate) }
    }

    public var diskWriteHistory: [(Date, Double)] {
        _orderedSnapshots.map { ($0.timestamp, $0.diskIO.writeRate) }
    }

    public var cpuTempHistory: [(Date, Double)] {
        _orderedSnapshots.compactMap { s in
            guard let temp = s.temperature.cpuTemp else { return nil }
            return (s.timestamp, temp)
        }
    }

    public var gpuUtilizationHistory: [(Date, Double)] {
        _orderedSnapshots.compactMap { s in
            guard let util = s.gpu.gpus.first?.utilization else { return nil }
            return (s.timestamp, util)
        }
    }
}
