import SwiftUI

public struct NetworkDetailView: View {
    public let monitor: SystemMonitor

    private var net: NetworkMetrics { monitor.currentSnapshot.network }

    public init(monitor: SystemMonitor) {
        self.monitor = monitor
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header card
                HStack(spacing: 40) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(ZuroxiaTheme.cyan)
                                .cyberGlow(color: ZuroxiaTheme.cyan)
                            Text("TX STREAM (UPLOAD)")
                                .font(ZuroxiaTheme.font(10, weight: .bold))
                                .tracking(2.0)
                                .foregroundStyle(ZuroxiaTheme.textMuted)
                        }
                        
                        Text(FormatHelpers.bytesPerSecond(net.totalSendRate))
                            .font(ZuroxiaTheme.font(28, weight: .light))
                            .foregroundStyle(ZuroxiaTheme.textPrimary)
                            .contentTransition(.numericText())
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(ZuroxiaTheme.emerald)
                                .cyberGlow(color: ZuroxiaTheme.emerald)
                            Text("RX STREAM (DOWNLOAD)")
                                .font(ZuroxiaTheme.font(10, weight: .bold))
                                .tracking(2.0)
                                .foregroundStyle(ZuroxiaTheme.textMuted)
                        }
                        
                        Text(FormatHelpers.bytesPerSecond(net.totalReceiveRate))
                            .font(ZuroxiaTheme.font(28, weight: .light))
                            .foregroundStyle(ZuroxiaTheme.textPrimary)
                            .contentTransition(.numericText())
                    }

                    Spacer()
                }
                .padding(24)
                .cyberPanel(borderColor: ZuroxiaTheme.borderLight)

                SectionHeader("THROUGHPUT HISTORY", icon: "chart.xyaxis.line", color: ZuroxiaTheme.cyan)

                DualLineChart(
                    data1: monitor.history.networkSendHistory,
                    data2: monitor.history.networkReceiveHistory,
                    color1: ZuroxiaTheme.cyan,
                    color2: ZuroxiaTheme.emerald,
                    label1: "Upload",
                    label2: "Download",
                    formatAsBytes: true
                )
                .padding(16)
                .cyberPanel()

                SectionHeader("ACTIVE INTERFACES", icon: "network", color: ZuroxiaTheme.cyan)

                ForEach(net.interfaces) { iface in
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "network")
                                .foregroundStyle(ZuroxiaTheme.cyan)
                            Text(iface.name.uppercased())
                                .font(ZuroxiaTheme.font(12, weight: .bold))
                                .tracking(1.5)
                                .foregroundStyle(ZuroxiaTheme.textPrimary)
                                
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\u{2191} \(FormatHelpers.bytesPerSecond(iface.sendRate))")
                                    .font(ZuroxiaTheme.font(10, weight: .medium))
                                    .foregroundStyle(ZuroxiaTheme.cyan)
                                Text("\u{2193} \(FormatHelpers.bytesPerSecond(iface.receiveRate))")
                                    .font(ZuroxiaTheme.font(10, weight: .medium))
                                    .foregroundStyle(ZuroxiaTheme.emerald)
                            }
                        }

                        Divider().background(ZuroxiaTheme.borderFaint)

                        HStack {
                            Text("TOTAL SENT: \(FormatHelpers.bytes(iface.bytesSent))")
                                .font(ZuroxiaTheme.font(9, weight: .medium))
                                .tracking(1.0)
                                .foregroundStyle(ZuroxiaTheme.textSecondary)
                            Spacer()
                            Text("TOTAL REC: \(FormatHelpers.bytes(iface.bytesReceived))")
                                .font(ZuroxiaTheme.font(9, weight: .medium))
                                .tracking(1.0)
                                .foregroundStyle(ZuroxiaTheme.textSecondary)
                        }
                    }
                    .padding(16)
                    .cyberPanel()
                }

                if !net.topProcesses.isEmpty {
                    SectionHeader("TOP PROCESSES BY NETWORK", icon: "arrow.up.arrow.down.circle", color: ZuroxiaTheme.cyan)

                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                        GridRow {
                            Text("PROCESS IDENTIFIER")
                                .frame(minWidth: 120, alignment: .leading)
                            Text("SENT")
                                .frame(width: 90, alignment: .trailing)
                            Text("RECEIVED")
                                .frame(width: 90, alignment: .trailing)
                        }
                        .font(ZuroxiaTheme.font(9, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(ZuroxiaTheme.textMuted)

                        Divider().background(ZuroxiaTheme.borderFaint)

                        ForEach(net.topProcesses) { proc in
                            GridRow {
                                Text(proc.name)
                                    .font(ZuroxiaTheme.font(11, weight: .medium))
                                    .foregroundStyle(ZuroxiaTheme.textPrimary)
                                    .lineLimit(1)
                                    .frame(minWidth: 120, alignment: .leading)
                                Text(FormatHelpers.bytes(proc.bytesSent))
                                    .font(ZuroxiaTheme.font(10))
                                    .frame(width: 90, alignment: .trailing)
                                    .foregroundStyle(ZuroxiaTheme.cyan)
                                Text(FormatHelpers.bytes(proc.bytesReceived))
                                    .font(ZuroxiaTheme.font(10))
                                    .frame(width: 90, alignment: .trailing)
                                    .foregroundStyle(ZuroxiaTheme.emerald)
                            }
                        }
                    }
                    .padding(16)
                    .cyberPanel()
                }
            }
            .padding()
        }
        .scrollContentBackground(.hidden)
        .background(ZuroxiaTheme.bgDark)
    }
}
