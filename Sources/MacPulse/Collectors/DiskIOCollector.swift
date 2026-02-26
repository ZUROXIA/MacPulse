import Foundation
import IOKit

public struct DiskIOCollector: MetricsCollector {
    private var previousBytes: (read: UInt64, write: UInt64)?
    private var previousTime: Date?

    public init() {}

    public mutating func collect() -> DiskIOMetrics {
        let current = readIOCounters()
        let now = Date()

        defer {
            previousBytes = current
            previousTime = now
        }

        guard let prevBytes = previousBytes, let prevTime = previousTime else {
            return .zero
        }

        let elapsed = now.timeIntervalSince(prevTime)
        guard elapsed > 0 else { return .zero }

        let deltaRead = current.read >= prevBytes.read ? current.read - prevBytes.read : 0
        let deltaWrite = current.write >= prevBytes.write ? current.write - prevBytes.write : 0

        return DiskIOMetrics(
            readRate: Double(deltaRead) / elapsed,
            writeRate: Double(deltaWrite) / elapsed
        )
    }

    private func readIOCounters() -> (read: UInt64, write: UInt64) {
        var totalRead: UInt64 = 0
        var totalWrite: UInt64 = 0

        let matching = IOServiceMatching("IOBlockStorageDriver") as NSMutableDictionary
        var iterator: io_iterator_t = 0

        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return (0, 0)
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
                  let dict = props?.takeRetainedValue() as? [String: Any],
                  let stats = dict["Statistics"] as? [String: Any] else {
                continue
            }

            if let readBytes = stats["Bytes (Read)"] as? UInt64 {
                totalRead += readBytes
            }
            if let writeBytes = stats["Bytes (Write)"] as? UInt64 {
                totalWrite += writeBytes
            }
        }

        return (read: totalRead, write: totalWrite)
    }
}
