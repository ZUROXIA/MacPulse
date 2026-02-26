import SwiftUI

public struct MenuBarView: View {
    public let monitor: SystemMonitor
    public let appState: AppState

    @Environment(\.openWindow) private var openWindow

    public init(monitor: SystemMonitor, appState: AppState) {
        self.monitor = monitor
        self.appState = appState
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MacPulse")
                .font(.headline)
                .padding(.bottom, 4)

            if !monitor.isReady {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("Collecting data...")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
            }

            QuickStatRow(
                icon: "cpu",
                label: "CPU",
                value: FormatHelpers.percent(monitor.currentSnapshot.cpu.totalUsage),
                color: .blue,
                sparklineData: recentValues(from: monitor.history.cpuHistory)
            )

            QuickStatRow(
                icon: "memorychip",
                label: "Memory",
                value: FormatHelpers.percent(monitor.currentSnapshot.memory.usedFraction),
                color: .orange,
                sparklineData: recentValues(from: monitor.history.memoryHistory)
            )

            QuickStatRow(
                icon: "arrow.up.arrow.down",
                label: "Network",
                value: "\u{2191}\(FormatHelpers.bytesPerSecond(monitor.currentSnapshot.network.totalSendRate))  \u{2193}\(FormatHelpers.bytesPerSecond(monitor.currentSnapshot.network.totalReceiveRate))",
                color: .green
            )

            if monitor.currentSnapshot.battery.isPresent {
                QuickStatRow(
                    icon: monitor.currentSnapshot.battery.isCharging ? "battery.100.bolt" : "battery.75",
                    label: "Battery",
                    value: FormatHelpers.percentInt(monitor.currentSnapshot.battery.chargePercent),
                    color: .yellow,
                    sparklineData: recentValues(from: monitor.history.batteryHistory)
                )
            }

            QuickStatRow(
                icon: "thermometer.medium",
                label: "Thermal",
                value: monitor.currentSnapshot.thermal.level.rawValue,
                color: monitor.currentSnapshot.thermal.level.color
            )

            Divider()

            Button("Show Details...") {
                openWindow(id: "detail")
            }
            .keyboardShortcut("d")

            Divider()

            Button("Settings...") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
            .keyboardShortcut(",")

            Button("Quit MacPulse") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(12)
        .frame(width: 300)
        .onAppear {
            monitor.start()
        }
    }

    /// Extract the last 30 values from a history array for the sparkline.
    private func recentValues(from history: [(Date, Double)]) -> [Double] {
        Array(history.suffix(30).map(\.1))
    }
}
