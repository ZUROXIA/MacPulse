import SwiftUI

public struct FanControlView: View {
    public let monitor: SystemMonitor
    @State private var selectedProfile: FanProfile = .auto
    @State private var fanOverrides: [Int: Double] = [:]
    @State private var didLoadProfile = false
    @State private var pendingProfile: FanProfile?
    @State private var smcError = false

    public init(monitor: SystemMonitor) {
        self.monitor = monitor
    }

    private var fans: [FanInfo] { monitor.currentSnapshot.temperature.fans }

    private var avgFraction: Double {
        guard !fans.isEmpty else { return 0 }
        let fractions = fans.compactMap { fan -> Double? in
            guard fan.maxRPM > 0 else { return nil }
            return Double(fan.rpm) / Double(fan.maxRPM)
        }
        guard !fractions.isEmpty else { return 0 }
        return fractions.reduce(0, +) / Double(fractions.count)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header card
                HStack(spacing: 30) {
                    GaugeView(
                        title: "Avg Fan",
                        value: avgFraction,
                        color: gaugeColor
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Fan Control")
                            .font(.title2.bold())
                        Text("\(fans.count) fan\(fans.count == 1 ? "" : "s") detected")
                            .foregroundStyle(.secondary)
                        if let avgRPM = averageRPM {
                            Text("\(avgRPM) RPM avg")
                                .font(.title.monospacedDigit())
                                .foregroundStyle(.cyan)
                                .contentTransition(.numericText())
                        }
                    }

                    Spacer()
                }
                .padding()
                .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))

                // Sandbox banner
                if ProcessHelper.isSandboxed {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.shield")
                            .foregroundStyle(.orange)
                        Text("Fan control requires running outside the App Sandbox. Speed changes may not take effect.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(10)
                    .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                    .accessibilityLabel("Fan control limited by sandbox")
                }

                // Profile picker
                SectionHeader("Speed Profile", icon: "slider.horizontal.3", color: .cyan)

                HStack(spacing: 6) {
                    ForEach(FanProfile.allCases) { profile in
                        Button {
                            handleProfileSelection(profile)
                        } label: {
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(profile.color)
                                    .frame(width: 7, height: 7)
                                Text(profile.rawValue)
                                    .font(.caption.weight(.medium))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                selectedProfile == profile
                                    ? profile.color.opacity(0.15)
                                    : Color.clear,
                                in: RoundedRectangle(cornerRadius: 8)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        selectedProfile == profile
                                            ? profile.color
                                            : Color.secondary.opacity(0.2),
                                        lineWidth: selectedProfile == profile ? 1.5 : 0.5
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .accessibilityHint("Select a fan speed profile")

                HStack(spacing: 4) {
                    Image(systemName: "speaker.wave.2")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text(selectedProfile.noiseEstimate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Per-fan cards
                if !fans.isEmpty {
                    SectionHeader("Active Fans", icon: "fan", color: .cyan)

                    ForEach(fans) { fan in
                        fanCard(fan)
                    }
                }

                // RPM history chart
                let rpmHistory = monitor.history.fanRPMHistory
                if !rpmHistory.isEmpty {
                    SectionHeader("RPM Over Time", icon: "chart.xyaxis.line", color: .cyan)

                    Group {
                        if rpmHistory.count == 2,
                           !rpmHistory[0].isEmpty, !rpmHistory[1].isEmpty {
                            DualLineChart(
                                data1: rpmHistory[0],
                                data2: rpmHistory[1],
                                color1: fanChartColor(index: 0),
                                color2: fanChartColor(index: 1),
                                label1: "Fan 1 RPM",
                                label2: "Fan 2 RPM"
                            )
                        } else {
                            ForEach(Array(rpmHistory.enumerated()), id: \.offset) { index, history in
                                if !history.isEmpty {
                                    Text("Fan \(index + 1)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)

                                    LiveChart(
                                        data: history,
                                        color: fanChartColor(index: index),
                                        label: "Fan \(index + 1) RPM"
                                    )
                                }
                            }
                        }
                    }
                    .padding()
                    .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .onAppear {
            if !didLoadProfile {
                let saved = UserDefaults.standard.string(forKey: "fan.profile") ?? "Auto"
                selectedProfile = FanProfile(rawValue: saved) ?? .auto
                didLoadProfile = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            let saved = UserDefaults.standard.string(forKey: "fan.profile") ?? "Auto"
            if let profile = FanProfile(rawValue: saved), profile != selectedProfile {
                selectedProfile = profile
            }
        }
        .alert("Switch Fan Profile?", isPresented: Binding(
            get: { pendingProfile != nil },
            set: { if !$0 { pendingProfile = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                pendingProfile = nil
            }
            Button("Switch") {
                if let profile = pendingProfile {
                    selectedProfile = profile
                    applyProfile(profile)
                    pendingProfile = nil
                }
            }
        } message: {
            if let profile = pendingProfile {
                Text("This will switch from automatic fan control to \(profile.rawValue) mode. Fan speeds will be manually set.")
            }
        }
        .alert("Fan Control Error", isPresented: $smcError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Failed to apply fan settings. SMC access may be restricted.")
        }
    }

    @ViewBuilder
    private func fanCard(_ fan: FanInfo) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                TimelineView(.animation) { timeline in
                    Image(systemName: "fan")
                        .font(.title3)
                        .foregroundStyle(.cyan)
                        .rotationEffect(.degrees(
                            timeline.date.timeIntervalSinceReferenceDate * rotationSpeed(rpm: fan.rpm)
                        ))
                }
                Text("Fan \(fan.index + 1)")
                    .fontWeight(.medium)
                Spacer()
                Text("\(fan.rpm)")
                    .font(.title2.monospacedDigit())
                    .foregroundStyle(.blue)
                    .contentTransition(.numericText())
                Text("RPM")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if fan.maxRPM > 0 {
                ProgressView(value: Double(fan.rpm), total: Double(fan.maxRPM))
                    .tint(fanColor(rpm: fan.rpm, max: fan.maxRPM))

                HStack {
                    Text("\(fan.minRPM) min")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(fan.maxRPM) max")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if selectedProfile == .custom && fan.maxRPM > 0 {
                HStack {
                    Text("Target:")
                        .font(.caption)
                    Slider(
                        value: Binding(
                            get: { fanOverrides[fan.index] ?? Double(fan.minRPM) },
                            set: { newValue in
                                fanOverrides[fan.index] = newValue
                                SMCHelper.setFanMinRPM(index: fan.index, rpm: Int(newValue))
                            }
                        ),
                        in: Double(fan.minRPM)...Double(fan.maxRPM),
                        step: 100
                    )
                    Text("\(Int(fanOverrides[fan.index] ?? Double(fan.minRPM))) RPM")
                        .font(.caption.monospacedDigit())
                        .frame(width: 70, alignment: .trailing)
                }
            }
        }
        .padding()
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Fan \(fan.index + 1): \(fan.rpm) of \(fan.maxRPM) RPM")
    }

    private func handleProfileSelection(_ profile: FanProfile) {
        if selectedProfile == .auto && profile != .auto {
            pendingProfile = profile
        } else {
            selectedProfile = profile
            applyProfile(profile)
        }
    }

    private func applyProfile(_ profile: FanProfile) {
        UserDefaults.standard.set(profile.rawValue, forKey: "fan.profile")

        var hadError = false

        switch profile {
        case .auto:
            if !SMCHelper.setFanMode(forced: false) { hadError = true }
            fanOverrides.removeAll()
            UserDefaults.standard.set(false, forKey: "fan.forcedActive")
        case .custom:
            if !SMCHelper.setFanMode(forced: true) { hadError = true }
            UserDefaults.standard.set(true, forKey: "fan.forcedActive")
        case .silent, .balanced, .performance:
            if !SMCHelper.setFanMode(forced: true) { hadError = true }
            UserDefaults.standard.set(true, forKey: "fan.forcedActive")
            for fan in fans where fan.maxRPM > 0 {
                if let target = profile.targetRPM(minRPM: fan.minRPM, maxRPM: fan.maxRPM) {
                    if !SMCHelper.setFanMinRPM(index: fan.index, rpm: target) { hadError = true }
                    fanOverrides[fan.index] = Double(target)
                }
            }
        }

        if hadError {
            smcError = true
        }
    }

    private func rotationSpeed(rpm: Int) -> Double {
        min(Double(rpm) / 10.0, 720)
    }

    private var averageRPM: Int? {
        guard !fans.isEmpty else { return nil }
        let total = fans.reduce(0) { $0 + $1.rpm }
        return total / fans.count
    }

    private var gaugeColor: Color {
        if avgFraction > 0.8 { return .red }
        if avgFraction > 0.5 { return .orange }
        return .green
    }

    private func fanColor(rpm: Int, max: Int) -> Color {
        let ratio = Double(rpm) / Double(max)
        if ratio > 0.8 { return .red }
        if ratio > 0.5 { return .orange }
        return .green
    }

    private func fanChartColor(index: Int) -> Color {
        let colors: [Color] = [.blue, .cyan, .teal, .mint]
        return colors[index % colors.count]
    }
}
