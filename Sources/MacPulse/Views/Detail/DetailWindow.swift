import SwiftUI

public struct DetailWindow: View {
    public let monitor: SystemMonitor
    @Bindable public var appState: AppState

    public init(monitor: SystemMonitor, appState: AppState) {
        self.monitor = monitor
        self.appState = appState
    }

    public var body: some View {
        NavigationSplitView {
            List(AppState.DetailTab.allCases, selection: $appState.selectedTab) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
                    .tag(tab)
            }
            .navigationSplitViewColumnWidth(min: 150, ideal: 180)
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
                case .processes:
                    ProcessListView(monitor: monitor)
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
            ToolbarItem(placement: .primaryAction) {
                Button {
                    CSVExporter.saveWithPanel(history: monitor.history)
                } label: {
                    Label("Export CSV", systemImage: "square.and.arrow.up")
                }
                .help("Export metrics history to CSV")
            }
        }
    }
}
