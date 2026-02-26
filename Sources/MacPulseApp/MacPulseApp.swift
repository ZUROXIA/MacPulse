import SwiftUI
import MacPulseCore

@main
struct MacPulseApp: App {
    @State private var monitor = SystemMonitor()
    @State private var appState = AppState()
    @State private var settings = AppSettings()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(monitor: monitor, appState: appState)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "gauge.medium")
                if monitor.isReady {
                    if settings.showCPUInMenuBar {
                        Text(FormatHelpers.percentInt(monitor.currentSnapshot.cpu.totalUsage))
                            .monospacedDigit()
                    }
                    if settings.showMemoryInMenuBar {
                        Text("M:" + FormatHelpers.percentInt(monitor.currentSnapshot.memory.usedFraction))
                            .monospacedDigit()
                    }
                    if settings.showNetworkInMenuBar {
                        Text("\u{2191}\(FormatHelpers.bytesPerSecond(monitor.currentSnapshot.network.totalSendRate))")
                            .monospacedDigit()
                    }
                }
            }
        }
        .menuBarExtraStyle(.window)

        Window("MacPulse — System Monitor", id: "detail") {
            DetailWindow(monitor: monitor, appState: appState)
                .frame(minWidth: 700, minHeight: 500)
        }
        .defaultSize(width: 800, height: 600)

        Settings {
            SettingsView(monitor: monitor, settings: settings)
                .frame(width: 400, height: 300)
        }
    }

    init() {
        _monitor = State(initialValue: SystemMonitor())
        _appState = State(initialValue: AppState())
        _settings = State(initialValue: AppSettings())
    }
}
