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
        .network: "6", .defense: "7", .thermal: "8", .fans: "9", .processes: "0", .optimize: "-",
    ]

    public var body: some View {
        NavigationSplitView {
            List(selection: $appState.selectedTab) {
                ForEach(AppState.DetailTab.grouped, id: \.0) { section, tabs in
                    Section {
                        ForEach(tabs) { tab in
                            Label {
                                Text(tab.rawValue.uppercased())
                                    .font(ZuroxiaTheme.font(11, weight: .medium))
                                    .tracking(2.0)
                            } icon: {
                                Image(systemName: tab.icon)
                                    .foregroundStyle(appState.selectedTab == tab ? ZuroxiaTheme.cyan : tab.color)
                                    .cyberGlow(color: appState.selectedTab == tab ? ZuroxiaTheme.cyan : .clear)
                            }
                            .tag(tab)
                        }
                    } header: {
                        Text(section.rawValue.uppercased())
                            .font(ZuroxiaTheme.font(9, weight: .bold))
                            .tracking(3.0)
                            .foregroundStyle(ZuroxiaTheme.textMuted)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(ZuroxiaTheme.bgPanel)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
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
                case .defense:
                    DefenseDetailView(monitor: monitor)
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
            .background(ZuroxiaTheme.bgDark)
        }
        .applyZuroxiaEnvironment()
        .toolbar {
            ToolbarItem(placement: .status) {
                HStack(spacing: 12) {
                    // CPU pill
                    HStack(spacing: 6) {
                        Image(systemName: "cpu")
                            .font(.caption2)
                            .foregroundStyle(ZuroxiaTheme.cyan)
                        Text(FormatHelpers.percentInt(monitor.currentSnapshot.cpu.totalUsage))
                            .font(ZuroxiaTheme.font(10, weight: .bold))
                            .foregroundStyle(ZuroxiaTheme.cyan)
                            .contentTransition(.numericText())
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(ZuroxiaTheme.cyan.opacity(0.1), in: Capsule())
                    .overlay(Capsule().stroke(ZuroxiaTheme.cyan.opacity(0.3), lineWidth: 1))

                    // Thermal pill
                    HStack(spacing: 6) {
                        Image(systemName: monitor.currentSnapshot.thermal.level.icon)
                            .font(.caption2)
                            .foregroundStyle(monitor.currentSnapshot.thermal.level.color)
                        Text(monitor.currentSnapshot.thermal.level.rawValue.uppercased())
                            .font(ZuroxiaTheme.font(10, weight: .bold))
                            .tracking(1.0)
                            .foregroundStyle(monitor.currentSnapshot.thermal.level.color)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        monitor.currentSnapshot.thermal.level.color.opacity(0.1),
                        in: Capsule()
                    )
                    .overlay(Capsule().stroke(monitor.currentSnapshot.thermal.level.color.opacity(0.3), lineWidth: 1))
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    CSVExporter.saveWithPanel(history: monitor.history)
                } label: {
                    Label("Export CSV", systemImage: "square.and.arrow.down")
                }
                .help("Export telemetry to CSV")
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
