import SwiftUI
import Charts

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
            VStack(alignment: .leading, spacing: 24) {
                // Header card
                HStack(spacing: 30) {
                    GaugeView(
                        title: sortByMemory ? "Memory" : "CPU",
                        value: sortByMemory
                            ? monitor.currentSnapshot.memory.usedFraction
                            : monitor.currentSnapshot.cpu.totalUsage,
                        color: sortByMemory ? ZuroxiaTheme.purple : ZuroxiaTheme.cyan
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text("PROCESS MATRIX")
                            .font(ZuroxiaTheme.font(16, weight: .bold))
                            .tracking(2.0)
                            .foregroundStyle(ZuroxiaTheme.textPrimary)
                            
                        if let top = topProcess {
                            Text("HIGHEST LOAD: \(top.name.uppercased())")
                                .font(ZuroxiaTheme.font(10, weight: .medium))
                                .tracking(1.5)
                                .foregroundStyle(ZuroxiaTheme.textMuted)
                        }
                    }

                    Spacer()
                }
                .padding(24)
                .cyberPanel(borderColor: ZuroxiaTheme.borderLight)

                Picker("Sort by", selection: $sortByMemory) {
                    Text("CPU Usage").tag(false)
                    Text("Memory Usage").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 250)
                .padding(.bottom, 8)

                let processes = sortByMemory
                    ? monitor.currentSnapshot.processes.topByMemory
                    : monitor.currentSnapshot.processes.topByCPU

                if processes.isEmpty && ProcessHelper.isSandboxed {
                    ContentUnavailableView(
                        "DATA UNAVAILABLE",
                        systemImage: "lock.shield",
                        description: Text("PROCESS ENUMERATION BLOCKED BY APP SANDBOX")
                    )
                    .padding(24)
                    .cyberPanel()
                } else if processes.isEmpty {
                    ContentUnavailableView(
                        "AWAITING TELEMETRY",
                        systemImage: "list.number",
                        description: Text("GATHERING PROCESS DATA...")
                    )
                    .padding(24)
                    .cyberPanel()
                } else {
                    SectionHeader("ACTIVE PROCESSES", icon: "server.rack", color: ZuroxiaTheme.textPrimary)
                        .padding(.bottom, 8)

                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                        GridRow {
                            Text("PID")
                                .frame(width: 60, alignment: .leading)
                            Text("IDENTIFIER")
                                .frame(minWidth: 150, alignment: .leading)
                            Text("CPU LOAD")
                                .frame(width: 80, alignment: .trailing)
                            Text("ALLOCATION")
                                .frame(width: 100, alignment: .trailing)
                            Text("ACTION")
                                .frame(width: 60, alignment: .center)
                        }
                        .font(ZuroxiaTheme.font(9, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(ZuroxiaTheme.textMuted)

                        Divider().background(ZuroxiaTheme.borderFaint)

                        ForEach(processes) { proc in
                            GridRow {
                                Text("\(proc.pid)")
                                    .font(ZuroxiaTheme.font(10, weight: .medium))
                                    .foregroundStyle(ZuroxiaTheme.textMuted)
                                    .frame(width: 60, alignment: .leading)
                                    
                                Text(proc.name)
                                    .font(ZuroxiaTheme.font(11, weight: .medium))
                                    .foregroundStyle(ZuroxiaTheme.textPrimary)
                                    .lineLimit(1)
                                    .frame(minWidth: 150, alignment: .leading)
                                    
                                Text(FormatHelpers.percent(proc.cpuUsage))
                                    .font(ZuroxiaTheme.font(10, weight: .bold))
                                    .frame(width: 80, alignment: .trailing)
                                    .foregroundStyle(cpuColor(proc.cpuUsage))
                                    
                                Text(FormatHelpers.bytes(proc.memoryBytes))
                                    .font(ZuroxiaTheme.font(10, weight: .bold))
                                    .frame(width: 100, alignment: .trailing)
                                    .foregroundStyle(ZuroxiaTheme.textSecondary)
                                    
                                if !ProcessHelper.isSandboxed && ProcessHelper.isSafeToTerminate(pid: proc.pid) {
                                    Button {
                                        terminateTarget = proc
                                    } label: {
                                        Text("KILL")
                                            .font(ZuroxiaTheme.font(9, weight: .bold))
                                            .tracking(1.0)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.clear)
                                            .foregroundStyle(ZuroxiaTheme.crimson.opacity(0.8))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 2)
                                                    .stroke(ZuroxiaTheme.crimson.opacity(0.5), lineWidth: 1)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                    .help("Terminate \(proc.name)")
                                    .accessibilityLabel("Terminate \(proc.name)")
                                    .frame(width: 60, alignment: .center)
                                } else {
                                    Color.clear
                                        .frame(width: 60)
                                }
                            }
                        }
                    }
                    .padding(24)
                    .cyberPanel()

                    // Usage chart
                    SectionHeader(
                        "\(sortByMemory ? "MEMORY" : "CPU") USAGE HISTORY",
                        icon: "chart.xyaxis.line",
                        color: sortByMemory ? ZuroxiaTheme.purple : ZuroxiaTheme.cyan
                    )

                    LiveChart(
                        data: sortByMemory
                            ? monitor.history.memoryHistory
                            : monitor.history.cpuHistory,
                        color: sortByMemory ? ZuroxiaTheme.purple : ZuroxiaTheme.cyan,
                        label: sortByMemory ? "Memory" : "CPU",
                        yDomain: 0...1.0,
                        formatAsPercent: true
                    )
                    .padding(16)
                    .cyberPanel()
                }
            }
            .padding()
        }
        .scrollContentBackground(.hidden)
        .background(ZuroxiaTheme.bgDark)
        .alert("TERMINATE PROCESS", isPresented: .init(
            get: { terminateTarget != nil },
            set: { if !$0 { terminateTarget = nil } }
        )) {
            Button("CANCEL", role: .cancel) { terminateTarget = nil }
            Button("TERMINATE", role: .destructive) {
                if let proc = terminateTarget {
                    _ = ProcessHelper.terminateProcess(pid: proc.pid)
                }
                terminateTarget = nil
            }
        } message: {
            if let proc = terminateTarget {
                Text("ARE YOU SURE YOU WANT TO TERMINATE \"\(proc.name)\" (PID \(proc.pid))?")
                    .font(ZuroxiaTheme.font(12))
            }
        }
    }

    private func cpuColor(_ usage: Double) -> Color {
        if usage > 0.5 { return ZuroxiaTheme.crimson }
        if usage > 0.1 { return .orange }
        return ZuroxiaTheme.textPrimary
    }
}
