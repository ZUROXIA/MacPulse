import SwiftUI

public struct MenuBarView: View {
    public let monitor: SystemMonitor
    public let appState: AppState

    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismiss) private var dismiss

    public init(monitor: SystemMonitor, appState: AppState) {
        self.monitor = monitor
        self.appState = appState
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title bar
            HStack {
                Image(systemName: "gauge.medium")
                    .foregroundStyle(.blue)
                Text("MacPulse")
                    .font(.headline)
                Spacer()
                if monitor.isReady {
                    Text(monitor.currentSnapshot.thermal.level.rawValue)
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            monitor.currentSnapshot.thermal.level.color.opacity(0.15),
                            in: Capsule()
                        )
                        .foregroundStyle(monitor.currentSnapshot.thermal.level.color)
                }
            }
            .padding(.bottom, 8)

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

            Divider()
                .padding(.vertical, 4)

            // Stats
            VStack(spacing: 6) {
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
                    color: .teal
                )

                if monitor.currentSnapshot.battery.isPresent {
                    QuickStatRow(
                        icon: monitor.currentSnapshot.battery.isCharging ? "battery.100.bolt" : "battery.75",
                        label: "Battery",
                        value: FormatHelpers.percentInt(monitor.currentSnapshot.battery.chargePercent),
                        color: .green,
                        sparklineData: recentValues(from: monitor.history.batteryHistory)
                    )
                }
            }

            Divider()
                .padding(.vertical, 4)

            // Actions
            VStack(spacing: 2) {
                Button {
                    dismiss()
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "detail")
                } label: {
                    HStack {
                        Image(systemName: "macwindow")
                            .frame(width: 16)
                        Text("Open MacPulse")
                        Spacer()
                        Text("\u{2318}D")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .keyboardShortcut("d")
                .buttonStyle(.plain)
                .padding(.vertical, 4)

                Button {
                    dismiss()
                    NSApp.activate(ignoringOtherApps: true)
                    appState.selectedTab = .settings
                    openWindow(id: "detail")
                } label: {
                    HStack {
                        Image(systemName: "gearshape")
                            .frame(width: 16)
                        Text("Settings")
                        Spacer()
                        Text("\u{2318},")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .keyboardShortcut(",")
                .buttonStyle(.plain)
                .padding(.vertical, 4)

                Divider()
                    .padding(.vertical, 2)

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    HStack {
                        Image(systemName: "power")
                            .frame(width: 16)
                        Text("Quit MacPulse")
                        Spacer()
                        Text("\u{2318}Q")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .keyboardShortcut("q")
                .buttonStyle(.plain)
                .padding(.vertical, 4)
            }
        }
        .padding(12)
        .frame(width: 300)
        .onAppear {
            monitor.start()
        }
    }

    private func recentValues(from history: [(Date, Double)]) -> [Double] {
        Array(history.suffix(30).map(\.1))
    }
}
