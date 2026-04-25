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
            VStack(alignment: .leading, spacing: 24) {
                // Header card
                HStack(spacing: 30) {
                    GaugeView(
                        title: "Avg Fan",
                        value: avgFraction,
                        color: gaugeColor
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text("THERMAL CONTROL")
                            .font(ZuroxiaTheme.font(16, weight: .bold))
                            .tracking(2.0)
                            .foregroundStyle(ZuroxiaTheme.textPrimary)
                            
                        Text("\(fans.count) FAN\(fans.count == 1 ? "" : "S") DETECTED")
                            .font(ZuroxiaTheme.font(10, weight: .medium))
                            .tracking(1.5)
                            .foregroundStyle(ZuroxiaTheme.textMuted)
                            
                        if let avgRPM = averageRPM {
                            Text("\(avgRPM) RPM AVG")
                                .font(ZuroxiaTheme.font(24, weight: .light))
                                .foregroundStyle(ZuroxiaTheme.cyan)
                                .contentTransition(.numericText())
                        }
                    }

                    Spacer()
                }
                .padding(24)
                .cyberPanel(borderColor: ZuroxiaTheme.borderLight)

                // Sandbox banner
                if ProcessHelper.isSandboxed {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.shield")
                            .font(.title2)
                            .foregroundStyle(.orange)
                            .cyberGlow(color: .orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("SANDBOX RESTRICTIONS ACTIVE")
                                .font(ZuroxiaTheme.font(10, weight: .bold))
                                .tracking(1.5)
                                .foregroundStyle(ZuroxiaTheme.textPrimary)
                            Text("FAN CONTROL REQUIRES ELEVATED PRIVILEGES OUTSIDE THE APP STORE SANDBOX.")
                                .font(ZuroxiaTheme.font(9, weight: .medium))
                                .tracking(1.0)
                                .foregroundStyle(ZuroxiaTheme.textSecondary)
                        }
                    }
                    .padding(16)
                    .cyberPanel(borderColor: .orange.opacity(0.3))
                    .accessibilityLabel("Fan control limited by sandbox")
                }

                // Profile picker
                SectionHeader("SPEED PROFILE", icon: "slider.horizontal.3", color: ZuroxiaTheme.cyan)

                HStack(spacing: 8) {
                    ForEach(FanProfile.allCases) { profile in
                        Button {
                            handleProfileSelection(profile)
                        } label: {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(profile == selectedProfile ? profile.color : profile.color.opacity(0.3))
                                    .frame(width: 8, height: 8)
                                    .cyberGlow(color: profile == selectedProfile ? profile.color : .clear)
                                Text(profile.rawValue.uppercased())
                                    .font(ZuroxiaTheme.font(10, weight: profile == selectedProfile ? .bold : .medium))
                                    .tracking(1.5)
                                    .foregroundStyle(profile == selectedProfile ? ZuroxiaTheme.textPrimary : ZuroxiaTheme.textMuted)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                selectedProfile == profile
                                    ? profile.color.opacity(0.1)
                                    : Color.clear
                            )
                            .clipShape(ChamferedRectangle(cornerSize: 4))
                            .overlay(
                                ChamferedRectangle(cornerSize: 4)
                                    .stroke(
                                        selectedProfile == profile
                                            ? profile.color.opacity(0.5)
                                            : ZuroxiaTheme.borderFaint,
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .accessibilityHint("Select a fan speed profile")

                HStack(spacing: 8) {
                    Image(systemName: "speaker.wave.2")
                        .font(.caption2)
                        .foregroundStyle(ZuroxiaTheme.textMuted)
                    Text("ACOUSTIC PROFILE: \(selectedProfile.noiseEstimate.uppercased())")
                        .font(ZuroxiaTheme.font(9, weight: .medium))
                        .tracking(1.5)
                        .foregroundStyle(ZuroxiaTheme.textSecondary)
                }

                // Per-fan cards
                if !fans.isEmpty {
                    SectionHeader("ACTIVE EXHAUSTS", icon: "fan", color: ZuroxiaTheme.cyan)

                    ForEach(fans) { fan in
                        fanCard(fan)
                    }
                }

                // RPM history chart
                let rpmHistory = monitor.history.fanRPMHistory
                if !rpmHistory.isEmpty {
                    SectionHeader("RPM HISTORY", icon: "chart.xyaxis.line", color: ZuroxiaTheme.cyan)

                    Group {
                        if rpmHistory.count == 2,
                           !rpmHistory[0].isEmpty, !rpmHistory[1].isEmpty {
                            DualLineChart(
                                data1: rpmHistory[0],
                                data2: rpmHistory[1],
                                color1: ZuroxiaTheme.cyan,
                                color2: ZuroxiaTheme.purple,
                                label1: "Fan 1 RPM",
                                label2: "Fan 2 RPM"
                            )
                        } else {
                            ForEach(Array(rpmHistory.enumerated()), id: \.offset) { index, history in
                                if !history.isEmpty {
                                    Text("FAN \(index + 1)")
                                        .font(ZuroxiaTheme.font(10, weight: .bold))
                                        .tracking(1.5)
                                        .foregroundStyle(ZuroxiaTheme.textMuted)

                                    LiveChart(
                                        data: history,
                                        color: fanChartColor(index: index),
                                        label: "Fan \(index + 1) RPM"
                                    )
                                }
                            }
                        }
                    }
                    .padding(16)
                    .cyberPanel()
                }
            }
            .padding()
        }
        .scrollContentBackground(.hidden)
        .background(ZuroxiaTheme.bgDark)
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
        .alert("OVERRIDE THERMAL CONTROLS?", isPresented: Binding(
            get: { pendingProfile != nil },
            set: { if !$0 { pendingProfile = nil } }
        )) {
            Button("CANCEL", role: .cancel) {
                pendingProfile = nil
            }
            Button("ENGAGE") {
                if let profile = pendingProfile {
                    selectedProfile = profile
                    applyProfile(profile)
                    pendingProfile = nil
                }
            }
        } message: {
            if let profile = pendingProfile {
                Text("THIS WILL BYPASS HARDWARE AUTOMATIC FAN CONTROL AND ENGAGE \(profile.rawValue.uppercased()) MODE. MANUAL RPM ENFORCEMENT WILL BE ACTIVE.")
                    .font(ZuroxiaTheme.font(12))
            }
        }
        .alert("SMC INTERFACE ERROR", isPresented: $smcError) {
            Button("ACKNOWLEDGE", role: .cancel) {}
        } message: {
            Text("FAILED TO WRITE TARGET RPM TO SYSTEM MANAGEMENT CONTROLLER. ELEVATED PRIVILEGES MAY BE REQUIRED.")
                .font(ZuroxiaTheme.font(12))
        }
    }

    @ViewBuilder
    private func fanCard(_ fan: FanInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TimelineView(.animation) { timeline in
                    Image(systemName: "fan")
                        .font(.title2)
                        .foregroundStyle(ZuroxiaTheme.cyan)
                        .cyberGlow(color: ZuroxiaTheme.cyan)
                        .rotationEffect(.degrees(
                            timeline.date.timeIntervalSinceReferenceDate * rotationSpeed(rpm: fan.rpm)
                        ))
                }
                Text("FAN \(fan.index + 1)")
                    .font(ZuroxiaTheme.font(14, weight: .bold))
                    .tracking(2.0)
                    .foregroundStyle(ZuroxiaTheme.textPrimary)
                Spacer()
                Text("\(fan.rpm)")
                    .font(ZuroxiaTheme.font(24, weight: .light))
                    .foregroundStyle(ZuroxiaTheme.cyan)
                    .contentTransition(.numericText())
                Text("RPM")
                    .font(ZuroxiaTheme.font(10, weight: .medium))
                    .tracking(1.5)
                    .foregroundStyle(ZuroxiaTheme.textMuted)
            }

            if fan.maxRPM > 0 {
                ProgressView(value: Double(fan.rpm), total: Double(fan.maxRPM))
                    .tint(fanColor(rpm: fan.rpm, max: fan.maxRPM))
                    .cyberGlow(color: fanColor(rpm: fan.rpm, max: fan.maxRPM))

                HStack {
                    Text("MIN: \(fan.minRPM)")
                        .font(ZuroxiaTheme.font(9, weight: .medium))
                        .tracking(1.0)
                        .foregroundStyle(ZuroxiaTheme.textSecondary)
                    Spacer()
                    Text("MAX: \(fan.maxRPM)")
                        .font(ZuroxiaTheme.font(9, weight: .medium))
                        .tracking(1.0)
                        .foregroundStyle(ZuroxiaTheme.textSecondary)
                }
            }

            if selectedProfile == .custom && fan.maxRPM > 0 {
                HStack(spacing: 16) {
                    Text("TARGET")
                        .font(ZuroxiaTheme.font(10, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(ZuroxiaTheme.textSecondary)
                        
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
                    .tint(ZuroxiaTheme.cyan)
                    
                    Text("\(Int(fanOverrides[fan.index] ?? Double(fan.minRPM))) RPM")
                        .font(ZuroxiaTheme.font(11, weight: .bold))
                        .foregroundStyle(ZuroxiaTheme.cyan)
                        .frame(width: 80, alignment: .trailing)
                }
                .padding(.top, 8)
            }
        }
        .padding(24)
        .cyberPanel(borderColor: ZuroxiaTheme.borderLight)
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
        if avgFraction > 0.8 { return ZuroxiaTheme.crimson }
        if avgFraction > 0.5 { return .orange }
        return ZuroxiaTheme.emerald
    }

    private func fanColor(rpm: Int, max: Int) -> Color {
        let ratio = Double(rpm) / Double(max)
        if ratio > 0.8 { return ZuroxiaTheme.crimson }
        if ratio > 0.5 { return .orange }
        return ZuroxiaTheme.emerald
    }

    private func fanChartColor(index: Int) -> Color {
        let colors: [Color] = [ZuroxiaTheme.cyan, ZuroxiaTheme.purple, ZuroxiaTheme.emerald, .orange]
        return colors[index % colors.count]
    }
}
