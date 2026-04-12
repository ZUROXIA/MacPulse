import SwiftUI

public struct BatteryDetailView: View {
    public let monitor: SystemMonitor

    private var battery: BatteryMetrics { monitor.currentSnapshot.battery }

    public init(monitor: SystemMonitor) {
        self.monitor = monitor
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if battery.isPresent {
                    // Header card
                    HStack(spacing: 30) {
                        GaugeView(
                            title: "Battery",
                            value: battery.chargePercent,
                            color: batteryColor
                        )

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Battery Status")
                                .font(.title2.bold())
                            Label(
                                battery.isCharging ? "Charging" : "On Battery",
                                systemImage: battery.isCharging ? "bolt.fill" : "battery.75"
                            )
                            .foregroundStyle(battery.isCharging ? .green : .secondary)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))

                    SectionHeader("Details", icon: "info.circle", color: .green)

                    Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 8) {
                        GridRow {
                            Text("Power Source")
                                .foregroundStyle(.secondary)
                            Text(battery.powerSource)
                        }
                        GridRow {
                            Text("Charge")
                                .foregroundStyle(.secondary)
                            Text(FormatHelpers.percent(battery.chargePercent))
                                .monospacedDigit()
                        }
                        GridRow {
                            Text("Cycle Count")
                                .foregroundStyle(.secondary)
                            Text("\(battery.cycleCount)")
                                .monospacedDigit()
                        }
                        GridRow {
                            Text("Health")
                                .foregroundStyle(.secondary)
                            Text(FormatHelpers.percent(battery.health))
                                .monospacedDigit()
                        }
                        if let timeRemaining = battery.timeRemaining, timeRemaining > 0 {
                            GridRow {
                                Text("Time Remaining")
                                    .foregroundStyle(.secondary)
                                Text(FormatHelpers.duration(minutes: timeRemaining))
                                    .monospacedDigit()
                            }
                        }
                    }
                    .padding()
                    .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))

                    SectionHeader("Charge Over Time", icon: "chart.xyaxis.line", color: .green)

                    LiveChart(
                        data: monitor.history.batteryHistory,
                        color: .green,
                        label: "Charge",
                        yDomain: 0...1.0,
                        formatAsPercent: true
                    )
                    .padding()
                    .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                } else {
                    ContentUnavailableView(
                        "No Battery",
                        systemImage: "battery.0",
                        description: Text("No battery detected on this Mac")
                    )
                    .padding()
                    .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private var batteryColor: Color {
        if battery.chargePercent < 0.2 { return .red }
        if battery.chargePercent < 0.5 { return .orange }
        return .green
    }
}
