import Foundation
import IOKit

public struct GPUCollector: MetricsCollector {
    private var cachedResult: GPUMetrics = .empty
    private var sampleCounter = 0
    /// Only collect every Nth call (IOKit registry traversal is expensive).
    private let collectEvery = 5

    public init() {}

    public mutating func collect() -> GPUMetrics {
        sampleCounter += 1
        if sampleCounter < collectEvery && !cachedResult.gpus.isEmpty {
            return cachedResult
        }
        sampleCounter = 0

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

            let name: String
            if let model = dict["model"] as? Data {
                name = String(data: model, encoding: .utf8)?.trimmingCharacters(in: .controlCharacters) ?? "GPU"
            } else {
                name = (dict["IOClass"] as? String) ?? "GPU"
            }

            var utilization: Double? = nil
            var vramUsed: UInt64? = nil
            var vramTotal: UInt64? = nil

            if let perfStats = dict["PerformanceStatistics"] as? [String: Any] {
                if let util = perfStats["Device Utilization %"] as? Int {
                    utilization = Double(util) / 100.0
                } else if let util = perfStats["GPU Activity(%)"] as? Int {
                    utilization = Double(util) / 100.0
                }

                if let used = perfStats["vramUsedBytes"] as? UInt64 {
                    vramUsed = used
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

        cachedResult = GPUMetrics(gpus: gpus)
        return cachedResult
    }
}
