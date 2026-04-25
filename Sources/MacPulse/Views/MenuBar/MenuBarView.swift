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
                    .foregroundStyle(ZuroxiaTheme.cyan)
                    .cyberGlow(color: ZuroxiaTheme.cyan)
                Text("ZUROXIA MACPULSE")
                    .font(ZuroxiaTheme.font(12, weight: .bold))
                    .tracking(2.0)
                    .foregroundStyle(ZuroxiaTheme.textPrimary)
                Spacer()
                if monitor.isReady {
                    Text(monitor.currentSnapshot.thermal.level.rawValue.uppercased())
                        .font(ZuroxiaTheme.font(9, weight: .bold))
                        .tracking(1.5)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            monitor.currentSnapshot.thermal.level.color.opacity(0.15),
                            in: Capsule()
                        )
                        .foregroundStyle(monitor.currentSnapshot.thermal.level.color)
                }
            }
            .padding(.bottom, 12)

            if !monitor.isReady {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                        .tint(ZuroxiaTheme.cyan)
                    Text("ESTABLISHING UPLINK...")
                        .font(ZuroxiaTheme.font(10, weight: .medium))
                        .tracking(1.5)
                        .foregroundStyle(ZuroxiaTheme.textMuted)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 16)
            } else {
                // Stats
                VStack(spacing: 8) {
                    QuickStatRow(
                        icon: "cpu",
                        label: "CPU",
                        value: FormatHelpers.percent(monitor.currentSnapshot.cpu.totalUsage),
                        color: ZuroxiaTheme.cyan,
                        sparklineData: recentValues(from: monitor.history.cpuHistory)
                    )

                    QuickStatRow(
                        icon: "memorychip",
                        label: "MEMORY",
                        value: FormatHelpers.percent(monitor.currentSnapshot.memory.usedFraction),
                        color: ZuroxiaTheme.purple,
                        sparklineData: recentValues(from: monitor.history.memoryHistory)
                    )

                    QuickStatRow(
                        icon: "arrow.up.arrow.down",
                        label: "NETWORK",
                        value: "\u{2191}\(FormatHelpers.bytesPerSecond(monitor.currentSnapshot.network.totalSendRate))  \u{2193}\(FormatHelpers.bytesPerSecond(monitor.currentSnapshot.network.totalReceiveRate))",
                        color: ZuroxiaTheme.emerald
                    )

                    if monitor.currentSnapshot.battery.isPresent {
                        QuickStatRow(
                            icon: monitor.currentSnapshot.battery.isCharging ? "bolt.fill" : "battery.75",
                            label: "POWER",
                            value: FormatHelpers.percentInt(monitor.currentSnapshot.battery.chargePercent),
                            color: monitor.currentSnapshot.battery.isCharging ? ZuroxiaTheme.emerald : ZuroxiaTheme.textMuted,
                            sparklineData: recentValues(from: monitor.history.batteryHistory)
                        )
                    }
                }
            }

            Divider()
                .background(ZuroxiaTheme.borderFaint)
                .padding(.vertical, 12)

            // Actions
            VStack(spacing: 4) {
                Button {
                    dismiss()
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "detail")
                } label: {
                    HStack {
                        Image(systemName: "macwindow")
                            .frame(width: 16)
                            .foregroundStyle(ZuroxiaTheme.textSecondary)
                        Text("OPEN CONTROL DECK")
                            .font(ZuroxiaTheme.font(10, weight: .bold))
                            .tracking(1.5)
                        Spacer()
                        Text("\u{2318}D")
                            .font(ZuroxiaTheme.font(10, weight: .medium))
                            .foregroundStyle(ZuroxiaTheme.textMuted)
                    }
                }
                .keyboardShortcut("d")
                .buttonStyle(.plain)
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(Color.white.opacity(0.001)) // For hit testing

                Button {
                    dismiss()
                    NSApp.activate(ignoringOtherApps: true)
                    appState.selectedTab = .settings
                    openWindow(id: "detail")
                } label: {
                    HStack {
                        Image(systemName: "gearshape")
                            .frame(width: 16)
                            .foregroundStyle(ZuroxiaTheme.textSecondary)
                        Text("CONFIG MATRIX")
                            .font(ZuroxiaTheme.font(10, weight: .bold))
                            .tracking(1.5)
                        Spacer()
                        Text("\u{2318},")
                            .font(ZuroxiaTheme.font(10, weight: .medium))
                            .foregroundStyle(ZuroxiaTheme.textMuted)
                    }
                }
                .keyboardShortcut(",")
                .buttonStyle(.plain)
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(Color.white.opacity(0.001))

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    HStack {
                        Image(systemName: "power")
                            .frame(width: 16)
                            .foregroundStyle(ZuroxiaTheme.crimson)
                        Text("DISCONNECT")
                            .font(ZuroxiaTheme.font(10, weight: .bold))
                            .tracking(1.5)
                            .foregroundStyle(ZuroxiaTheme.crimson)
                        Spacer()
                        Text("\u{2318}Q")
                            .font(ZuroxiaTheme.font(10, weight: .medium))
                            .foregroundStyle(ZuroxiaTheme.textMuted)
                    }
                }
                .keyboardShortcut("q")
                .buttonStyle(.plain)
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(Color.white.opacity(0.001))
            }
        }
        .padding(16)
        .frame(width: 320)
        .background(ZuroxiaTheme.bgDark)
        .preferredColorScheme(.dark)
        .onAppear {
            monitor.start()
        }
    }

    private func recentValues(from history: [(Date, Double)]) -> [Double] {
        Array(history.suffix(30).map(\.1))
    }
}
