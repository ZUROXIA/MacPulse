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
            VStack(alignment: .leading, spacing: 24) {
                // Header card
                HStack(spacing: 30) {
                    Image(systemName: thermal.level.icon)
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(thermal.level.color)
                        .cyberGlow(color: thermal.level.color)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("THERMAL STATE")
                            .font(ZuroxiaTheme.font(16, weight: .bold))
                            .tracking(2.0)
                            .foregroundStyle(ZuroxiaTheme.textPrimary)
                            
                        Text(thermal.level.rawValue.uppercased())
                            .font(ZuroxiaTheme.font(24, weight: .bold))
                            .tracking(2.0)
                            .foregroundStyle(thermal.level.color)
                            
                        Text(thermal.level.description.uppercased())
                            .font(ZuroxiaTheme.font(9, weight: .medium))
                            .tracking(1.5)
                            .foregroundStyle(ZuroxiaTheme.textMuted)
                    }

                    Spacer()
                }
                .padding(24)
                .cyberPanel(borderColor: ZuroxiaTheme.borderLight)

                SectionHeader("STATE LEVELS", icon: "thermometer.medium", color: ZuroxiaTheme.crimson)

                VStack(spacing: 0) {
                    ForEach(ThermalLevel.allCases, id: \.self) { level in
                        HStack {
                            Circle()
                                .fill(level.color)
                                .frame(width: 8, height: 8)
                                .cyberGlow(color: level == thermal.level ? level.color : .clear)
                                
                            Text(level.rawValue.uppercased())
                                .font(ZuroxiaTheme.font(10, weight: level == thermal.level ? .bold : .medium))
                                .tracking(2.0)
                                .foregroundStyle(level == thermal.level ? ZuroxiaTheme.textPrimary : ZuroxiaTheme.textMuted)
                                
                            Spacer()
                            
                            if level == thermal.level {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(level.color)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        
                        if level != ThermalLevel.allCases.last {
                            Divider().background(ZuroxiaTheme.borderFaint).padding(.leading, 32)
                        }
                    }
                }
                .padding(.vertical, 8)
                .cyberPanel()

                SectionHeader("THERMAL STATE HISTORY", icon: "chart.xyaxis.line", color: ZuroxiaTheme.crimson)

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
                        .foregroundStyle(ZuroxiaTheme.borderLight)
                        .interpolationMethod(.stepCenter)
                    }
                }
                .chartYScale(domain: 0...3)
                .chartYAxis {
                    AxisMarks(values: [0, 1, 2, 3]) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [2, 4]))
                            .foregroundStyle(ZuroxiaTheme.borderFaint)
                        AxisValueLabel {
                            if let v = value.as(Int.self) {
                                Text(ThermalLevel.allCases[v].rawValue.uppercased())
                                    .font(ZuroxiaTheme.font(9, weight: .medium))
                                    .tracking(1.0)
                                    .foregroundStyle(ZuroxiaTheme.textMuted)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .minute, count: 2)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [2, 4]))
                            .foregroundStyle(ZuroxiaTheme.borderFaint)
                        AxisValueLabel(format: .dateTime.minute().second())
                            .font(ZuroxiaTheme.font(9))
                            .foregroundStyle(ZuroxiaTheme.textMuted)
                    }
                }
                .frame(height: 200)
                .padding(16)
                .cyberPanel()
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Thermal state history chart")
                .accessibilityValue("Current level: \(thermal.level.rawValue)")

                // Fan summary
                let fans = monitor.currentSnapshot.temperature.fans
                if !fans.isEmpty {
                    SectionHeader("THERMAL EXHAUST FANS", icon: "fan", color: ZuroxiaTheme.cyan)

                    ForEach(fans) { fan in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "fan")
                                    .foregroundStyle(ZuroxiaTheme.cyan)
                                    .cyberGlow(color: ZuroxiaTheme.cyan)
                                    
                                Text("FAN \(fan.index + 1)")
                                    .font(ZuroxiaTheme.font(11, weight: .bold))
                                    .tracking(2.0)
                                    .foregroundStyle(ZuroxiaTheme.textPrimary)
                                    
                                Spacer()
                                
                                Text("\(fan.rpm) RPM")
                                    .font(ZuroxiaTheme.font(12, weight: .bold))
                                    .foregroundStyle(ZuroxiaTheme.cyan)
                            }

                            if fan.maxRPM > 0 {
                                ProgressView(value: Double(fan.rpm), total: Double(fan.maxRPM))
                                    .tint(fanColor(rpm: fan.rpm, max: fan.maxRPM))
                                    .cyberGlow(color: fanColor(rpm: fan.rpm, max: fan.maxRPM))
                            }
                        }
                        .padding(20)
                        .cyberPanel(borderColor: ZuroxiaTheme.borderLight)
                    }
                }
            }
            .padding()
        }
        .scrollContentBackground(.hidden)
        .background(ZuroxiaTheme.bgDark)
    }

    private func fanColor(rpm: Int, max: Int) -> Color {
        let ratio = Double(rpm) / Double(max)
        if ratio > 0.8 { return ZuroxiaTheme.crimson }
        if ratio > 0.5 { return .orange }
        return ZuroxiaTheme.emerald
    }
}
