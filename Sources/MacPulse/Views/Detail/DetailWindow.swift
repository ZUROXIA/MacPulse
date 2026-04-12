import SwiftUI

public struct DetailWindow: View {
    public let monitor: SystemMonitor
    @Bindable public var appState: AppState

    public init(monitor: SystemMonitor, appState: AppState) {
        self.monitor = monitor
        self.appState = appState
    }

    private static let tabShortcuts: [AppState.DetailTab: KeyEquivalent] = [
        .cpu: "1", .gpu: "2", .memory: "3", .disk: "4", .battery: "5",
        .network: "6", .thermal: "7", .fans: "8", .processes: "9", .optimize: "0",
    ]

    public var body: some View {
        NavigationSplitView {
            List(selection: $appState.selectedTab) {
                ForEach(AppState.DetailTab.grouped, id: \.0) { section, tabs in
                    Section(section.rawValue) {
                        ForEach(tabs) { tab in
                            Label {
                                Text(tab.rawValue)
                            } icon: {
                                Image(systemName: tab.icon)
                                    .foregroundStyle(tab.color)
                            }
                            .tag(tab)
                        }
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 190)
        } detail: {
            Group {
                switch appState.selectedTab {
                case .cpu:
                    CPUDetailView(monitor: monitor)
                case .gpu:
                    GPUDetailView(monitor: monitor)
                case .memory:
                    MemoryDetailView(monitor: monitor)
                case .disk:
                    DiskDetailView(monitor: monitor)
                case .battery:
                    BatteryDetailView(monitor: monitor)
                case .network:
                    NetworkDetailView(monitor: monitor)
                case .thermal:
                    ThermalDetailView(monitor: monitor)
                case .fans:
                    FanControlView(monitor: monitor)
                case .processes:
                    ProcessListView(monitor: monitor)
                case .optimize:
                    OptimizeView(monitor: monitor)
                case .settings:
                    SettingsView(monitor: monitor)
                }
            }
            .id(appState.selectedTab)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.2), value: appState.selectedTab)
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .status) {
                HStack(spacing: 12) {
                    // CPU pill
                    HStack(spacing: 4) {
                        Image(systemName: "cpu")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(FormatHelpers.percentInt(monitor.currentSnapshot.cpu.totalUsage))
                            .font(.caption.monospacedDigit().weight(.medium))
                            .contentTransition(.numericText())
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary.opacity(0.5), in: Capsule())

                    // Thermal pill
                    HStack(spacing: 4) {
                        Image(systemName: monitor.currentSnapshot.thermal.level.icon)
                            .font(.caption2)
                        Text(monitor.currentSnapshot.thermal.level.rawValue)
                            .font(.caption.weight(.medium))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        monitor.currentSnapshot.thermal.level.color.opacity(0.15),
                        in: Capsule()
                    )
                    .foregroundStyle(monitor.currentSnapshot.thermal.level.color)
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    CSVExporter.saveWithPanel(history: monitor.history)
                } label: {
                    Label("Export CSV", systemImage: "square.and.arrow.up")
                }
                .help("Export metrics history to CSV")
            }
        }
        // Keyboard shortcuts for tab switching
        .background {
            ForEach(Array(Self.tabShortcuts), id: \.key) { tab, key in
                Button("") { appState.selectedTab = tab }
                    .keyboardShortcut(key, modifiers: .command)
                    .hidden()
            }
        }
    }
}
