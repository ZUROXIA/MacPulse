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
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("CONFIG MATRIX")
                        .font(ZuroxiaTheme.font(16, weight: .bold))
                        .tracking(2.0)
                        .foregroundStyle(ZuroxiaTheme.textPrimary)
                    Spacer()
                    Text("USER: APEX_01")
                        .font(ZuroxiaTheme.font(10, weight: .medium))
                        .tracking(2.0)
                        .foregroundStyle(ZuroxiaTheme.textMuted)
                }
                .padding(.bottom, 8)
                .border(width: 1, edges: [.bottom], color: ZuroxiaTheme.borderFaint)

                // General
                SectionHeader("CORE PARAMETERS", icon: "gearshape.fill", color: ZuroxiaTheme.cyan)

                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("UPDATE INTERVAL")
                            .font(ZuroxiaTheme.font(10, weight: .medium))
                            .tracking(1.5)
                            .foregroundStyle(ZuroxiaTheme.textSecondary)
                        Spacer()
                        Picker("", selection: $settings.updateInterval) {
                            ForEach(AppSettings.intervals, id: \.1) { name, interval in
                                Text(name.uppercased()).tag(interval)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 150)
                        .onChange(of: settings.updateInterval) { _, newValue in
                            monitor.restart(interval: newValue)
                        }
                    }

                    Toggle("LAUNCH AT LOGIN", isOn: $settings.launchAtLogin)
                        .font(ZuroxiaTheme.font(10, weight: .medium))
                        .tracking(1.5)
                        .foregroundStyle(ZuroxiaTheme.textSecondary)
                }
                .padding(24)
                .cyberPanel()

                // Menu Bar
                SectionHeader("HUD CONFIGURATION", icon: "menubar.rectangle", color: ZuroxiaTheme.purple)

                VStack(alignment: .leading, spacing: 16) {
                    Toggle("GRAPH MODE (MINI CHART)", isOn: $settings.menuBarGraphMode)
                        .font(ZuroxiaTheme.font(10, weight: .medium))
                        .tracking(1.5)
                        .foregroundStyle(ZuroxiaTheme.textSecondary)
                        
                    if !settings.menuBarGraphMode {
                        Divider().background(ZuroxiaTheme.borderFaint)
                        
                        Toggle("SHOW CPU %", isOn: $settings.showCPUInMenuBar)
                            .font(ZuroxiaTheme.font(10, weight: .medium))
                            .tracking(1.5)
                            .foregroundStyle(ZuroxiaTheme.textSecondary)
                        Toggle("SHOW MEMORY %", isOn: $settings.showMemoryInMenuBar)
                            .font(ZuroxiaTheme.font(10, weight: .medium))
                            .tracking(1.5)
                            .foregroundStyle(ZuroxiaTheme.textSecondary)
                        Toggle("SHOW NETWORK RATE", isOn: $settings.showNetworkInMenuBar)
                            .font(ZuroxiaTheme.font(10, weight: .medium))
                            .tracking(1.5)
                            .foregroundStyle(ZuroxiaTheme.textSecondary)
                    }
                }
                .padding(24)
                .cyberPanel()

                // Alerts
                SectionHeader("AUTONOMOUS DEFENSE", icon: "bell.badge.fill", color: ZuroxiaTheme.emerald)

                VStack(alignment: .leading, spacing: 16) {
                    Toggle("CPU USAGE ALERT (>90% FOR 30S)", isOn: $monitor.alertManager.cpuAlertEnabled)
                        .font(ZuroxiaTheme.font(10, weight: .medium))
                        .tracking(1.5)
                        .foregroundStyle(ZuroxiaTheme.textSecondary)
                    Toggle("DISK SPACE ALERT (>95% FULL)", isOn: $monitor.alertManager.diskAlertEnabled)
                        .font(ZuroxiaTheme.font(10, weight: .medium))
                        .tracking(1.5)
                        .foregroundStyle(ZuroxiaTheme.textSecondary)
                }
                .padding(24)
                .cyberPanel()

                // Optimize
                SectionHeader("DIAGNOSTIC THRESHOLDS", icon: "wand.and.stars", color: ZuroxiaTheme.crimson)

                VStack(alignment: .leading, spacing: 24) {
                    // Thresholds
                    VStack(alignment: .leading, spacing: 12) {
                        Text("RECOMMENDATION THRESHOLDS")
                            .font(ZuroxiaTheme.font(11, weight: .bold))
                            .tracking(2.0)
                            .foregroundStyle(ZuroxiaTheme.textPrimary)
                            .padding(.bottom, 4)

                        thresholdRow(
                            label: "CPU WARNING",
                            value: $settings.cpuWarningThreshold,
                            range: 0.5...0.99
                        )
                        thresholdRow(
                            label: "CPU CRITICAL",
                            value: $settings.cpuCriticalThreshold,
                            range: 0.5...1.0
                        )
                        thresholdRow(
                            label: "DISK WARNING",
                            value: $settings.diskWarningThreshold,
                            range: 0.5...0.99
                        )
                        thresholdRow(
                            label: "BATTERY WARNING",
                            value: $settings.batteryWarningThreshold,
                            range: 0.05...0.5
                        )
                    }

                    Divider().background(ZuroxiaTheme.borderFaint)

                    // Rule toggles
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ENABLED RULES")
                            .font(ZuroxiaTheme.font(11, weight: .bold))
                            .tracking(2.0)
                            .foregroundStyle(ZuroxiaTheme.textPrimary)
                            .padding(.bottom, 4)

                        Group {
                            Toggle("MEMORY PRESSURE", isOn: $settings.enableMemoryRule)
                            Toggle("CPU USAGE", isOn: $settings.enableCPURule)
                            Toggle("DISK SPACE", isOn: $settings.enableDiskRule)
                            Toggle("THERMAL STATE", isOn: $settings.enableThermalRule)
                            Toggle("BATTERY LEVEL", isOn: $settings.enableBatteryRule)
                        }
                        .font(ZuroxiaTheme.font(10, weight: .medium))
                        .tracking(1.5)
                        .foregroundStyle(ZuroxiaTheme.textSecondary)
                    }

                    Divider().background(ZuroxiaTheme.borderFaint)

                    // Behavior
                    VStack(alignment: .leading, spacing: 12) {
                        Text("BEHAVIOR")
                            .font(ZuroxiaTheme.font(11, weight: .bold))
                            .tracking(2.0)
                            .foregroundStyle(ZuroxiaTheme.textPrimary)
                            .padding(.bottom, 4)

                        HStack {
                            Text("RESOURCE HOGS SHOWN")
                                .font(ZuroxiaTheme.font(10, weight: .medium))
                                .tracking(1.5)
                                .foregroundStyle(ZuroxiaTheme.textSecondary)
                            Spacer()
                            Picker("", selection: $settings.resourceHogCount) {
                                ForEach(AppSettings.hogCountOptions, id: \.self) { count in
                                    Text("\(count)").tag(count)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 80)
                        }

                        Toggle("CONFIRM BEFORE TERMINATING PROCESSES", isOn: $settings.confirmBeforeTerminate)
                            .font(ZuroxiaTheme.font(10, weight: .medium))
                            .tracking(1.5)
                            .foregroundStyle(ZuroxiaTheme.textSecondary)
                    }
                }
                .padding(24)
                .cyberPanel()

                // Fan
                SectionHeader("THERMAL CONTROL", icon: "fan", color: ZuroxiaTheme.cyan)

                VStack(alignment: .leading, spacing: 16) {
                    Toggle("AUTO-SWITCH TO PERFORMANCE UNDER THERMAL STRESS", isOn: $settings.fanThermalAutoSwitch)
                        .font(ZuroxiaTheme.font(10, weight: .medium))
                        .tracking(1.5)
                        .foregroundStyle(ZuroxiaTheme.textSecondary)

                    Divider().background(ZuroxiaTheme.borderFaint)

                    HStack {
                        Text("CURRENT PROFILE")
                            .font(ZuroxiaTheme.font(10, weight: .medium))
                            .tracking(1.5)
                            .foregroundStyle(ZuroxiaTheme.textSecondary)
                        Spacer()
                        HStack(spacing: 8) {
                            Circle()
                                .fill(currentFanProfile.color)
                                .frame(width: 8, height: 8)
                                .cyberGlow(color: currentFanProfile.color)
                            Text(settings.fanProfile.uppercased())
                                .font(ZuroxiaTheme.font(11, weight: .bold))
                                .tracking(2.0)
                                .foregroundStyle(ZuroxiaTheme.textPrimary)
                        }
                    }
                }
                .padding(24)
                .cyberPanel()
            }
            .padding()
        }
        .scrollContentBackground(.hidden)
        .background(ZuroxiaTheme.bgDark)
    }

    private var currentFanProfile: FanProfile {
        FanProfile(rawValue: settings.fanProfile) ?? .auto
    }

    private func thresholdRow(label: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        HStack {
            Text(label)
                .font(ZuroxiaTheme.font(10, weight: .medium))
                .tracking(1.5)
                .foregroundStyle(ZuroxiaTheme.textSecondary)
            Spacer()
            Slider(value: value, in: range, step: 0.05)
                .tint(ZuroxiaTheme.crimson)
                .frame(width: 150)
            Text(FormatHelpers.percentInt(value.wrappedValue))
                .font(ZuroxiaTheme.font(10, weight: .bold))
                .foregroundStyle(ZuroxiaTheme.textPrimary)
                .monospacedDigit()
                .frame(width: 40, alignment: .trailing)
        }
    }
}
