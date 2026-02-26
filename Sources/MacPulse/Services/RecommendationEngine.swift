import Foundation

public struct Recommendation: Identifiable {
    public enum Severity: Int, Comparable {
        case info = 0
        case warning = 1
        case critical = 2

        public static func < (lhs: Severity, rhs: Severity) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    public let id = UUID()
    public let severity: Severity
    public let icon: String
    public let title: String
    public let detail: String
    public let actionLabel: String?
    public let action: (() -> Void)?

    public init(severity: Severity, icon: String, title: String, detail: String, actionLabel: String? = nil, action: (() -> Void)? = nil) {
        self.severity = severity
        self.icon = icon
        self.title = title
        self.detail = detail
        self.actionLabel = actionLabel
        self.action = action
    }
}

/// User-configurable thresholds for the recommendation engine.
public struct OptimizeThresholds {
    public var cpuWarning: Double
    public var cpuCritical: Double
    public var diskWarning: Double
    public var batteryWarning: Double
    public var enableMemory: Bool
    public var enableCPU: Bool
    public var enableDisk: Bool
    public var enableThermal: Bool
    public var enableBattery: Bool

    public static let defaults = OptimizeThresholds(
        cpuWarning: 0.8,
        cpuCritical: 0.95,
        diskWarning: 0.9,
        batteryWarning: 0.2,
        enableMemory: true,
        enableCPU: true,
        enableDisk: true,
        enableThermal: true,
        enableBattery: true
    )

    public init(
        cpuWarning: Double = 0.8,
        cpuCritical: Double = 0.95,
        diskWarning: Double = 0.9,
        batteryWarning: Double = 0.2,
        enableMemory: Bool = true,
        enableCPU: Bool = true,
        enableDisk: Bool = true,
        enableThermal: Bool = true,
        enableBattery: Bool = true
    ) {
        self.cpuWarning = cpuWarning
        self.cpuCritical = cpuCritical
        self.diskWarning = diskWarning
        self.batteryWarning = batteryWarning
        self.enableMemory = enableMemory
        self.enableCPU = enableCPU
        self.enableDisk = enableDisk
        self.enableThermal = enableThermal
        self.enableBattery = enableBattery
    }

    /// Convenience initializer from AppSettings.
    @MainActor
    public init(from settings: AppSettings) {
        self.cpuWarning = settings.cpuWarningThreshold
        self.cpuCritical = settings.cpuCriticalThreshold
        self.diskWarning = settings.diskWarningThreshold
        self.batteryWarning = settings.batteryWarningThreshold
        self.enableMemory = settings.enableMemoryRule
        self.enableCPU = settings.enableCPURule
        self.enableDisk = settings.enableDiskRule
        self.enableThermal = settings.enableThermalRule
        self.enableBattery = settings.enableBatteryRule
    }
}

public enum RecommendationEngine {
    /// Analyzes the current snapshot using default thresholds.
    public static func analyze(_ snapshot: SystemSnapshot) -> [Recommendation] {
        analyze(snapshot, thresholds: .defaults)
    }

    /// Analyzes the current snapshot using user-configured thresholds.
    public static func analyze(_ snapshot: SystemSnapshot, thresholds: OptimizeThresholds) -> [Recommendation] {
        var results: [Recommendation] = []

        if thresholds.enableMemory { analyzeMemory(snapshot, into: &results) }
        if thresholds.enableCPU { analyzeCPU(snapshot, thresholds: thresholds, into: &results) }
        if thresholds.enableDisk { analyzeDisk(snapshot, thresholds: thresholds, into: &results) }
        if thresholds.enableThermal { analyzeThermal(snapshot, into: &results) }
        if thresholds.enableBattery { analyzeBattery(snapshot, thresholds: thresholds, into: &results) }

        results.sort { $0.severity > $1.severity }
        return results
    }

    // MARK: - Rules

