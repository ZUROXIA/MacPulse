import SwiftUI

public struct CPUDetailView: View {
    public let monitor: SystemMonitor

    public init(monitor: SystemMonitor) {
        self.monitor = monitor
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header card
                HStack(spacing: 30) {
                    GaugeView(
                        title: "Total CPU",
                        value: monitor.currentSnapshot.cpu.totalUsage,
                        color: ZuroxiaTheme.cyan
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text("PROCESSOR LOAD")
                            .font(ZuroxiaTheme.font(16, weight: .bold))
                            .tracking(2.0)
                            .foregroundStyle(ZuroxiaTheme.cyan)
                            .cyberGlow(color: ZuroxiaTheme.cyan)
                            
                        Text("\(monitor.currentSnapshot.cpu.perCoreUsage.count) CORES ACTIVE")
                            .font(ZuroxiaTheme.font(10, weight: .medium))
                            .tracking(1.5)
                            .foregroundStyle(ZuroxiaTheme.textMuted)
                            
                        HStack(spacing: 12) {
                            Text(FormatHelpers.percent(monitor.currentSnapshot.cpu.totalUsage))
                                .font(ZuroxiaTheme.font(32, weight: .light))
                                .foregroundStyle(ZuroxiaTheme.textPrimary)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                let load = monitor.currentSnapshot.cpu.loadAverage
                                Text("LOAD: \(String(format: "%.2f", load.0)) \(String(format: "%.2f", load.1)) \(String(format: "%.2f", load.2))")
                                    .font(ZuroxiaTheme.font(8, weight: .bold))
                                    .foregroundStyle(ZuroxiaTheme.textSecondary)
                                Text("UPTIME: \(FormatHelpers.duration(seconds: Int(monitor.currentSnapshot.cpu.uptime)))")
                                    .font(ZuroxiaTheme.font(8, weight: .bold))
                                    .foregroundStyle(ZuroxiaTheme.textMuted)
                            }
                        }
                        .contentTransition(.numericText())
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 10) {
                        if let cpuTemp = monitor.currentSnapshot.temperature.cpuTemp {
                            HStack(spacing: 8) {
                                Image(systemName: "thermometer")
                                    .foregroundStyle(tempColor(cpuTemp))
                                    .cyberGlow(color: tempColor(cpuTemp))
                                Text(String(format: "%.0f\u{00B0}C", cpuTemp))
                                    .font(ZuroxiaTheme.font(16, weight: .bold))
                                    .foregroundStyle(tempColor(cpuTemp))
                            }
                        }
                        if let gpuTemp = monitor.currentSnapshot.temperature.gpuTemp {
                            HStack(spacing: 8) {
                                Text("GPU")
                                    .font(ZuroxiaTheme.font(9, weight: .medium))
                                    .tracking(2.0)
                                    .foregroundStyle(ZuroxiaTheme.textMuted)
                                Text(String(format: "%.0f\u{00B0}C", gpuTemp))
                                    .font(ZuroxiaTheme.font(14, weight: .bold))
                                    .foregroundStyle(tempColor(gpuTemp))
                            }
                        }
                        ForEach(monitor.currentSnapshot.temperature.fans) { fan in
                            HStack(spacing: 8) {
                                Image(systemName: "fan")
                                    .foregroundStyle(ZuroxiaTheme.textMuted)
                                Text("\(fan.rpm) RPM")
                                    .font(ZuroxiaTheme.font(10, weight: .medium))
                                    .tracking(1.0)
                                    .foregroundStyle(ZuroxiaTheme.textSecondary)
                            }
                        }
                    }
                }
                .padding(24)
                .cyberPanel(borderColor: ZuroxiaTheme.borderLight)

                // Per-Core Usage
                SectionHeader("PER-CORE USAGE", icon: "cpu", color: ZuroxiaTheme.cyan)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                    ForEach(Array(monitor.currentSnapshot.cpu.perCoreUsage.enumerated()), id: \.offset) { index, usage in
                        VStack(spacing: 6) {
                            Text("CORE \(index)")
                                .font(ZuroxiaTheme.font(9, weight: .medium))
                                .tracking(1.5)
                                .foregroundStyle(ZuroxiaTheme.textSecondary)
                                
                            ProgressView(value: min(usage, 1.0))
                                .tint(coreColor(usage))
                                
                            Text(FormatHelpers.percentInt(usage))
                                .font(ZuroxiaTheme.font(10, weight: .bold))
                                .foregroundStyle(ZuroxiaTheme.textPrimary)
                        }
                        .padding(12)
                        .cyberPanel()
                    }
                }

                // CPU Usage Over Time
                SectionHeader("CPU USAGE HISTORY", icon: "chart.xyaxis.line", color: ZuroxiaTheme.cyan)

                LiveChart(
                    data: monitor.history.cpuHistory,
                    color: ZuroxiaTheme.cyan,
                    label: "CPU",
                    yDomain: 0...1.0,
                    formatAsPercent: true
                )
                .padding(16)
                .cyberPanel()

                if !monitor.history.cpuTempHistory.isEmpty {
                    SectionHeader("THERMAL HISTORY", icon: "thermometer", color: ZuroxiaTheme.crimson)

                    LiveChart(
                        data: monitor.history.cpuTempHistory,
                        color: ZuroxiaTheme.crimson,
                        label: "Temperature (\u{00B0}C)"
                    )
                    .padding(16)
                    .cyberPanel()
                }

            }
            .padding()
        }
        .scrollContentBackground(.hidden)
        .background(ZuroxiaTheme.bgDark)
    }

    private func coreColor(_ usage: Double) -> Color {
        if usage > 0.8 { return ZuroxiaTheme.crimson }
        if usage > 0.5 { return .orange }
        return ZuroxiaTheme.cyan
    }

    private func tempColor(_ temp: Double) -> Color {
        if temp > 90 { return ZuroxiaTheme.crimson }
        if temp > 70 { return .orange }
        return ZuroxiaTheme.emerald
    }

}
