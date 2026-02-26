import Foundation
import Combine

@MainActor
@Observable
public final class SystemMonitor {
    public var currentSnapshot: SystemSnapshot = .empty
    public var history = MetricsHistory()

    private var cpuCollector = CPUCollector()
    private var memoryCollector = MemoryCollector()
    private var diskCollector = DiskCollector()
    private var batteryCollector = BatteryCollector()
    private var networkCollector = NetworkCollector()
    private var thermalCollector = ThermalCollector()
    private var diskIOCollector = DiskIOCollector()
    private var temperatureCollector = TemperatureCollector()
    private var processCollector = ProcessCollector()
    private var gpuCollector = GPUCollector()

    public var alertManager = AlertManager()
    private let store = MetricsStore()
    private var pruneCounter = 0

    private var timer: Timer?
    private var interval: TimeInterval = 2.0
    private var isRunning = false

    public var isReady: Bool { history.count > 0 }

    public init() {}

    public func start() {
        guard !isRunning else { return }
        isRunning = true

        // Restore recent history from disk (on background queue)
        let store = self.store
        Task.detached {
            let recent = store.loadRecent(maxAge: 600)
            await MainActor.run { [weak self] in
                for snapshot in recent {
                    self?.history.append(snapshot)
                }
            }
        }

        sample()
        scheduleTimer()
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    public func restart(interval newInterval: TimeInterval) {
        interval = newInterval
        stop()
        isRunning = true
        scheduleTimer()
    }

    private func scheduleTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sample()
            }
        }
    }

    private func sample() {
        let snapshot = SystemSnapshot(
            timestamp: .now,
            cpu: cpuCollector.collect(),
            memory: memoryCollector.collect(),
            disk: diskCollector.collect(),
            battery: batteryCollector.collect(),
            network: networkCollector.collect(),
            thermal: thermalCollector.collect(),
            diskIO: diskIOCollector.collect(),
            temperature: temperatureCollector.collect(),
            processes: processCollector.collect(),
            gpu: gpuCollector.collect()
        )
        currentSnapshot = snapshot
        history.append(snapshot)
        alertManager.evaluate(snapshot: snapshot)

        // Persist to SQLite on background queue
        let store = self.store
        Task.detached {
            store.save(snapshot)
        }

        // Update shared defaults for widget
        let shared = UserDefaults(suiteName: "com.macpulse.shared")
        shared?.set(snapshot.cpu.totalUsage, forKey: "widget.cpuUsage")
        shared?.set(snapshot.memory.usedFraction, forKey: "widget.memoryUsage")
        shared?.set(snapshot.thermal.level.rawValue, forKey: "widget.thermalLevel")

        // Prune old data every ~100 samples
        pruneCounter += 1
        if pruneCounter >= 100 {
            pruneCounter = 0
            Task.detached { store.prune() }
        }
    }
}
