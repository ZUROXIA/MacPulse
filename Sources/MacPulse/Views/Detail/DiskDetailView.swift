import SwiftUI

public struct DiskDetailView: View {
    public let monitor: SystemMonitor

    public init(monitor: SystemMonitor) {
        self.monitor = monitor
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("STORAGE VOLUMES")
                        .font(ZuroxiaTheme.font(16, weight: .bold))
                        .tracking(2.0)
                        .foregroundStyle(ZuroxiaTheme.textPrimary)
                    Spacer()
                    Text("NVME PCIE MATRIX")
                        .font(ZuroxiaTheme.font(10, weight: .medium))
                        .tracking(2.0)
                        .foregroundStyle(ZuroxiaTheme.textMuted)
                }
                .padding(.bottom, 8)
                .border(width: 1, edges: [.bottom], color: ZuroxiaTheme.borderFaint)

                ForEach(monitor.currentSnapshot.disk.volumes) { volume in
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "internaldrive")
                                .foregroundStyle(ZuroxiaTheme.cyan)
                                .cyberGlow(color: ZuroxiaTheme.cyan)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(volume.name.uppercased())
                                    .font(ZuroxiaTheme.font(12, weight: .bold))
                                    .tracking(1.5)
                                    .foregroundStyle(ZuroxiaTheme.textPrimary)
                                Text(volume.mountPoint.uppercased())
                                    .font(ZuroxiaTheme.font(9, weight: .medium))
                                    .tracking(2.0)
                                    .foregroundStyle(ZuroxiaTheme.textMuted)
                            }
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(FormatHelpers.bytes(volume.freeBytes))
                                    .font(ZuroxiaTheme.font(20, weight: .light))
                                    .foregroundStyle(ZuroxiaTheme.textPrimary)
                                Text("AVAILABLE OF \(FormatHelpers.bytes(volume.totalBytes))")
                                    .font(ZuroxiaTheme.font(9, weight: .medium))
                                    .tracking(2.0)
                                    .foregroundStyle(ZuroxiaTheme.textMuted)
                            }
                        }

                        VStack(spacing: 8) {
                            ProgressView(value: volume.usedFraction)
                                .tint(diskColor(volume.usedFraction))
                                .cyberGlow(color: diskColor(volume.usedFraction))

                            HStack {
                                Text("USED: \(FormatHelpers.bytes(volume.usedBytes))")
                                    .font(ZuroxiaTheme.font(10, weight: .bold))
                                    .foregroundStyle(ZuroxiaTheme.textSecondary)
                                Spacer()
                                Text(FormatHelpers.percentInt(volume.usedFraction))
                                    .font(ZuroxiaTheme.font(10, weight: .bold))
                                    .foregroundStyle(diskColor(volume.usedFraction))
                            }
                        }
                    }
                    .padding(24)
                    .cyberPanel(borderColor: ZuroxiaTheme.borderLight)
                }

                if monitor.currentSnapshot.disk.volumes.isEmpty {
                    ContentUnavailableView("NO VOLUMES", systemImage: "internaldrive", description: Text("NO MOUNTED VOLUMES FOUND"))
                        .padding()
                        .cyberPanel()
                }

                SectionHeader("DISK I/O", icon: "arrow.up.arrow.down", color: ZuroxiaTheme.cyan)

                HStack(spacing: 40) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.down.doc")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(ZuroxiaTheme.emerald)
                                .cyberGlow(color: ZuroxiaTheme.emerald)
                            Text("READ STREAM")
                                .font(ZuroxiaTheme.font(10, weight: .bold))
                                .tracking(2.0)
                                .foregroundStyle(ZuroxiaTheme.textMuted)
                        }
                        
                        Text(FormatHelpers.bytesPerSecond(monitor.currentSnapshot.diskIO.readRate))
                            .font(ZuroxiaTheme.font(28, weight: .light))
                            .foregroundStyle(ZuroxiaTheme.textPrimary)
                            .contentTransition(.numericText())
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.doc")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(ZuroxiaTheme.crimson)
                                .cyberGlow(color: ZuroxiaTheme.crimson)
                            Text("WRITE STREAM")
                                .font(ZuroxiaTheme.font(10, weight: .bold))
                                .tracking(2.0)
                                .foregroundStyle(ZuroxiaTheme.textMuted)
                        }
                        
                        Text(FormatHelpers.bytesPerSecond(monitor.currentSnapshot.diskIO.writeRate))
                            .font(ZuroxiaTheme.font(28, weight: .light))
                            .foregroundStyle(ZuroxiaTheme.textPrimary)
                            .contentTransition(.numericText())
                    }

                    Spacer()
                }
                .padding(24)
                .cyberPanel()

                DualLineChart(
                    data1: monitor.history.diskReadHistory,
                    data2: monitor.history.diskWriteHistory,
                    color1: ZuroxiaTheme.emerald,
                    color2: ZuroxiaTheme.crimson,
                    label1: "Read",
                    label2: "Write",
                    formatAsBytes: true
                )
                .padding(16)
                .cyberPanel()
            }
            .padding()
        }
        .scrollContentBackground(.hidden)
        .background(ZuroxiaTheme.bgDark)
    }

    private func diskColor(_ fraction: Double) -> Color {
        if fraction > 0.9 { return ZuroxiaTheme.crimson }
        if fraction > 0.75 { return .orange }
        return ZuroxiaTheme.cyan
    }
}

extension View {
    func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
        overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
    }
}

struct EdgeBorder: Shape {
    var width: CGFloat
    var edges: [Edge]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for edge in edges {
            var x: CGFloat {
                switch edge {
                case .top, .bottom, .leading: return rect.minX
                case .trailing: return rect.maxX - width
                }
            }

            var y: CGFloat {
                switch edge {
                case .top, .leading, .trailing: return rect.minY
                case .bottom: return rect.maxY - width
                }
            }

            var w: CGFloat {
                switch edge {
                case .top, .bottom: return rect.width
                case .leading, .trailing: return width
                }
            }

            var h: CGFloat {
                switch edge {
                case .top, .bottom: return width
                case .leading, .trailing: return rect.height
                }
            }
            path.addRect(CGRect(x: x, y: y, width: w, height: h))
        }
        return path
    }
}
