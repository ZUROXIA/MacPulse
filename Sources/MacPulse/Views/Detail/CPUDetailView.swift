import SwiftUI

public struct CPUDetailView: View {
    public let monitor: SystemMonitor

    public init(monitor: SystemMonitor) {
        self.monitor = monitor
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header card
                HStack(spacing: 30) {
                    GaugeView(
                        title: "Total CPU",
                        value: monitor.currentSnapshot.cpu.totalUsage,
                        color: .blue
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text("CPU Usage")
                            .font(.title2.bold())
                        Text("\(monitor.currentSnapshot.cpu.perCoreUsage.count) cores")
                            .foregroundStyle(.secondary)
                        Text(FormatHelpers.percent(monitor.currentSnapshot.cpu.totalUsage))
                            .font(.title.monospacedDigit())
                            .foregroundStyle(.blue)
                            .contentTransition(.numericText())
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 8) {
                        if let cpuTemp = monitor.currentSnapshot.temperature.cpuTemp {
                            HStack(spacing: 4) {
                                Image(systemName: "thermometer")
                                    .foregroundStyle(tempColor(cpuTemp))
                                Text(String(format: "%.0f\u{00B0}C", cpuTemp))
                                    .font(.title2.monospacedDigit())
                                    .foregroundStyle(tempColor(cpuTemp))
                            }
                        }
                        if let gpuTemp = monitor.currentSnapshot.temperature.gpuTemp {
                            HStack(spacing: 4) {
                                Text("GPU")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(String(format: "%.0f\u{00B0}C", gpuTemp))
                                    .font(.body.monospacedDigit())
                                    .foregroundStyle(tempColor(gpuTemp))
                            }
                        }
                        ForEach(monitor.currentSnapshot.temperature.fans) { fan in
                            HStack(spacing: 4) {
                                Image(systemName: "fan")
                                    .foregroundStyle(.secondary)
                                Text("\(fan.rpm) RPM")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding()
                .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))

                // Per-Core Usage
                SectionHeader("Per-Core Usage", icon: "cpu", color: .blue)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                    ForEach(Array(monitor.currentSnapshot.cpu.perCoreUsage.enumerated()), id: \.offset) { index, usage in
                        VStack(spacing: 4) {
                            Text("Core \(index)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            ProgressView(value: min(usage, 1.0))
                                .tint(coreColor(usage))
                            Text(FormatHelpers.percentInt(usage))
                                .font(.caption.monospacedDigit())
                        }
                        .padding(8)
                        .background(.quaternary.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
                    }
                }

                // CPU Usage Over Time
                SectionHeader("CPU Usage Over Time", icon: "chart.xyaxis.line", color: .blue)

                LiveChart(
                    data: monitor.history.cpuHistory,
                    color: .blue,
                    label: "CPU",
                    yDomain: 0...1.0,
                    formatAsPercent: true
                )
                .padding()
                .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))

                if !monitor.history.cpuTempHistory.isEmpty {
                    SectionHeader("CPU Temperature Over Time", icon: "thermometer", color: .red)

                    LiveChart(
                        data: monitor.history.cpuTempHistory,
                        color: .red,
                        label: "Temperature (\u{00B0}C)"
                    )
                    .padding()
                    .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                }

            }
        }
    }

    private func coreColor(_ usage: Double) -> Color {
        if usage > 0.8 { return .red }
        if usage > 0.5 { return .orange }
        return .blue
    }

    private func tempColor(_ temp: Double) -> Color {
        if temp > 90 { return .red }
        if temp > 70 { return .orange }
        return .green
    }

}
