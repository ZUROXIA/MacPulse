import SwiftUI

public struct GPUDetailView: View {
    public let monitor: SystemMonitor

    private var gpu: GPUMetrics { monitor.currentSnapshot.gpu }

    public init(monitor: SystemMonitor) {
        self.monitor = monitor
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("GPU TELEMETRY")
                        .font(ZuroxiaTheme.font(16, weight: .bold))
                        .tracking(2.0)
                        .foregroundStyle(ZuroxiaTheme.textPrimary)
                    Spacer()
                }
                .padding(.bottom, 8)
                .border(width: 1, edges: [.bottom], color: ZuroxiaTheme.borderFaint)

                if gpu.gpus.isEmpty {
                    ContentUnavailableView(
                        "NO GPU DATA",
                        systemImage: "gpu",
                        description: Text("NO GRAPHICS PROCESSOR DETECTED")
                    )
                    .padding()
                    .cyberPanel()
                } else {
                    ForEach(gpu.gpus) { gpuInfo in
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Image(systemName: "cpu.fill") // no explicit gpu symbol in standard SF symbols on all OS versions, but we'll use one that looks good
                                    .font(.title2)
                                    .foregroundStyle(ZuroxiaTheme.purple)
                                    .cyberGlow(color: ZuroxiaTheme.purple)
                                Text(gpuInfo.name.uppercased())
                                    .font(ZuroxiaTheme.font(14, weight: .bold))
                                    .tracking(2.0)
                                    .foregroundStyle(ZuroxiaTheme.textPrimary)
                                Spacer()
                            }

                            if let util = gpuInfo.utilization {
                                HStack(spacing: 30) {
                                    GaugeView(
                                        title: "Utilization",
                                        value: util,
                                        color: ZuroxiaTheme.purple
                                    )

                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("RENDER LOAD")
                                            .font(ZuroxiaTheme.font(10, weight: .bold))
                                            .tracking(2.0)
                                            .foregroundStyle(ZuroxiaTheme.textMuted)
                                        Text(FormatHelpers.percent(util))
                                            .font(ZuroxiaTheme.font(32, weight: .light))
                                            .foregroundStyle(ZuroxiaTheme.textPrimary)
                                            .contentTransition(.numericText())
                                    }

                                    Spacer()
                                }
                            }

                            if let vramUsed = gpuInfo.vramUsed, let vramTotal = gpuInfo.vramTotal {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("VRAM ALLOCATION")
                                        .font(ZuroxiaTheme.font(10, weight: .bold))
                                        .tracking(2.0)
                                        .foregroundStyle(ZuroxiaTheme.textMuted)
                                        
                                    ProgressView(value: gpuInfo.vramFraction ?? 0)
                                        .tint(ZuroxiaTheme.purple)
                                        .cyberGlow(color: ZuroxiaTheme.purple)
                                        
                                    HStack {
                                        Text("\(FormatHelpers.bytes(vramUsed)) USED")
                                            .font(ZuroxiaTheme.font(10, weight: .bold))
                                            .foregroundStyle(ZuroxiaTheme.textSecondary)
                                        Spacer()
                                        Text("\(FormatHelpers.bytes(vramTotal)) TOTAL")
                                            .font(ZuroxiaTheme.font(10, weight: .bold))
                                            .foregroundStyle(ZuroxiaTheme.textSecondary)
                                    }
                                }
                            }

                            if gpuInfo.utilization == nil && gpuInfo.vramUsed == nil {
                                Text("PERFORMANCE STATISTICS UNAVAILABLE FOR THIS UNIT")
                                    .font(ZuroxiaTheme.font(9, weight: .medium))
                                    .tracking(1.5)
                                    .foregroundStyle(ZuroxiaTheme.textMuted)
                            }
                        }
                        .padding(24)
                        .cyberPanel(borderColor: ZuroxiaTheme.borderLight)
                    }
                }

                if !monitor.history.gpuUtilizationHistory.isEmpty {
                    SectionHeader("GPU LOAD HISTORY", icon: "chart.xyaxis.line", color: ZuroxiaTheme.purple)

                    LiveChart(
                        data: monitor.history.gpuUtilizationHistory,
                        color: ZuroxiaTheme.purple,
                        label: "GPU",
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
    }
}
