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
            VStack(alignment: .leading, spacing: 20) {
                // Header card
                HStack(spacing: 30) {
                    GaugeView(
                        title: "Memory",
                        value: mem.usedFraction,
                        color: .orange
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Memory Pressure")
                            .font(.title2.bold())
                        Text("\(FormatHelpers.bytes(mem.used)) of \(FormatHelpers.bytes(mem.total)) used")
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(spacing: 4) {
                        Image(systemName: pressureIcon)
                            .font(.title)
                            .foregroundStyle(pressureColor)
                        Text(mem.pressureLevel.label)
                            .font(.caption.bold())
                            .foregroundStyle(pressureColor)
                    }
                }
                .padding()
                .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))

                SectionHeader("Breakdown", icon: "chart.pie", color: .orange)

                Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 8) {
                    memoryRow("Active", value: mem.active, color: .orange)
                    memoryRow("Wired", value: mem.wired, color: .red)
                    memoryRow("Compressed", value: mem.compressed, color: .purple)
                    memoryRow("Free", value: mem.free, color: .green)
                }
                .padding()
                .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))

                SectionHeader("Memory Usage Over Time", icon: "chart.xyaxis.line", color: .orange)

                LiveChart(
                    data: monitor.history.memoryHistory,
                    color: .orange,
                    label: "Memory",
                    yDomain: 0...1.0,
                    formatAsPercent: true
                )
                .padding()
                .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))

                SectionHeader("Memory Pressure Over Time", icon: "gauge.with.dots.needle.50percent", color: .orange)

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
                        .foregroundStyle(.gray.opacity(0.3))
                        .interpolationMethod(.stepCenter)
                    }
                }
                .chartYScale(domain: 0...2)
                .chartYAxis {
                    AxisMarks(values: [0, 1, 2]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Int.self) {
                                Text(MemoryPressureLevel(rawValue: v)?.label ?? "")
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .minute, count: 2)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.minute().second())
                    }
                }
                .frame(height: 150)
                .padding()
                .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Memory pressure history chart")
                .accessibilityValue("Current: \(mem.pressureLevel.label)")
            }
        }
    }

    private var pressureColor: Color {
        switch mem.pressureLevel {
        case .normal: .green
        case .warning: .orange
        case .critical: .red
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
        case 0: .green
        case 1: .orange
        default: .red
        }
    }

    private func memoryRow(_ label: String, value: UInt64, color: Color) -> some View {
        GridRow {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .frame(width: 100, alignment: .leading)
            Text(FormatHelpers.bytes(value))
                .monospacedDigit()
        }
    }
}
