import Foundation

public struct MemoryCollector: MetricsCollector {
    public init() {}

    public func collect() -> MemoryMetrics {
        guard let stats = MachHelpers.vmStatistics64() else {
            return .zero
        }

        let pageSize = MachHelpers.pageSize
        let total = MachHelpers.physicalMemory

        let free = UInt64(stats.free_count) * pageSize
        let active = UInt64(stats.active_count) * pageSize
        let wired = UInt64(stats.wire_count) * pageSize
        let compressed = UInt64(stats.compressor_page_count) * pageSize
        let used = active + wired + compressed

        return MemoryMetrics(
            total: total,
            used: used,
            free: free,
            active: active,
            wired: wired,
            compressed: compressed
        )
    }
}
