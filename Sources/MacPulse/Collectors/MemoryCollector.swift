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

        // Compute memory pressure based on compressed ratio and free memory
        let pressure = computePressure(
            compressed: compressed,
            used: used,
            total: total,
            free: free
        )

        return MemoryMetrics(
            total: total,
            used: used,
            free: free,
            active: active,
            wired: wired,
            compressed: compressed,
            pressureLevel: pressure
        )
    }

    private func computePressure(compressed: UInt64, used: UInt64, total: UInt64, free: UInt64) -> MemoryPressureLevel {
        guard total > 0 else { return .normal }
        let usedFraction = Double(used) / Double(total)
        let compressedFraction = Double(compressed) / Double(total)

        // Critical: >90% used with significant compression
        if usedFraction > 0.9 && compressedFraction > 0.15 {
            return .critical
        }
        // Warning: >80% used with moderate compression, or >95% used
        if (usedFraction > 0.8 && compressedFraction > 0.05) || usedFraction > 0.95 {
            return .warning
        }
        return .normal
    }
}
