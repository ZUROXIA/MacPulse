import Foundation
import SwiftUI

public enum ThermalLevel: String, Sendable, CaseIterable {
    case nominal = "Nominal"
    case fair = "Fair"
    case serious = "Serious"
    case critical = "Critical"

    public var description: String {
        switch self {
        case .nominal: "System is running normally"
        case .fair: "Slightly elevated thermal state"
        case .serious: "System is under thermal pressure"
        case .critical: "Critical thermal state — throttling active"
        }
    }

    public var color: Color {
        switch self {
        case .nominal: .green
        case .fair: .yellow
        case .serious: .orange
        case .critical: .red
        }
    }

    public var icon: String {
        switch self {
        case .nominal: "thermometer.low"
        case .fair: "thermometer.medium"
        case .serious: "thermometer.high"
        case .critical: "thermometer.sun.fill"
        }
    }

    public init(from state: ProcessInfo.ThermalState) {
        switch state {
        case .nominal: self = .nominal
        case .fair: self = .fair
        case .serious: self = .serious
        case .critical: self = .critical
        @unknown default: self = .nominal
        }
    }
}

public struct ThermalMetrics: Sendable {
    public var level: ThermalLevel

    public static let nominal = ThermalMetrics(level: .nominal)

    public init(level: ThermalLevel) {
        self.level = level
    }
}
