import SwiftUI
import Charts

public struct MemoryDetailView: View {
    public let monitor: SystemMonitor

    private var mem: MemoryMetrics { monitor.currentSnapshot.memory }

    public init(monitor: SystemMonitor) {
        self.monitor = monitor
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header card
                HStack(spacing: 30) {
                    GaugeView(
                        title: "Memory",
                        value: mem.usedFraction,
                        color: ZuroxiaTheme.purple
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text("MEMORY PRESSURE")
                            .font(ZuroxiaTheme.font(16, weight: .bold))
                            .tracking(2.0)
                            .foregroundStyle(ZuroxiaTheme.purple)
                            .cyberGlow(color: ZuroxiaTheme.purple)
                            
                        Text("\(FormatHelpers.bytes(mem.used)) OF \(FormatHelpers.bytes(mem.total)) USED")
                            .font(ZuroxiaTheme.font(10, weight: .medium))
                            .tracking(1.5)
                            .foregroundStyle(ZuroxiaTheme.textMuted)
                    }

                    Spacer()

                    VStack(spacing: 6) {
                        Image(systemName: pressureIcon)
                            .font(.title)
                            .foregroundStyle(pressureColor)
                            .cyberGlow(color: pressureColor)
                            
                        Text(mem.pressureLevel.label.uppercased())
                            .font(ZuroxiaTheme.font(10, weight: .bold))
                            .tracking(2.0)
                            .foregroundStyle(pressureColor)
                    }
                }
                .padding(24)
                .cyberPanel(borderColor: ZuroxiaTheme.borderLight)

                SectionHeader("ALLOCATION BREAKDOWN", icon: "chart.pie", color: ZuroxiaTheme.purple)

                Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 12) {
                    memoryRow("ACTIVE", value: mem.active, color: ZuroxiaTheme.purple)
                    memoryRow("WIRED", value: mem.wired, color: ZuroxiaTheme.crimson)
                    memoryRow("COMPRESSED", value: mem.compressed, color: ZuroxiaTheme.cyan)
                    memoryRow("FREE", value: mem.free, color: ZuroxiaTheme.emerald)
                    if mem.swapTotal > 0 {
                        memoryRow("SWAP USED", value: mem.swapUsed, color: .orange)
                    }
                }
                .padding(16)
                .cyberPanel()

                SectionHeader("MEMORY USAGE HISTORY", icon: "chart.xyaxis.line", color: ZuroxiaTheme.purple)

                LiveChart(
                    data: monitor.history.memoryHistory,
                    color: ZuroxiaTheme.purple,
                    label: "Memory",
                    yDomain: 0...1.0,
                    formatAsPercent: true
                )
                .padding(16)
                .cyberPanel()

                SectionHeader("PRESSURE STATE HISTORY", icon: "gauge.with.dots.needle.50percent", color: ZuroxiaTheme.purple)

                let pressureData = monitor.history.memoryPressureHistory
                Chart {
                    ForEach(Array(pressureData.enumerated()), id: \.1.0) { _, point in
                        PointMark(
                            x: .value("Time", point.0),
                            y: .value("Level", point.1)
                        )
                        .foregroundStyle(pressureColorForValue(point.1))

                        LineMark(
                            x: .value("Time", point.0),
                            y: .value("Level", point.1)
                        )
                        .foregroundStyle(ZuroxiaTheme.borderLight)
                        .interpolationMethod(.stepCenter)
                    }
                }
                .chartYScale(domain: 0...2)
                .chartYAxis {
                    AxisMarks(values: [0, 1, 2]) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [2, 4]))
                            .foregroundStyle(ZuroxiaTheme.borderFaint)
                        AxisValueLabel {
                            if let v = value.as(Int.self) {
                                Text(MemoryPressureLevel(rawValue: v)?.label.uppercased() ?? "")
                                    .font(ZuroxiaTheme.font(9, weight: .medium))
                                    .tracking(1.0)
                                    .foregroundStyle(ZuroxiaTheme.textMuted)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .minute, count: 2)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [2, 4]))
                            .foregroundStyle(ZuroxiaTheme.borderFaint)
                        AxisValueLabel(format: .dateTime.minute().second())
                            .font(ZuroxiaTheme.font(9))
                            .foregroundStyle(ZuroxiaTheme.textMuted)
                    }
                }
                .frame(height: 150)
                .padding(16)
                .cyberPanel()
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Memory pressure history chart")
                .accessibilityValue("Current: \(mem.pressureLevel.label)")
            }
            .padding()
        }
        .scrollContentBackground(.hidden)
        .background(ZuroxiaTheme.bgDark)
    }

    private var pressureColor: Color {
        switch mem.pressureLevel {
        case .normal: ZuroxiaTheme.emerald
        case .warning: .orange
        case .critical: ZuroxiaTheme.crimson
        }
    }

    private var pressureIcon: String {
        switch mem.pressureLevel {
        case .normal: "gauge.with.dots.needle.0percent"
        case .warning: "gauge.with.dots.needle.50percent"
        case .critical: "gauge.with.dots.needle.100percent"
        }
    }

    private func pressureColorForValue(_ value: Int) -> Color {
        switch value {
        case 0: ZuroxiaTheme.emerald
        case 1: .orange
        default: ZuroxiaTheme.crimson
        }
    }

    private func memoryRow(_ label: String, value: UInt64, color: Color) -> some View {
        GridRow {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .cyberGlow(color: color)
                
            Text(label)
                .font(ZuroxiaTheme.font(10, weight: .medium))
                .tracking(1.5)
                .foregroundStyle(ZuroxiaTheme.textSecondary)
                .frame(width: 100, alignment: .leading)
                
            Text(FormatHelpers.bytes(value))
                .font(ZuroxiaTheme.font(12, weight: .bold))
                .foregroundStyle(ZuroxiaTheme.textPrimary)
        }
    }
}
