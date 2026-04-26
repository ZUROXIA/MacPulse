import Foundation

public struct DiskCollector: MetricsCollector {
    public init() {}

    public func collect() -> DiskMetrics {
        let fm = FileManager.default
        guard let urls = fm.mountedVolumeURLs(
            includingResourceValuesForKeys: [.volumeNameKey, .volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey, .volumeAvailableCapacityKey],
            options: [.skipHiddenVolumes]
        ) else {
            return .zero
        }

        var volumes: [VolumeInfo] = []

        for url in urls {
            guard let values = try? url.resourceValues(forKeys: [
                .volumeNameKey,
                .volumeTotalCapacityKey,
                .volumeAvailableCapacityForImportantUsageKey,
                .volumeAvailableCapacityKey
            ]) else { continue }

            let name = values.volumeName ?? url.lastPathComponent
            let total = UInt64(values.volumeTotalCapacity ?? 0)
            
            var free: UInt64 = 0
            if let importantFree = values.volumeAvailableCapacityForImportantUsage, importantFree > 0 {
                free = UInt64(importantFree)
            } else if let regularFree = values.volumeAvailableCapacity, regularFree > 0 {
                free = UInt64(regularFree)
            }

            guard total > 0 else { continue }

            volumes.append(VolumeInfo(
                name: name,
                mountPoint: url.path,
                totalBytes: total,
                freeBytes: free
            ))
        }

        return DiskMetrics(volumes: volumes)
    }
}
