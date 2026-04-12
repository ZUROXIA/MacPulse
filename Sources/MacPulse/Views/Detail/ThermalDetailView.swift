import SwiftUI
import Charts

public struct ThermalDetailView: View {
    public let monitor: SystemMonitor

    private var thermal: ThermalMetrics { monitor.currentSnapshot.thermal }

    public init(monitor: SystemMonitor) {
        self.monitor = monitor
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header card
                HStack(spacing: 20) {
                    Image(systemName: thermal.level.icon)
                        .font(.system(size: 48))
                        .foregroundStyle(thermal.level.color)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Thermal State")
                            .font(.title2.bold())
                        Text(thermal.level.rawValue)
                            .font(.title)
                            .foregroundStyle(thermal.level.color)
                        Text(thermal.level.description)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding()
                .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))

                SectionHeader("State Levels", icon: "thermometer.medium", color: .red)

                VStack(spacing: 0) {
                    ForEach(ThermalLevel.allCases, id: \.self) { level in
                        HStack {
                            Circle()
                                .fill(level.color)
                                .frame(width: 10, height: 10)
                            Text(level.rawValue)
                                .fontWeight(level == thermal.level ? .bold : .regular)
                            Spacer()
                            if level == thermal.level {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(level.color)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        if level != ThermalLevel.allCases.last {
                            Divider().padding(.leading, 28)
                        }
                    }
                }
                .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))

                SectionHeader("Thermal State Over Time", icon: "chart.xyaxis.line", color: .red)

                let thermalData = monitor.history.thermalHistory
                Chart {
                    ForEach(Array(thermalData.enumerated()), id: \.1.0) { _, point in
                        PointMark(
                            x: .value("Time", point.0),
                            y: .value("Level", point.1)
                        )
                        .foregroundStyle(ThermalLevel.allCases[point.1].color)

                        LineMark(
                            x: .value("Time", point.0),
                            y: .value("Level", point.1)
                        )
                        .foregroundStyle(.gray.opacity(0.3))
                        .interpolationMethod(.stepCenter)
                    }
                }
                .chartYScale(domain: 0...3)
                .chartYAxis {
                    AxisMarks(values: [0, 1, 2, 3]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Int.self) {
                                Text(ThermalLevel.allCases[v].rawValue)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .minute, count: 2)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.minute().second())
                    }
                }
                .frame(height: 200)
                .padding()
                .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Thermal state history chart")
                .accessibilityValue("Current level: \(thermal.level.rawValue)")

                // Fan summary
                let fans = monitor.currentSnapshot.temperature.fans
                if !fans.isEmpty {
                    SectionHeader("Fans", icon: "fan", color: .cyan)

                    ForEach(fans) { fan in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Image(systemName: "fan")
                                    .foregroundStyle(.cyan)
                                Text("Fan \(fan.index + 1)")
                                    .fontWeight(.medium)
                                Spacer()
                                Text("\(fan.rpm) RPM")
                                    .monospacedDigit()
                                    .foregroundStyle(.blue)
                            }

                            if fan.maxRPM > 0 {
                                ProgressView(value: Double(fan.rpm), total: Double(fan.maxRPM))
                                    .tint(fanColor(rpm: fan.rpm, max: fan.maxRPM))
                            }
                        }
                        .padding()
                        .background(.quaternary.opacity(0.2), in: RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }

    private func fanColor(rpm: Int, max: Int) -> Color {
        let ratio = Double(rpm) / Double(max)
        if ratio > 0.8 { return .red }
        if ratio > 0.5 { return .orange }
        return .green
    }
}
