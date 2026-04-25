import SwiftUI

public struct TelemetryLogView: View {
    @State private var logService = LogStreamService()
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header Block
                HStack(spacing: 30) {
                    Image(systemName: "terminal")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(ZuroxiaTheme.cyan)
                        .cyberGlow(color: ZuroxiaTheme.cyan)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("TELEMETRY STREAM")
                            .font(ZuroxiaTheme.font(16, weight: .bold))
                            .tracking(2.0)
                            .foregroundStyle(ZuroxiaTheme.textPrimary)
                            
                        Text(logService.isStreaming ? "SYSTEM LOG ACTIVE" : "SYSTEM LOG INACTIVE")
                            .font(ZuroxiaTheme.font(10, weight: .bold))
                            .tracking(2.0)
                            .foregroundStyle(logService.isStreaming ? ZuroxiaTheme.cyan : ZuroxiaTheme.textMuted)
                            .cyberGlow(color: logService.isStreaming ? ZuroxiaTheme.cyan : .clear)
                    }

                    Spacer()
                    
                    Button(action: {
                        if logService.isStreaming {
                            logService.stopStreaming()
                        } else {
                            logService.startStreaming()
                        }
                    }) {
                        Text(logService.isStreaming ? "TERMINATE STREAM" : "INITIATE STREAM")
                            .font(ZuroxiaTheme.font(9, weight: .bold))
                            .tracking(1.0)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.clear)
                            .foregroundStyle(logService.isStreaming ? ZuroxiaTheme.crimson : ZuroxiaTheme.cyan)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(logService.isStreaming ? ZuroxiaTheme.crimson.opacity(0.5) : ZuroxiaTheme.cyan.opacity(0.5), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(24)
                .cyberPanel(borderColor: ZuroxiaTheme.borderLight)
                
                SectionHeader("LIVE LOG STREAM", icon: "text.alignleft", color: ZuroxiaTheme.cyan)
                
                VStack(spacing: 0) {
                    if logService.logs.isEmpty {
                        ContentUnavailableView(
                            "AWAITING TELEMETRY",
                            systemImage: "terminal",
                            description: Text("START STREAM TO CAPTURE SYSTEM EVENTS")
                        )
                        .padding(40)
                    } else {
                        ForEach(logService.logs) { log in
                            HStack(alignment: .top, spacing: 16) {
                                Text(log.timestamp)
                                    .font(ZuroxiaTheme.font(10, weight: .medium))
                                    .foregroundStyle(ZuroxiaTheme.textMuted)
                                    .frame(width: 60, alignment: .leading)
                                    
                                Text(log.message)
                                    .font(ZuroxiaTheme.font(10, weight: .medium))
                                    .foregroundStyle(log.isWarning ? ZuroxiaTheme.crimson : ZuroxiaTheme.cyan)
                                    
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            
                            Divider().background(ZuroxiaTheme.borderFaint)
                        }
                    }
                }
                .padding(.vertical, 8)
                .cyberPanel()
            }
            .padding()
        }
        .scrollContentBackground(.hidden)
        .background(ZuroxiaTheme.bgDark)
        .onAppear {
            logService.startStreaming()
        }
        .onDisappear {
            logService.stopStreaming()
        }
    }
}