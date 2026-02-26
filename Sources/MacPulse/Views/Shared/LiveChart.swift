import SwiftUI
import Charts

private struct ChartDataPoint: Identifiable {
    var id: Date { date }
    let date: Date
    let value: Double
}

public struct LiveChart: View {
    public let data: [(Date, Double)]
    public let color: Color
    public let label: String
    public var yDomain: ClosedRange<Double>? = nil
    public var formatAsPercent: Bool = false
    public var formatAsBytes: Bool = false

    public init(data: [(Date, Double)], color: Color, label: String, yDomain: ClosedRange<Double>? = nil, formatAsPercent: Bool = false, formatAsBytes: Bool = false) {
        self.data = data
        self.color = color
        self.label = label
        self.yDomain = yDomain
        self.formatAsPercent = formatAsPercent
        self.formatAsBytes = formatAsBytes
    }

    public var body: some View {
        let points = data.map { ChartDataPoint(date: $0.0, value: $0.1) }
        Chart(points) { point in
            LineMark(
                x: .value("Time", point.date),
                y: .value(label, point.value)
            )
            .foregroundStyle(color.gradient)
            .interpolationMethod(.catmullRom)

            AreaMark(
                x: .value("Time", point.date),
                y: .value(label, point.value)
            )
            .foregroundStyle(color.opacity(0.1).gradient)
            .interpolationMethod(.catmullRom)
        }
        .chartYScale(domain: yDomain ?? autoDomain)
        .chartXAxis {
            AxisMarks(values: .stride(by: .minute, count: 2)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.minute().second())
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if formatAsPercent {
                        Text(FormatHelpers.percentInt(value.as(Double.self) ?? 0))
                    } else if formatAsBytes {
                        Text(FormatHelpers.bytesPerSecond(value.as(Double.self) ?? 0))
                    } else {
                        Text("\(value.as(Double.self) ?? 0, specifier: "%.1f")")
                    }
                }
            }
        }
        .frame(height: 200)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label) chart")
        .accessibilityValue(accessibilitySummary)
        .accessibilityAddTraits(.updatesFrequently)
    }

    private var autoDomain: ClosedRange<Double> {
        let values = data.map(\.1)
        let maxVal = values.max() ?? 1.0
        return 0...max(maxVal * 1.1, 0.01)
    }

    private var accessibilitySummary: String {
        guard let last = data.last else { return "No data" }
        if formatAsPercent {
            return "Current: \(FormatHelpers.percentInt(last.1))"
        } else if formatAsBytes {
            return "Current: \(FormatHelpers.bytesPerSecond(last.1))"
        }
        return "Current: \(String(format: "%.1f", last.1))"
    }
}

public struct DualLineChart: View {
    public let data1: [(Date, Double)]
    public let data2: [(Date, Double)]
    public let color1: Color
    public let color2: Color
    public let label1: String
    public let label2: String
    public var formatAsBytes: Bool = false

    public init(data1: [(Date, Double)], data2: [(Date, Double)], color1: Color, color2: Color, label1: String, label2: String, formatAsBytes: Bool = false) {
        self.data1 = data1
        self.data2 = data2
        self.color1 = color1
        self.color2 = color2
        self.label1 = label1
        self.label2 = label2
        self.formatAsBytes = formatAsBytes
    }

    public var body: some View {
        let points1 = data1.map { ChartDataPoint(date: $0.0, value: $0.1) }
        let points2 = data2.map { ChartDataPoint(date: $0.0, value: $0.1) }
        Chart {
            ForEach(points1) { point in
                LineMark(
                    x: .value("Time", point.date),
                    y: .value(label1, point.value),
                    series: .value("Series", label1)
                )
                .foregroundStyle(color1)
                .interpolationMethod(.catmullRom)
            }
            ForEach(points2) { point in
                LineMark(
                    x: .value("Time", point.date),
                    y: .value(label2, point.value),
                    series: .value("Series", label2)
                )
                .foregroundStyle(color2)
                .interpolationMethod(.catmullRom)
            }
        }
        .chartForegroundStyleScale([
            label1: color1,
            label2: color2,
        ])
        .chartXAxis {
            AxisMarks(values: .stride(by: .minute, count: 2)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.minute().second())
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if formatAsBytes {
                        Text(FormatHelpers.bytesPerSecond(value.as(Double.self) ?? 0))
                    } else {
                        Text("\(value.as(Double.self) ?? 0, specifier: "%.1f")")
                    }
                }
            }
        }
        .frame(height: 200)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label1) and \(label2) chart")
        .accessibilityValue(dualAccessibilitySummary)
        .accessibilityAddTraits(.updatesFrequently)
    }

    private var dualAccessibilitySummary: String {
        let v1 = data1.last.map { formatAsBytes ? FormatHelpers.bytesPerSecond($0.1) : String(format: "%.1f", $0.1) } ?? "No data"
        let v2 = data2.last.map { formatAsBytes ? FormatHelpers.bytesPerSecond($0.1) : String(format: "%.1f", $0.1) } ?? "No data"
        return "\(label1): \(v1), \(label2): \(v2)"
    }
}
