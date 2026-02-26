import Foundation
import IOKit

public struct GPUCollector: MetricsCollector {
    public init() {}

    public func collect() -> GPUMetrics {
        var gpus: [GPUInfo] = []

        let matching = IOServiceMatching("IOAccelerator") as NSMutableDictionary
        var iterator: io_iterator_t = 0

        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return .empty
        }
        defer { IOObjectRelease(iterator) }

        var entry: io_object_t = IOIteratorNext(iterator)
        while entry != IO_OBJECT_NULL {
            defer {
                IOObjectRelease(entry)
                entry = IOIteratorNext(iterator)
            }

            var props: Unmanaged<CFMutableDictionary>?
            guard IORegistryEntryCreateCFProperties(entry, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
                  let dict = props?.takeRetainedValue() as? [String: Any] else {
                continue
            }

            // Get GPU name from IOClass or model property
            let name: String
            if let model = dict["model"] as? Data {
                name = String(data: model, encoding: .utf8)?.trimmingCharacters(in: .controlCharacters) ?? "GPU"
            } else {
                name = (dict["IOClass"] as? String) ?? "GPU"
            }

            // Read performance statistics
            var utilization: Double? = nil
            var vramUsed: UInt64? = nil
            var vramTotal: UInt64? = nil

            if let perfStats = dict["PerformanceStatistics"] as? [String: Any] {
                // Device Utilization % is reported by many GPU drivers
                if let util = perfStats["Device Utilization %"] as? Int {
                    utilization = Double(util) / 100.0
                } else if let util = perfStats["GPU Activity(%)"] as? Int {
                    utilization = Double(util) / 100.0
                }

                if let used = perfStats["vramUsedBytes"] as? UInt64 {
                    vramUsed = used
                } else if let used = perfStats["VRAM,totalMB"] as? Int {
                    // Some drivers report differently
                    vramTotal = UInt64(used) * 1024 * 1024
                }

                if let total = perfStats["VRAM,totalMB"] as? Int {
                    vramTotal = UInt64(total) * 1024 * 1024
                }
            }

            gpus.append(GPUInfo(
                name: name,
                utilization: utilization,
                vramUsed: vramUsed,
                vramTotal: vramTotal
            ))
        }

        return GPUMetrics(gpus: gpus)
    }
}
