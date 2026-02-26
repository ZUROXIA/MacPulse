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

public struct NetworkMetrics: Sendable {
    public var interfaces: [InterfaceTraffic]
    public var totalSendRate: Double
    public var totalReceiveRate: Double

    public static let zero = NetworkMetrics(interfaces: [], totalSendRate: 0, totalReceiveRate: 0)

    public init(interfaces: [InterfaceTraffic], totalSendRate: Double, totalReceiveRate: Double) {
        self.interfaces = interfaces
        self.totalSendRate = totalSendRate
        self.totalReceiveRate = totalReceiveRate
    }
}
