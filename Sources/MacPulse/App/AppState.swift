import SwiftUI

@Observable
public final class AppState {
    public var selectedTab: DetailTab = .cpu
    public var showDetailWindow = false

    public init() {}

    public enum DetailTab: String, CaseIterable, Identifiable {
        case cpu = "CPU"
        case gpu = "GPU"
        case memory = "Memory"
        case disk = "Disk"
        case battery = "Battery"
        case network = "Network"
        case thermal = "Thermal"
        case fans = "Fans"
        case processes = "Processes"
        case optimize = "Optimize"
        case settings = "Settings"

        public var id: String { rawValue }

        public var icon: String {
            switch self {
            case .cpu: "cpu"
            case .gpu: "gpu"
            case .memory: "memorychip"
            case .disk: "internaldrive"
            case .battery: "battery.100"
            case .network: "network"
            case .thermal: "thermometer.medium"
            case .fans: "fan.fill"
            case .processes: "list.number"
            case .optimize: "wand.and.stars"
            case .settings: "gearshape"
            }
        }
    }
}
