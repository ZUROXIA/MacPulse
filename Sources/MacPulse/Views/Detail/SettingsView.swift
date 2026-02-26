import SwiftUI

public struct SettingsView: View {
    @Bindable public var monitor: SystemMonitor
    @State private var settings: AppSettings

    public init(monitor: SystemMonitor, settings: AppSettings? = nil) {
        self.monitor = monitor
        self._settings = State(initialValue: settings ?? AppSettings())
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Settings")
                    .font(.title2.bold())

                GroupBox("General") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Update Interval")
                            Spacer()
                            Picker("", selection: $settings.updateInterval) {
                                ForEach(AppSettings.intervals, id: \.1) { name, interval in
                                    Text(name).tag(interval)
                                }
                            }
                            .frame(width: 150)
                            .onChange(of: settings.updateInterval) { _, newValue in
                                monitor.restart(interval: newValue)
                            }
                        }

                        Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                    }
                    .padding(.vertical, 4)
                }

                GroupBox("Menu Bar") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Graph mode (mini chart)", isOn: $settings.menuBarGraphMode)
                        if !settings.menuBarGraphMode {
                            Toggle("Show CPU %", isOn: $settings.showCPUInMenuBar)
                            Toggle("Show Memory %", isOn: $settings.showMemoryInMenuBar)
                            Toggle("Show Network Rate", isOn: $settings.showNetworkInMenuBar)
                        }
                    }
                    .padding(.vertical, 4)
                }

                GroupBox("Alerts") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("CPU usage alert (>90% for 30s)", isOn: $monitor.alertManager.cpuAlertEnabled)
                        Toggle("Disk space alert (>95% full)", isOn: $monitor.alertManager.diskAlertEnabled)
                    }
                    .padding(.vertical, 4)
                }

                GroupBox("Optimize") {
                    VStack(alignment: .leading, spacing: 16) {
                        // Thresholds
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recommendation Thresholds")
                                .font(.subheadline.bold())

                            thresholdRow(
                                label: "CPU warning",
                                value: $settings.cpuWarningThreshold,
                                range: 0.5...0.99
                            )
                            thresholdRow(
                                label: "CPU critical",
                                value: $settings.cpuCriticalThreshold,
                                range: 0.5...1.0
                            )
                            thresholdRow(
                                label: "Disk warning",
                                value: $settings.diskWarningThreshold,
                                range: 0.5...0.99
                            )
                            thresholdRow(
                                label: "Battery warning",
                                value: $settings.batteryWarningThreshold,
                                range: 0.05...0.5
                            )
                        }

                        Divider()

                        // Rule toggles
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Enabled Rules")
                                .font(.subheadline.bold())

                            Toggle("Memory pressure", isOn: $settings.enableMemoryRule)
                            Toggle("CPU usage", isOn: $settings.enableCPURule)
                            Toggle("Disk space", isOn: $settings.enableDiskRule)
                            Toggle("Thermal state", isOn: $settings.enableThermalRule)
                            Toggle("Battery level", isOn: $settings.enableBatteryRule)
                        }

                        Divider()

                        // Behavior
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Behavior")
                                .font(.subheadline.bold())

                            HStack {
                                Text("Resource hogs shown")
                                Spacer()
                                Picker("", selection: $settings.resourceHogCount) {
                                    ForEach(AppSettings.hogCountOptions, id: \.self) { count in
                                        Text("\(count)").tag(count)
                                    }
                                }
                                .frame(width: 80)
                            }

                            Toggle("Confirm before terminating processes", isOn: $settings.confirmBeforeTerminate)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func thresholdRow(label: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        HStack {
            Text(label)
            Spacer()
            Slider(value: value, in: range, step: 0.05)
                .frame(width: 150)
            Text(FormatHelpers.percentInt(value.wrappedValue))
                .monospacedDigit()
                .frame(width: 40, alignment: .trailing)
        }
    }
}
