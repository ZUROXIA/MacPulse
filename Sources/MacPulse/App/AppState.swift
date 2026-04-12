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

        public var color: Color {
            switch self {
            case .cpu: .blue
            case .gpu: .purple
            case .memory: .orange
            case .disk: .indigo
            case .battery: .green
            case .network: .teal
            case .thermal: .red
            case .fans: .cyan
            case .processes: .pink
            case .optimize: .mint
            case .settings: .gray
            }
        }

        public enum Section: String, CaseIterable {
            case hardware = "Hardware"
            case system = "System"
            case tools = "Tools"
        }

        public var section: Section {
            switch self {
            case .cpu, .gpu, .memory, .disk, .battery: .hardware
            case .network, .thermal, .fans, .processes: .system
            case .optimize, .settings: .tools
            }
        }

        public static var grouped: [(Section, [DetailTab])] {
            Section.allCases.map { section in
                (section, allCases.filter { $0.section == section })
            }
        }
    }
}