    private static func analyzeMemory(_ snapshot: SystemSnapshot, into results: inout [Recommendation]) {
        let mem = snapshot.memory
        let topMem = snapshot.processes.topByMemory.first

        switch mem.pressureLevel {
        case .critical:
            let detail: String
            if let proc = topMem {
                detail = "Memory pressure is critical. Top consumer: \(proc.name) (\(FormatHelpers.bytes(proc.memoryBytes))). Purging inactive memory may help."
            } else {
                detail = "Memory pressure is critical. Purging inactive memory may help."
            }
            results.append(Recommendation(
                severity: .critical,
                icon: "memorychip",
                title: "Critical Memory Pressure",
                detail: detail,
                actionLabel: "Purge Memory",
                action: { _ = ProcessHelper.purgeMemory() }
            ))

        case .warning:
            let detail: String
            if let proc = topMem {
                detail = "Memory pressure is elevated. Top consumer: \(proc.name) (\(FormatHelpers.bytes(proc.memoryBytes)))."
            } else {
                detail = "Memory pressure is elevated. Consider closing unused apps."
            }
            results.append(Recommendation(
                severity: .warning,
                icon: "memorychip",
                title: "Elevated Memory Pressure",
                detail: detail,
                actionLabel: "Purge Memory",
                action: { _ = ProcessHelper.purgeMemory() }
            ))

        case .normal:
            break
        }
    }

    private static func analyzeCPU(_ snapshot: SystemSnapshot, thresholds: OptimizeThresholds, into results: inout [Recommendation]) {
        guard snapshot.cpu.totalUsage > thresholds.cpuWarning else { return }
        let topCPU = snapshot.processes.topByCPU.first
        let severity: Recommendation.Severity = snapshot.cpu.totalUsage > thresholds.cpuCritical ? .critical : .warning
        let detail: String
        if let proc = topCPU {
            detail = "CPU usage is at \(FormatHelpers.percent(snapshot.cpu.totalUsage)). Top consumer: \(proc.name) (\(FormatHelpers.percent(proc.cpuUsage)))."
        } else {
            detail = "CPU usage is at \(FormatHelpers.percent(snapshot.cpu.totalUsage))."
        }
        results.append(Recommendation(
            severity: severity,
            icon: "cpu",
            title: "High CPU Usage",
            detail: detail
        ))
    }

    private static func analyzeDisk(_ snapshot: SystemSnapshot, thresholds: OptimizeThresholds, into results: inout [Recommendation]) {
        let criticalThreshold = thresholds.diskWarning + (1.0 - thresholds.diskWarning) / 2.0
        for volume in snapshot.disk.volumes {
            guard volume.usedFraction > thresholds.diskWarning else { continue }
            let severity: Recommendation.Severity = volume.usedFraction > criticalThreshold ? .critical : .warning
            results.append(Recommendation(
                severity: severity,
                icon: "internaldrive",
                title: "Low Disk Space",
                detail: "\(volume.name) is \(FormatHelpers.percentInt(volume.usedFraction)) full. Only \(FormatHelpers.bytes(volume.freeBytes)) remaining."
            ))
        }
    }

    private static func analyzeThermal(_ snapshot: SystemSnapshot, into results: inout [Recommendation]) {
        switch snapshot.thermal.level {
        case .critical:
            results.append(Recommendation(
                severity: .critical,
                icon: "thermometer.sun.fill",
                title: "Critical Thermal State",
                detail: "The system is throttling due to heat. Close GPU-heavy or CPU-intensive applications."
            ))
        case .serious:
            results.append(Recommendation(
                severity: .warning,
                icon: "thermometer.high",
                title: "System Running Hot",
                detail: "Thermal pressure is serious. Consider closing demanding applications."
            ))
        case .nominal, .fair:
            break
        }
    }

    private static func analyzeBattery(_ snapshot: SystemSnapshot, thresholds: OptimizeThresholds, into results: inout [Recommendation]) {
        let bat = snapshot.battery
        guard bat.isPresent, bat.chargePercent < thresholds.batteryWarning, !bat.isCharging else { return }
        let severity: Recommendation.Severity = bat.chargePercent < thresholds.batteryWarning / 2.0 ? .critical : .warning
        results.append(Recommendation(
            severity: severity,
            icon: "battery.25",
            title: "Low Battery",
            detail: "Battery is at \(FormatHelpers.percentInt(bat.chargePercent)) and not charging. Reduce brightness and close unused apps to extend battery life."
        ))
    }
}
