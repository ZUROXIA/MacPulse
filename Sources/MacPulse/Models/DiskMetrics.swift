import Foundation

public struct VolumeInfo: Sendable, Identifiable {
    public var id: String { mountPoint }
    public var name: String
    public var mountPoint: String
    public var totalBytes: UInt64
    public var freeBytes: UInt64

    public var usedBytes: UInt64 { totalBytes > freeBytes ? totalBytes - freeBytes : 0 }
    public var usedFraction: Double {
        totalBytes > 0 ? Double(usedBytes) / Double(totalBytes) : 0
    }

    public init(name: String, mountPoint: String, totalBytes: UInt64, freeBytes: UInt64) {
        self.name = name
        self.mountPoint = mountPoint
        self.totalBytes = totalBytes
        self.freeBytes = freeBytes
    }
}

public struct DiskMetrics: Sendable {
    public var volumes: [VolumeInfo]

    public static let zero = DiskMetrics(volumes: [])

    public init(volumes: [VolumeInfo]) {
        self.volumes = volumes
    }
}
