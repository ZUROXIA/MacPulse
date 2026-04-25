import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct SystemStatsEntry: TimelineEntry {
    let date: Date
    let cpuUsage: Double
    let memoryUsage: Double
    let thermalLevel: String
}

struct SystemStatsProvider: TimelineProvider {
    func placeholder(in context: Context) -> SystemStatsEntry {
        SystemStatsEntry(date: .now, cpuUsage: 0.25, memoryUsage: 0.60, thermalLevel: "Nominal")
    }

    func getSnapshot(in context: Context, completion: @escaping (SystemStatsEntry) -> Void) {
        let entry = readCurrentStats()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SystemStatsEntry>) -> Void) {
        let entry = readCurrentStats()
        // Refresh every 5 minutes
        let next = Calendar.current.date(byAdding: .minute, value: 5, to: entry.date) ?? entry.date
        let timeline = Timeline(entries: [entry], policy: .after(next))
        completion(timeline)
    }

    private func readCurrentStats() -> SystemStatsEntry {
        // Read from shared UserDefaults (set by main app)
        let defaults = UserDefaults(suiteName: "com.macpulse.shared") ?? .standard
        let cpu = defaults.double(forKey: "widget.cpuUsage")
        let mem = defaults.double(forKey: "widget.memoryUsage")
        let thermal = defaults.string(forKey: "widget.thermalLevel") ?? "Nominal"
        return SystemStatsEntry(date: .now, cpuUsage: cpu, memoryUsage: mem, thermalLevel: thermal)
    }
}

// MARK: - Widget Views

struct SystemStatsWidgetSmall: View {
    let entry: SystemStatsEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "gauge.medium")
                    .foregroundStyle(.blue)
                Text("MacPulse")
                    .font(.caption.bold())
            }

            HStack(spacing: 12) {
                MiniGauge(label: "CPU", value: entry.cpuUsage, color: .blue)
                MiniGauge(label: "MEM", value: entry.memoryUsage, color: .orange)
            }

            HStack(spacing: 4) {
                Image(systemName: "thermometer")
                    .font(.caption2)
                Text(entry.thermalLevel)
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)
        }
        .padding()
    }
}

struct SystemStatsWidgetMedium: View {
    let entry: SystemStatsEntry

    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "gauge.medium")
                        .foregroundStyle(.blue)
                    Text("MacPulse")
                        .font(.headline)
                }
                Text("System Monitor")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            MiniGauge(label: "CPU", value: entry.cpuUsage, color: .blue)
            MiniGauge(label: "Memory", value: entry.memoryUsage, color: .orange)

            VStack(spacing: 4) {
                Image(systemName: "thermometer")
                Text(entry.thermalLevel)
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)
        }
        .padding()
    }
}

struct MiniGauge: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: min(value, 1.0))
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(String(format: "%.0f%%", value * 100))
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }
            .frame(width: 40, height: 40)

            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Widget Declaration

struct MacPulseWidget: Widget {
    let kind = "MacPulseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SystemStatsProvider()) { entry in
            if #available(macOS 14.0, *) {
                Group {
                    SystemStatsWidgetSmall(entry: entry)
                }
                .containerBackground(.fill.tertiary, for: .widget)
            } else {
                SystemStatsWidgetSmall(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("System Stats")
        .description("CPU, memory, and thermal state at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct MacPulseWidgetBundle: WidgetBundle {
    var body: some Widget {
        MacPulseWidget()
    }
}
