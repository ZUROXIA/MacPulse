import SwiftUI

public struct ProcessListView: View {
    public let monitor: SystemMonitor

    @State private var sortByMemory = false
    @State private var terminateTarget: ProcessInfo_?

    public init(monitor: SystemMonitor) {
        self.monitor = monitor
    }

    private var topProcess: ProcessInfo_? {
        sortByMemory
            ? monitor.currentSnapshot.processes.topByMemory.first
            : monitor.currentSnapshot.processes.topByCPU.first
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header card
                HStack(spacing: 30) {
                    GaugeView(
                        title: sortByMemory ? "Memory" : "CPU",
                        value: sortByMemory
                            ? monitor.currentSnapshot.memory.usedFraction
                            : monitor.currentSnapshot.cpu.totalUsage,
                        color: sortByMemory ? .orange : .blue
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Top Processes")
                            .font(.title2.bold())
                        if let top = topProcess {
                            Text("Highest: \(top.name)")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()
                }
                .padding()
                .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))

                Picker("Sort by", selection: $sortByMemory) {
                    Text("CPU Usage").tag(false)
                    Text("Memory Usage").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 250)

                let processes = sortByMemory
                    ? monitor.currentSnapshot.processes.topByMemory
                    : monitor.currentSnapshot.processes.topByCPU

                if processes.isEmpty && ProcessHelper.isSandboxed {
                    ContentUnavailableView(
                        "Process Data Unavailable",
                        systemImage: "lock.shield",
                        description: Text("Process enumeration is not available in the App Store version. CPU and memory monitoring remain fully functional.")
                    )
                    .padding()
                    .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                } else if processes.isEmpty {
                    ContentUnavailableView(
                        "No Process Data",
                        systemImage: "list.number",
                        description: Text("Waiting for process data...")
                    )
                    .padding()
                    .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
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
                            Text("")
                                .frame(width: 32)
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
                                    .foregroundStyle(cpuColor(proc.cpuUsage))
                                Text(FormatHelpers.bytes(proc.memoryBytes))
                                    .monospacedDigit()
                                    .frame(width: 100, alignment: .trailing)
                                if !ProcessHelper.isSandboxed && ProcessHelper.isSafeToTerminate(pid: proc.pid) {
                                    Button {
                                        terminateTarget = proc
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.red.opacity(0.7))
                                    }
                                    .buttonStyle(.plain)
                                    .help("Terminate \(proc.name)")
                                    .accessibilityLabel("Terminate \(proc.name)")
                                    .frame(width: 32)
                                } else {
                                    Color.clear
                                        .frame(width: 32)
                                }
                            }
                            .font(.system(.body, design: .monospaced))
                        }
                    }
                    .padding()
                    .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))

                    // Usage chart
                    SectionHeader(
                        "\(sortByMemory ? "Memory" : "CPU") Usage Over Time",
                        icon: "chart.xyaxis.line",
                        color: sortByMemory ? .orange : .blue
                    )

                    LiveChart(
                        data: sortByMemory
                            ? monitor.history.memoryHistory
                            : monitor.history.cpuHistory,
                        color: sortByMemory ? .orange : .blue,
                        label: sortByMemory ? "Memory" : "CPU",
                        yDomain: 0...1.0,
                        formatAsPercent: true
                    )
                    .padding()
                    .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .alert("Terminate Process", isPresented: .init(
            get: { terminateTarget != nil },
            set: { if !$0 { terminateTarget = nil } }
        )) {
            Button("Cancel", role: .cancel) { terminateTarget = nil }
            Button("Terminate", role: .destructive) {
                if let proc = terminateTarget {
                    _ = ProcessHelper.terminateProcess(pid: proc.pid)
                }
                terminateTarget = nil
            }
        } message: {
            if let proc = terminateTarget {
                Text("Are you sure you want to terminate \"\(proc.name)\" (PID \(proc.pid))?")
            }
        }
    }

    private func cpuColor(_ usage: Double) -> Color {
        if usage > 0.5 { return .red }
        if usage > 0.1 { return .orange }
        return .primary
    }
}
