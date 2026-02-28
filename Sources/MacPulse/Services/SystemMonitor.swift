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

    private var preThermalProfile: FanProfile?
    private var thermalOverrideActive = false

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
        restoreFanProfile()
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
        evaluateThermalFanSwitch(thermalLevel: snapshot.thermal.level)

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

    private func restoreFanProfile() {
        let defaults = UserDefaults.standard
        let forcedActive = defaults.bool(forKey: "fan.forcedActive")
        let profileRaw = defaults.string(forKey: "fan.profile") ?? "Auto"
        let profile = FanProfile(rawValue: profileRaw) ?? .auto

        if forcedActive && profile == .auto {
            // Crash recovery: forcedActive but profile is auto — reset
            _ = SMCHelper.setFanMode(forced: false)
            defaults.set(false, forKey: "fan.forcedActive")
            return
        }

        guard profile != .auto && profile != .custom else { return }

        _ = SMCHelper.setFanMode(forced: true)
        for fan in temperatureCollector.collect().fans where fan.maxRPM > 0 {
            if let target = profile.targetRPM(minRPM: fan.minRPM, maxRPM: fan.maxRPM) {
                _ = SMCHelper.setFanMinRPM(index: fan.index, rpm: target)
            }
        }
    }

    private func evaluateThermalFanSwitch(thermalLevel: ThermalLevel) {
        let defaults = UserDefaults.standard
        let autoSwitchEnabled = defaults.object(forKey: "fan.thermalAutoSwitch") != nil
            ? defaults.bool(forKey: "fan.thermalAutoSwitch") : true
        guard autoSwitchEnabled else { return }

        let profileRaw = defaults.string(forKey: "fan.profile") ?? "Auto"
        let currentProfile = FanProfile(rawValue: profileRaw) ?? .auto

        if FanProfile.shouldAutoSwitchToPerformance(
            thermalLevel: thermalLevel,
            currentProfile: currentProfile,
            alreadyOverridden: thermalOverrideActive
        ) {
            preThermalProfile = currentProfile
            thermalOverrideActive = true

            defaults.set(FanProfile.performance.rawValue, forKey: "fan.profile")
            defaults.set(true, forKey: "fan.forcedActive")

            _ = SMCHelper.setFanMode(forced: true)
            for fan in temperatureCollector.collect().fans where fan.maxRPM > 0 {
                if let target = FanProfile.performance.targetRPM(minRPM: fan.minRPM, maxRPM: fan.maxRPM) {
                    _ = SMCHelper.setFanMinRPM(index: fan.index, rpm: target)
                }
            }

            alertManager.sendFanNotification(
                title: "Fan Speed Increased",
                body: "Thermal pressure detected — switched to Performance profile."
            )
        } else if thermalOverrideActive &&
                    (thermalLevel == .nominal || thermalLevel == .fair) {
            let restoreProfile = preThermalProfile ?? .auto
            defaults.set(restoreProfile.rawValue, forKey: "fan.profile")

            if restoreProfile == .auto {
                _ = SMCHelper.setFanMode(forced: false)
                defaults.set(false, forKey: "fan.forcedActive")
            } else {
                _ = SMCHelper.setFanMode(forced: true)
                for fan in temperatureCollector.collect().fans where fan.maxRPM > 0 {
                    if let target = restoreProfile.targetRPM(minRPM: fan.minRPM, maxRPM: fan.maxRPM) {
                        _ = SMCHelper.setFanMinRPM(index: fan.index, rpm: target)
                    }
                }
            }

            thermalOverrideActive = false
            preThermalProfile = nil

            alertManager.sendFanNotification(
                title: "Fan Speed Restored",
                body: "Thermal pressure resolved — reverted to \(restoreProfile.rawValue) profile."
            )
        }
    }
}
