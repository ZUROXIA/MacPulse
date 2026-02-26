import SwiftUI

public struct ProcessListView: View {
    public let monitor: SystemMonitor

    @State private var sortByMemory = false

    public init(monitor: SystemMonitor) {
        self.monitor = monitor
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Top Processes")
                    .font(.title2.bold())

                Picker("Sort by", selection: $sortByMemory) {
                    Text("CPU Usage").tag(false)
                    Text("Memory Usage").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 250)

                let processes = sortByMemory
                    ? monitor.currentSnapshot.processes.topByMemory
                    : monitor.currentSnapshot.processes.topByCPU

                if processes.isEmpty {
                    ContentUnavailableView(
                        "No Process Data",
                        systemImage: "list.number",
                        description: Text("Waiting for process data...")
                    )
                } else {
                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
                        GridRow {
                            Text("PID")
                                .fontWeight(.semibold)
                                .frame(width: 60, alignment: .leading)
                            Text("Name")
                                .fontWeight(.semibold)
                                .frame(minWidth: 150, alignment: .leading)
                            Text("CPU")
                                .fontWeight(.semibold)
                                .frame(width: 80, alignment: .trailing)
                            Text("Memory")
                                .fontWeight(.semibold)
                                .frame(width: 100, alignment: .trailing)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        Divider()

                        ForEach(processes) { proc in
                            GridRow {
                                Text("\(proc.pid)")
                                    .monospacedDigit()
                                    .frame(width: 60, alignment: .leading)
                                Text(proc.name)
                                    .lineLimit(1)
                                    .frame(minWidth: 150, alignment: .leading)
                                Text(FormatHelpers.percent(proc.cpuUsage))
                                    .monospacedDigit()
                                    .frame(width: 80, alignment: .trailing)
                                    .foregroundStyle(proc.cpuUsage > 0.5 ? .red : proc.cpuUsage > 0.1 ? .orange : .primary)
                                Text(FormatHelpers.bytes(proc.memoryBytes))
                                    .monospacedDigit()
                                    .frame(width: 100, alignment: .trailing)
                            }
                            .font(.system(.body, design: .monospaced))
                        }
                    }
                }
            }
        }
    }
}
