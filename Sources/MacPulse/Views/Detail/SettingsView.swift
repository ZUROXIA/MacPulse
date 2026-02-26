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
                        Toggle("Show CPU %", isOn: $settings.showCPUInMenuBar)
                        Toggle("Show Memory %", isOn: $settings.showMemoryInMenuBar)
                        Toggle("Show Network Rate", isOn: $settings.showNetworkInMenuBar)
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
            }
        }
    }
}
