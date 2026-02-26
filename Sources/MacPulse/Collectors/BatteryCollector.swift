import Foundation
import IOKit.ps

public struct BatteryCollector: MetricsCollector {
    public init() {}

    public func collect() -> BatteryMetrics {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [Any],
              let first = sources.first
        else {
            return .unavailable
        }

        guard let info = IOPSGetPowerSourceDescription(snapshot, first as CFTypeRef)?.takeUnretainedValue() as? [String: Any] else {
            return .unavailable
        }

        let currentCapacity = info[kIOPSCurrentCapacityKey] as? Int ?? 0
        let maxCapacity = info[kIOPSMaxCapacityKey] as? Int ?? 100
        let isCharging = info[kIOPSIsChargingKey] as? Bool ?? false
        let powerSource = info[kIOPSPowerSourceStateKey] as? String ?? "Unknown"

        let chargePercent = maxCapacity > 0 ? Double(currentCapacity) / Double(maxCapacity) : 0
        let timeRemaining = info[kIOPSTimeToEmptyKey] as? Int

        let cycleCount = getBatteryCycleCount()
        let health = getDesignCapacityHealth()

        return BatteryMetrics(
            isPresent: true,
            chargePercent: chargePercent,
            isCharging: isCharging,
            cycleCount: cycleCount,
            health: health,
            powerSource: powerSource == kIOPSACPowerValue ? "AC Power" : "Battery",
            timeRemaining: timeRemaining
        )
    }

    private func getBatteryCycleCount() -> Int {
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("AppleSmartBattery")
        )
        guard service != IO_OBJECT_NULL else { return 0 }
        defer { IOObjectRelease(service) }

        let prop = IORegistryEntryCreateCFProperty(
            service, "CycleCount" as CFString, kCFAllocatorDefault, 0
        )
        return prop?.takeRetainedValue() as? Int ?? 0
    }

    private func getDesignCapacityHealth() -> Double {
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("AppleSmartBattery")
        )
        guard service != IO_OBJECT_NULL else { return 0 }
        defer { IOObjectRelease(service) }

        let maxProp = IORegistryEntryCreateCFProperty(
            service, "MaxCapacity" as CFString, kCFAllocatorDefault, 0
        )
        let designProp = IORegistryEntryCreateCFProperty(
            service, "DesignCapacity" as CFString, kCFAllocatorDefault, 0
        )

        let max = maxProp?.takeRetainedValue() as? Double ?? 0
        let design = designProp?.takeRetainedValue() as? Double ?? 1

        return design > 0 ? max / design : 0
    }
}
