import SwiftUI

public struct MemoryDetailView: View {
    public let monitor: SystemMonitor

    private var mem: MemoryMetrics { monitor.currentSnapshot.memory }

    public init(monitor: SystemMonitor) {
        self.monitor = monitor
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
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
                }

                Divider()

                Text("Breakdown")
                    .font(.headline)

                Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 8) {
                    memoryRow("Active", value: mem.active, color: .orange)
                    memoryRow("Wired", value: mem.wired, color: .red)
                    memoryRow("Compressed", value: mem.compressed, color: .purple)
                    memoryRow("Free", value: mem.free, color: .green)
                }

                Divider()

                Text("Memory Usage Over Time")
                    .font(.headline)

                LiveChart(
                    data: monitor.history.memoryHistory,
                    color: .orange,
                    label: "Memory",
                    yDomain: 0...1.0,
                    formatAsPercent: true
                )
            }
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
