import Foundation
import Darwin

public struct NetworkCollector: MetricsCollector {
    private var previousCounters: [String: (sent: UInt64, received: UInt64)] = [:]
    private var previousTime: Date?

    public init() {}

    public mutating func collect() -> NetworkMetrics {
        let counters = readInterfaceCounters()
        let now = Date()

        defer {
            previousCounters = counters
            previousTime = now
        }

        guard let prevTime = previousTime else {
            return NetworkMetrics(interfaces: [], totalSendRate: 0, totalReceiveRate: 0)
        }

        let elapsed = now.timeIntervalSince(prevTime)
        guard elapsed > 0 else { return .zero }

        var interfaces: [InterfaceTraffic] = []
        var totalSend: Double = 0
        var totalRecv: Double = 0

        for (name, current) in counters {
            guard let prev = previousCounters[name] else { continue }

            let deltaSent = Self.counterDelta(current: current.sent, previous: prev.sent)
            let deltaRecv = Self.counterDelta(current: current.received, previous: prev.received)

            let sendRate = Double(deltaSent) / elapsed
            let recvRate = Double(deltaRecv) / elapsed

            interfaces.append(InterfaceTraffic(
                name: name,
                bytesSent: current.sent,
                bytesReceived: current.received,
                sendRate: sendRate,
                receiveRate: recvRate
            ))

            totalSend += sendRate
            totalRecv += recvRate
        }

        interfaces.sort { $0.name < $1.name }

        let topProcs = collectTopNetworkProcesses()

        return NetworkMetrics(
            interfaces: interfaces,
            totalSendRate: totalSend,
            totalReceiveRate: totalRecv,
            topProcesses: topProcs
        )
    }

    /// Compute delta between two counter values, handling 32-bit wraparound.
    /// ifi_obytes/ifi_ibytes are 32-bit counters that wrap at UInt32.max.
    /// Returns 0 if delta exceeds 10 GB/s (indicates counter reset, not wrap).
    private static func counterDelta(current: UInt64, previous: UInt64) -> UInt64 {
        let delta: UInt64
        if current >= previous {
            delta = current - previous
        } else {
            // 32-bit counter wraparound
            delta = (UInt64(UInt32.max) - previous) + current + 1
        }
        // Sanity cap: >10 GB/s is unrealistic, treat as counter reset
        let maxReasonableDelta: UInt64 = 10_000_000_000
        return delta > maxReasonableDelta ? 0 : delta
    }

    /// Per-process network bytes are not available through public macOS APIs.
    /// The NetworkStatistics private framework or a Network Extension would be needed.
    /// Returns empty array; the UI gracefully hides the section when empty.
    private func collectTopNetworkProcesses() -> [ProcessNetworkUsage] {
        return []
    }

    private func readInterfaceCounters() -> [String: (sent: UInt64, received: UInt64)] {
        var counters: [String: (sent: UInt64, received: UInt64)] = [:]
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return counters
        }

        defer { freeifaddrs(ifaddr) }

        var ptr: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let addr = ptr {
            let name = String(cString: addr.pointee.ifa_name)

            if addr.pointee.ifa_addr?.pointee.sa_family == UInt8(AF_LINK) {
                if let data = addr.pointee.ifa_data {
                    let networkData = data.assumingMemoryBound(to: if_data.self).pointee
                    let sent = UInt64(networkData.ifi_obytes)
                    let received = UInt64(networkData.ifi_ibytes)

                    if let existing = counters[name] {
                        counters[name] = (
                            sent: existing.sent + sent,
                            received: existing.received + received
                        )
                    } else {
                        counters[name] = (sent: sent, received: received)
                    }
                }
            }

            ptr = addr.pointee.ifa_next
        }

        return counters
    }
}
