import SwiftUI

public struct GPUDetailView: View {
    public let monitor: SystemMonitor

    private var gpu: GPUMetrics { monitor.currentSnapshot.gpu }

    public init(monitor: SystemMonitor) {
        self.monitor = monitor
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("GPU")
                    .font(.title2.bold())

                if gpu.gpus.isEmpty {
                    ContentUnavailableView(
                        "No GPU Data",
                        systemImage: "gpu",
                        description: Text("No GPU information available")
                    )
                    .padding()
                    .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                } else {
                    ForEach(gpu.gpus) { gpuInfo in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "gpu")
                                    .font(.title2)
                                    .foregroundStyle(.purple)
                                Text(gpuInfo.name)
                                    .font(.headline)
                                Spacer()
                            }

                            if let util = gpuInfo.utilization {
                                HStack(spacing: 20) {
                                    GaugeView(
                                        title: "Utilization",
                                        value: util,
                                        color: .purple
                                    )

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("GPU Usage")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                        Text(FormatHelpers.percent(util))
                                            .font(.title.monospacedDigit())
                                            .foregroundStyle(.purple)
                                    }

                                    Spacer()
                                }
                            }

                            if let vramUsed = gpuInfo.vramUsed, let vramTotal = gpuInfo.vramTotal {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("VRAM")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    ProgressView(value: gpuInfo.vramFraction ?? 0)
                                        .tint(.purple)
                                    HStack {
                                        Text("\(FormatHelpers.bytes(vramUsed)) used")
                                        Spacer()
                                        Text("\(FormatHelpers.bytes(vramTotal)) total")
                                            .foregroundStyle(.secondary)
                                    }
                                    .font(.caption.monospacedDigit())
                                }
                            }

                            if gpuInfo.utilization == nil && gpuInfo.vramUsed == nil {
                                Text("Performance statistics not available for this GPU")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                        }
                        .padding()
                        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
                    }
                }

                if !monitor.history.gpuUtilizationHistory.isEmpty {
                    SectionHeader("GPU Utilization Over Time", icon: "chart.xyaxis.line", color: .purple)

                    LiveChart(
                        data: monitor.history.gpuUtilizationHistory,
                        color: .purple,
                        label: "GPU",
                        yDomain: 0...1.0,
                        formatAsPercent: true
                    )
                    .padding()
                    .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}
