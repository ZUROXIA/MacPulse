import Foundation

public struct InterfaceTraffic: Sendable, Identifiable {
    public var id: String { name }
    public var name: String
    public var bytesSent: UInt64
    public var bytesReceived: UInt64
    public var sendRate: Double
    public var receiveRate: Double

    public init(name: String, bytesSent: UInt64, bytesReceived: UInt64, sendRate: Double, receiveRate: Double) {
        self.name = name
        self.bytesSent = bytesSent
        self.bytesReceived = bytesReceived
        self.sendRate = sendRate
        self.receiveRate = receiveRate
    }
}

public struct ProcessNetworkUsage: Sendable, Identifiable {
    public var id: Int32 { pid }
    public var pid: Int32
    public var name: String
    public var bytesSent: UInt64
    public var bytesReceived: UInt64

    public init(pid: Int32, name: String, bytesSent: UInt64, bytesReceived: UInt64) {
        self.pid = pid
        self.name = name
        self.bytesSent = bytesSent
        self.bytesReceived = bytesReceived
    }
}

public struct NetworkMetrics: Sendable {
    public var interfaces: [InterfaceTraffic]
    public var totalSendRate: Double
    public var totalReceiveRate: Double
    public var topProcesses: [ProcessNetworkUsage]

    public static let zero = NetworkMetrics(interfaces: [], totalSendRate: 0, totalReceiveRate: 0, topProcesses: [])

    public init(interfaces: [InterfaceTraffic], totalSendRate: Double, totalReceiveRate: Double, topProcesses: [ProcessNetworkUsage] = []) {
        self.interfaces = interfaces
        self.totalSendRate = totalSendRate
        self.totalReceiveRate = totalReceiveRate
        self.topProcesses = topProcesses
    }
}
