import SwiftUI

public struct NetworkDetailView: View {
    public let monitor: SystemMonitor

    private var net: NetworkMetrics { monitor.currentSnapshot.network }

    public init(monitor: SystemMonitor) {
        self.monitor = monitor
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Network Throughput")
                    .font(.title2.bold())

                HStack(spacing: 40) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Upload", systemImage: "arrow.up")
                            .foregroundStyle(.blue)
                        Text(FormatHelpers.bytesPerSecond(net.totalSendRate))
                            .font(.title2.monospacedDigit())
                            .contentTransition(.numericText())
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Label("Download", systemImage: "arrow.down")
                            .foregroundStyle(.green)
                        Text(FormatHelpers.bytesPerSecond(net.totalReceiveRate))
                            .font(.title2.monospacedDigit())
                            .contentTransition(.numericText())
                    }

                    Spacer()
                }
                .padding()
                .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))

                SectionHeader("Throughput Over Time", icon: "chart.xyaxis.line", color: .teal)

                DualLineChart(
                    data1: monitor.history.networkSendHistory,
                    data2: monitor.history.networkReceiveHistory,
                    color1: .blue,
                    color2: .green,
                    label1: "Upload",
                    label2: "Download",
                    formatAsBytes: true
                )
                .padding()
                .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))

                SectionHeader("Interfaces", icon: "network", color: .teal)

                ForEach(net.interfaces) { iface in
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "network")
                                .foregroundStyle(.teal)
                            Text(iface.name)
                                .font(.headline)
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("\u{2191} \(FormatHelpers.bytesPerSecond(iface.sendRate))")
                                    .foregroundStyle(.blue)
                                Text("\u{2193} \(FormatHelpers.bytesPerSecond(iface.receiveRate))")
                                    .foregroundStyle(.green)
                            }
                            .font(.caption.monospacedDigit())
                        }

                        HStack {
                            Text("Total Sent: \(FormatHelpers.bytes(iface.bytesSent))")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("Total Received: \(FormatHelpers.bytes(iface.bytesReceived))")
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption.monospacedDigit())
                    }
                    .padding()
                    .background(.quaternary.opacity(0.2), in: RoundedRectangle(cornerRadius: 10))
                }

                if !net.topProcesses.isEmpty {
                    SectionHeader("Top Processes by Network", icon: "arrow.up.arrow.down.circle", color: .teal)

                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
                        GridRow {
                            Text("Process")
                                .fontWeight(.semibold)
                                .frame(minWidth: 120, alignment: .leading)
                            Text("Sent")
                                .fontWeight(.semibold)
                                .frame(width: 90, alignment: .trailing)
                            Text("Received")
                                .fontWeight(.semibold)
                                .frame(width: 90, alignment: .trailing)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        Divider()

                        ForEach(net.topProcesses) { proc in
                            GridRow {
                                Text(proc.name)
                                    .lineLimit(1)
                                    .frame(minWidth: 120, alignment: .leading)
                                Text(FormatHelpers.bytes(proc.bytesSent))
                                    .monospacedDigit()
                                    .frame(width: 90, alignment: .trailing)
                                    .foregroundStyle(.blue)
                                Text(FormatHelpers.bytes(proc.bytesReceived))
                                    .monospacedDigit()
                                    .frame(width: 90, alignment: .trailing)
                                    .foregroundStyle(.green)
                            }
                            .font(.system(.body, design: .monospaced))
                        }
                    }
                    .padding()
                    .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}
