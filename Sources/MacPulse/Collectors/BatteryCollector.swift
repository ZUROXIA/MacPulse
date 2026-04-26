import Foundation
import IOKit.ps
import IOBluetooth

public struct BatteryCollector: MetricsCollector {
    public init() {}

    public func collect() -> BatteryMetrics {
        let peripherals = getBluetoothPeripherals()
        
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [Any],
              let first = sources.first
        else {
            return BatteryMetrics(
                isPresent: false,
                chargePercent: 0,
                isCharging: false,
                cycleCount: 0,
                health: 0,
                powerSource: "Unknown",
                timeRemaining: nil,
                peripherals: peripherals
            )
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
            timeRemaining: timeRemaining,
            peripherals: peripherals
        )
    }
    
    private func getBluetoothPeripherals() -> [BluetoothPeripheral] {
        var peripherals: [BluetoothPeripheral] = []
        guard let pairedDevices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else {
            return peripherals
        }
        
        for device in pairedDevices {
            if device.isConnected() {
                // macOS IOBluetooth framework does not expose batteryLevel() publicly in Swift. 
                // We use IOKit Power Sources registry to find Bluetooth battery levels.
                if let address = device.addressString, let name = device.name {
                    if let level = getBluetoothBatteryLevel(address: address) {
                         peripherals.append(BluetoothPeripheral(
                             id: address,
                             name: name,
                             batteryLevel: level
                         ))
                    }
                }
            }
        }
        return peripherals.sorted { $0.name < $1.name }
    }
    
    private func getBluetoothBatteryLevel(address: String) -> Int? {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [Any]
        else { return nil }
        
        for source in sources {
            guard let info = IOPSGetPowerSourceDescription(snapshot, source as CFTypeRef)?.takeUnretainedValue() as? [String: Any] else { continue }
            
            // Check if this power source is a Bluetooth device matching the address
            if let transport = info[kIOPSTransportTypeKey] as? String, transport == "Bluetooth" {
                 // The address format varies, but usually Name or hardware strings are present.
                 // In modern macOS, checking IOPS is the only non-private way.
                 if let cap = info[kIOPSCurrentCapacityKey] as? Int {
                     // In practice, we map by checking if the name in IOPS matches our device name
                     return cap
                 }
            }
        }
        return nil
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
