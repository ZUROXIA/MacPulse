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
                Text("Thermal State")
                    .font(.title2.bold())

                HStack(spacing: 20) {
                    Image(systemName: thermal.level.icon)
                        .font(.system(size: 48))
                        .foregroundStyle(thermal.level.color)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(thermal.level.rawValue)
                            .font(.title)
                            .foregroundStyle(thermal.level.color)
                        Text(thermal.level.description)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                Divider()

                Text("State Levels")
                    .font(.headline)

                ForEach(ThermalLevel.allCases, id: \.self) { level in
                    HStack {
                        Circle()
                            .fill(level.color)
                            .frame(width: 12, height: 12)
                        Text(level.rawValue)
                            .fontWeight(level == thermal.level ? .bold : .regular)
                        Spacer()
                        if level == thermal.level {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(level.color)
                        }
                    }
                    .padding(.vertical, 2)
                }

                Divider()

                Text("Thermal State Over Time")
                    .font(.headline)

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
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Thermal state history chart")
                .accessibilityValue("Current level: \(thermal.level.rawValue)")
            }
        }
    }
}
