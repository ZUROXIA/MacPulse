import Foundation
import AppKit

public enum CSVExporter {
    public static func export(history: MetricsHistory) -> String {
        var lines: [String] = []

        lines.append("Timestamp,CPU Usage,Memory Usage,Memory Used (bytes),Network Send Rate,Network Receive Rate,Disk Read Rate,Disk Write Rate,Thermal Level,CPU Temp (°C)")

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        for snapshot in history.snapshots {
            let fields: [String] = [
                dateFormatter.string(from: snapshot.timestamp),
                String(format: "%.4f", snapshot.cpu.totalUsage),
                String(format: "%.4f", snapshot.memory.usedFraction),
                "\(snapshot.memory.used)",
                String(format: "%.0f", snapshot.network.totalSendRate),
                String(format: "%.0f", snapshot.network.totalReceiveRate),
                String(format: "%.0f", snapshot.diskIO.readRate),
                String(format: "%.0f", snapshot.diskIO.writeRate),
                snapshot.thermal.level.rawValue,
                snapshot.temperature.cpuTemp.map { String(format: "%.1f", $0) } ?? "",
            ]
            lines.append(fields.joined(separator: ","))
        }

        return lines.joined(separator: "\n")
    }

    public static func saveWithPanel(history: MetricsHistory) {
        let csv = export(history: history)

        let panel = NSSavePanel()
        panel.title = "Export Metrics"
        panel.nameFieldStringValue = "macpulse-metrics.csv"
        panel.allowedContentTypes = [.commaSeparatedText]

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            try? csv.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}
