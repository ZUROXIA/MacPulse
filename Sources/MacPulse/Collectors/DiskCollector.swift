import Foundation

public struct DiskCollector: MetricsCollector {
    public init() {}

    public func collect() -> DiskMetrics {
        let fm = FileManager.default
        guard let urls = fm.mountedVolumeURLs(
            includingResourceValuesForKeys: [.volumeNameKey, .volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey],
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
            ]) else { continue }

            let name = values.volumeName ?? url.lastPathComponent
            let total = UInt64(values.volumeTotalCapacity ?? 0)
            let free = UInt64(values.volumeAvailableCapacityForImportantUsage ?? 0)

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
