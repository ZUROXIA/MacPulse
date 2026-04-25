import SwiftUI

public struct DefenseDetailView: View {
    public let monitor: SystemMonitor

    private var defense: DefenseMetrics { monitor.currentSnapshot.defense }

    public init(monitor: SystemMonitor) {
        self.monitor = monitor
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header Block
                HStack(spacing: 30) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(ZuroxiaTheme.emerald)
                        .cyberGlow(color: ZuroxiaTheme.emerald)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("DEFENSE MATRIX")
                            .font(ZuroxiaTheme.font(16, weight: .bold))
                            .tracking(2.0)
                            .foregroundStyle(ZuroxiaTheme.textPrimary)
                            
                        Text(defense.pfEnabled ? "PACKET FILTER ACTIVE" : "PACKET FILTER INACTIVE")
                            .font(ZuroxiaTheme.font(10, weight: .bold))
                            .tracking(2.0)
                            .foregroundStyle(defense.pfEnabled ? ZuroxiaTheme.emerald : ZuroxiaTheme.textMuted)
                            .cyberGlow(color: defense.pfEnabled ? ZuroxiaTheme.emerald : .clear)
                    }

                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 6) {
                        Text("THREAT LEVEL: ZERO")
                            .font(ZuroxiaTheme.font(10, weight: .bold))
                            .tracking(1.5)
                            .foregroundStyle(ZuroxiaTheme.textSecondary)
                        Text("CONNECTIONS: \(defense.activeConnections.count)")
                            .font(ZuroxiaTheme.font(10, weight: .bold))
                            .tracking(1.5)
                            .foregroundStyle(ZuroxiaTheme.textSecondary)
                    }
                }
                .padding(24)
                .cyberPanel(borderColor: ZuroxiaTheme.borderLight)
                
                if ProcessHelper.isSandboxed {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.shield")
                            .font(.title2)
                            .foregroundStyle(.orange)
                            .cyberGlow(color: .orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("SANDBOX RESTRICTIONS ACTIVE")
                                .font(ZuroxiaTheme.font(10, weight: .bold))
                                .tracking(1.5)
                                .foregroundStyle(ZuroxiaTheme.textPrimary)
                            Text("NETWORK CONNECTION QUERYING MAY BE BLOCKED OR RESTRICTED IN SANDBOXED ENVIRONMENTS.")
                                .font(ZuroxiaTheme.font(9, weight: .medium))
                                .tracking(1.0)
                                .foregroundStyle(ZuroxiaTheme.textSecondary)
                        }
                    }
                    .padding(16)
                    .cyberPanel(borderColor: .orange.opacity(0.3))
                }

                // Firewall Rules
                if !defense.firewallRules.isEmpty {
                    SectionHeader("ACTIVE FIREWALL DIRECTIVES", icon: "shield.righthalf.filled", color: ZuroxiaTheme.cyan)

                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                        GridRow {
                            Text("TARGET_IP")
                                .frame(minWidth: 100, alignment: .leading)
                            Text("PROTOCOL")
                                .frame(width: 80, alignment: .leading)
                            Text("PORT")
                                .frame(width: 60, alignment: .leading)
                            Text("STATUS")
                                .frame(width: 80, alignment: .trailing)
                        }
                        .font(ZuroxiaTheme.font(9, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(ZuroxiaTheme.textMuted)

                        Divider().background(ZuroxiaTheme.borderFaint)

                        ForEach(defense.firewallRules) { rule in
                            GridRow {
                                Text(rule.ip)
                                    .font(ZuroxiaTheme.font(10, weight: .medium))
                                    .foregroundStyle(ZuroxiaTheme.textPrimary)
                                    .frame(minWidth: 100, alignment: .leading)
                                Text(rule.protocol)
                                    .font(ZuroxiaTheme.font(10, weight: .medium))
                                    .foregroundStyle(ZuroxiaTheme.textSecondary)
                                    .frame(width: 80, alignment: .leading)
                                Text(rule.port)
                                    .font(ZuroxiaTheme.font(10, weight: .medium))
                                    .foregroundStyle(ZuroxiaTheme.textSecondary)
                                    .frame(width: 60, alignment: .leading)
                                Text(rule.action)
                                    .font(ZuroxiaTheme.font(10, weight: .bold))
                                    .foregroundStyle(rule.action == "ALLOW" ? ZuroxiaTheme.textPrimary : ZuroxiaTheme.textMuted)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 2)
                                            .stroke(rule.action == "ALLOW" ? ZuroxiaTheme.borderLight : ZuroxiaTheme.borderFaint)
                                    )
                                    .frame(width: 80, alignment: .trailing)
                            }
                        }
                    }
                    .padding(24)
                    .cyberPanel()
                }

                // Active Connections
                SectionHeader("ACTIVE TCP SOCKETS", icon: "network", color: ZuroxiaTheme.purple)

                if defense.activeConnections.isEmpty {
                    ContentUnavailableView(
                        "NO CONNECTIONS",
                        systemImage: "network.slash",
                        description: Text(ProcessHelper.isSandboxed ? "ELEVATED PRIVILEGES REQUIRED OR NONE FOUND." : "NO ESTABLISHED CONNECTIONS FOUND.")
                    )
                    .padding(24)
                    .cyberPanel()
                } else {
                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                        GridRow {
                            Text("LOCAL")
                                .frame(minWidth: 150, alignment: .leading)
                            Text("REMOTE")
                                .frame(minWidth: 150, alignment: .leading)
                            Text("STATE")
                                .frame(width: 100, alignment: .trailing)
                        }
                        .font(ZuroxiaTheme.font(9, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(ZuroxiaTheme.textMuted)

                        Divider().background(ZuroxiaTheme.borderFaint)

                        ForEach(defense.activeConnections) { conn in
                            GridRow {
                                HStack(spacing: 4) {
                                    Text(conn.localIP)
                                        .font(ZuroxiaTheme.font(10, weight: .medium))
                                        .foregroundStyle(ZuroxiaTheme.textPrimary)
                                    Text(":\(conn.localPort)")
                                        .font(ZuroxiaTheme.font(9, weight: .medium))
                                        .foregroundStyle(ZuroxiaTheme.textMuted)
                                }
                                .frame(minWidth: 150, alignment: .leading)
                                
                                HStack(spacing: 4) {
                                    Text(conn.remoteIP)
                                        .font(ZuroxiaTheme.font(10, weight: .medium))
                                        .foregroundStyle(ZuroxiaTheme.cyan)
                                    Text(":\(conn.remotePort)")
                                        .font(ZuroxiaTheme.font(9, weight: .medium))
                                        .foregroundStyle(ZuroxiaTheme.textMuted)
                                }
                                .frame(minWidth: 150, alignment: .leading)
                                
                                Text(conn.status)
                                    .font(ZuroxiaTheme.font(9, weight: .bold))
                                    .foregroundStyle(ZuroxiaTheme.emerald)
                                    .frame(width: 100, alignment: .trailing)
                            }
                        }
                    }
                    .padding(24)
                    .cyberPanel()
                }
            }
            .padding()
        }
        .scrollContentBackground(.hidden)
        .background(ZuroxiaTheme.bgDark)
    }
}
