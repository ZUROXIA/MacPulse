import SwiftUI

public struct CPUDetailView: View {
    public let monitor: SystemMonitor
    @State private var fanOverrides: [Int: Double] = [:]
    @State private var manualFanMode = false

    public init(monitor: SystemMonitor) {
        self.monitor = monitor
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
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
                    }

                    Spacer()

                    // Temperature & Fan info
                    VStack(alignment: .trailing, spacing: 8) {
                        if let cpuTemp = monitor.currentSnapshot.temperature.cpuTemp {
                            HStack(spacing: 4) {
                                Image(systemName: "thermometer")
                                    .foregroundStyle(tempColor(cpuTemp))
                                Text(String(format: "%.0f°C", cpuTemp))
                                    .font(.title2.monospacedDigit())
                                    .foregroundStyle(tempColor(cpuTemp))
                            }
                        }
                        if let gpuTemp = monitor.currentSnapshot.temperature.gpuTemp {
                            HStack(spacing: 4) {
                                Text("GPU")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(String(format: "%.0f°C", gpuTemp))
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

                Divider()

                Text("Per-Core Usage")
                    .font(.headline)

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
                    }
                }

                Divider()

                Text("CPU Usage Over Time")
                    .font(.headline)

                LiveChart(
                    data: monitor.history.cpuHistory,
                    color: .blue,
                    label: "CPU",
                    yDomain: 0...1.0,
                    formatAsPercent: true
                )

                if !monitor.history.cpuTempHistory.isEmpty {
                    Divider()

                    Text("CPU Temperature Over Time")
                        .font(.headline)

                    LiveChart(
                        data: monitor.history.cpuTempHistory,
                        color: .red,
                        label: "Temperature (°C)"
                    )
                }

                // Fan Control
                let fans = monitor.currentSnapshot.temperature.fans
                if !fans.isEmpty {
                    Divider()

                    HStack {
                        Text("Fan Control")
                            .font(.headline)
                        Spacer()
                        Toggle("Manual", isOn: $manualFanMode)
                            .toggleStyle(.switch)
                            .onChange(of: manualFanMode) { _, enabled in
                                SMCHelper.setFanMode(forced: enabled)
                                if !enabled {
                                    fanOverrides.removeAll()
                                }
                            }
                    }

                    if manualFanMode {
                        Text("Drag sliders to set minimum fan speed. Fans will not spin below the set RPM.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    ForEach(fans) { fan in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "fan")
                                Text("Fan \(fan.index + 1)")
                                    .fontWeight(.medium)
                                Spacer()
                                Text("\(fan.rpm) RPM")
                                    .monospacedDigit()
                                    .foregroundStyle(.blue)
                            }

                            if fan.maxRPM > 0 {
                                ProgressView(value: Double(fan.rpm), total: Double(fan.maxRPM))
                                    .tint(fanColor(rpm: fan.rpm, max: fan.maxRPM))

                                HStack {
                                    Text("\(fan.minRPM)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(fan.maxRPM) RPM max")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            if manualFanMode && fan.maxRPM > 0 {
                                HStack {
                                    Text("Target:")
                                        .font(.caption)
                                    Slider(
                                        value: Binding(
                                            get: { fanOverrides[fan.index] ?? Double(fan.minRPM) },
                                            set: { newValue in
                                                fanOverrides[fan.index] = newValue
                                                SMCHelper.setFanMinRPM(index: fan.index, rpm: Int(newValue))
                                            }
                                        ),
                                        in: Double(fan.minRPM)...Double(fan.maxRPM),
                                        step: 100
                                    )
                                    Text("\(Int(fanOverrides[fan.index] ?? Double(fan.minRPM))) RPM")
                                        .font(.caption.monospacedDigit())
                                        .frame(width: 70, alignment: .trailing)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
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

    private func fanColor(rpm: Int, max: Int) -> Color {
        let ratio = Double(rpm) / Double(max)
        if ratio > 0.8 { return .red }
        if ratio > 0.5 { return .orange }
        return .green
    }
}
