import SwiftUI

public struct DiskDetailView: View {
    public let monitor: SystemMonitor

    public init(monitor: SystemMonitor) {
        self.monitor = monitor
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Disk Usage")
                    .font(.title2.bold())

                ForEach(monitor.currentSnapshot.disk.volumes) { volume in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "internaldrive")
                            Text(volume.name)
                                .font(.headline)
                            Spacer()
                            Text(volume.mountPoint)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        ProgressView(value: volume.usedFraction)
                            .tint(diskColor(volume.usedFraction))

                        HStack {
                            Text("\(FormatHelpers.bytes(volume.usedBytes)) used")
                            Spacer()
                            Text("\(FormatHelpers.bytes(volume.freeBytes)) free")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(FormatHelpers.bytes(volume.totalBytes)) total")
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption.monospacedDigit())
                    }
                    .padding()
                    .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
                }

                if monitor.currentSnapshot.disk.volumes.isEmpty {
                    ContentUnavailableView("No Volumes", systemImage: "internaldrive", description: Text("No mounted volumes found"))
                }

                Divider()

                Text("Disk I/O")
                    .font(.headline)

                HStack(spacing: 40) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Read", systemImage: "arrow.down.doc")
                            .foregroundStyle(.blue)
                        Text(FormatHelpers.bytesPerSecond(monitor.currentSnapshot.diskIO.readRate))
                            .font(.title2.monospacedDigit())
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Label("Write", systemImage: "arrow.up.doc")
                            .foregroundStyle(.orange)
                        Text(FormatHelpers.bytesPerSecond(monitor.currentSnapshot.diskIO.writeRate))
                            .font(.title2.monospacedDigit())
                    }

                    Spacer()
                }

                DualLineChart(
                    data1: monitor.history.diskReadHistory,
                    data2: monitor.history.diskWriteHistory,
                    color1: .blue,
                    color2: .orange,
                    label1: "Read",
                    label2: "Write",
                    formatAsBytes: true
                )
            }
        }
    }

    private func diskColor(_ fraction: Double) -> Color {
        if fraction > 0.9 { return .red }
        if fraction > 0.75 { return .orange }
        return .blue
    }
}
