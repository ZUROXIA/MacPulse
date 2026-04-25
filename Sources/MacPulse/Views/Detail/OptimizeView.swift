import SwiftUI

public struct OptimizeView: View {
    public let monitor: SystemMonitor

    @State private var settings = AppSettings()
    @State private var recommendations: [Recommendation] = []
    @State private var purgeResult: String?
    @State private var dnsResult: String?
    @State private var cacheSize: UInt64?
    @State private var cacheResult: String?
    @State private var showCacheClearConfirm = false
    @State private var terminateTarget: ProcessInfo_?
    @State private var isPurging = false
    @State private var isFlushingDNS = false
    @State private var isClearingCaches = false

    public init(monitor: SystemMonitor) {
        self.monitor = monitor
    }

    // MARK: - Health Score

    private var healthScore: Double {
        let snap = monitor.currentSnapshot
        var score = 1.0
        if snap.cpu.totalUsage > 0.9 { score -= 0.25 }
        else if snap.cpu.totalUsage > 0.7 { score -= 0.10 }
        switch snap.memory.pressureLevel {
        case .critical: score -= 0.30
        case .warning: score -= 0.15
        case .normal: break
        }
        switch snap.thermal.level {
        case .critical: score -= 0.25
        case .serious: score -= 0.10
        case .fair, .nominal: break
        }
        for vol in snap.disk.volumes {
            if vol.usedFraction > 0.95 { score -= 0.15; break }
            else if vol.usedFraction > 0.9 { score -= 0.05; break }
        }
        return max(score, 0)
    }

    private var healthColor: Color {
        if healthScore > 0.7 { return ZuroxiaTheme.emerald }
        if healthScore > 0.4 { return .orange }
        return ZuroxiaTheme.crimson
    }

    private var healthLabel: String {
        if healthScore > 0.7 { return "OPTIMAL" }
        if healthScore > 0.4 { return "DEGRADED" }
        return "CRITICAL"
    }

    // MARK: - Body

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection

                SectionHeader("DIAGNOSTIC ALERTS", icon: "shield.lefthalf.filled", color: ZuroxiaTheme.cyan)
                recommendationsSection

                if ProcessHelper.isSandboxed {
                    sandboxLimitedSection
                } else {
                    SectionHeader("SYSTEM PURGE PROTOCOLS", icon: "bolt.fill", color: ZuroxiaTheme.purple)
                    quickActionsRow
                }

                SectionHeader("RESOURCE HOGS", icon: "flame.fill", color: ZuroxiaTheme.crimson)
                resourceHogsSection
            }
            .padding()
        }
        .scrollContentBackground(.hidden)
        .background(ZuroxiaTheme.bgDark)
        .onAppear { refresh() }
        .onChange(of: monitor.currentSnapshot.timestamp) { refresh() }
        .alert("TERMINATE PROCESS", isPresented: .init(
            get: { terminateTarget != nil },
            set: { if !$0 { terminateTarget = nil } }
        )) {
            Button("CANCEL", role: .cancel) { terminateTarget = nil }
            Button("TERMINATE", role: .destructive) {
                if let proc = terminateTarget {
                    _ = ProcessHelper.terminateProcess(pid: proc.pid)
                }
                terminateTarget = nil
            }
        } message: {
            if let proc = terminateTarget {
                Text("ARE YOU SURE YOU WANT TO TERMINATE \"\(proc.name)\" (PID \(proc.pid))?")
                    .font(ZuroxiaTheme.font(12))
            }
        }
        .alert("CLEAR CACHE VOLUMES", isPresented: $showCacheClearConfirm) {
            Button("CANCEL", role: .cancel) {}
            Button("CLEAR", role: .destructive) { performCacheClear() }
        } message: {
            if let size = cacheSize {
                Text("THIS WILL PURGE APPROXIMATELY \(FormatHelpers.bytes(size)) OF TEMPORARY DATA. BROWSER CACHES ARE PRESERVED.")
                    .font(ZuroxiaTheme.font(12))
            } else {
                Text("THIS WILL PURGE CACHED DATA FROM ~/Library/Caches/. BROWSER CACHES ARE PRESERVED.")
                    .font(ZuroxiaTheme.font(12))
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 30) {
            GaugeView(
                title: "Health",
                value: healthScore,
                color: healthColor
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("SYSTEM OPTIMIZATION")
                    .font(ZuroxiaTheme.font(16, weight: .bold))
                    .tracking(2.0)
                    .foregroundStyle(ZuroxiaTheme.textPrimary)
                    
                HStack(spacing: 8) {
                    Circle()
                        .fill(healthColor)
                        .frame(width: 8, height: 8)
                        .cyberGlow(color: healthColor)
                        
                    Text(healthLabel)
                        .font(ZuroxiaTheme.font(12, weight: .bold))
                        .tracking(2.0)
                        .foregroundStyle(healthColor)
                }
                Text("\(recommendations.count) ALERT\(recommendations.count == 1 ? "" : "S")")
                    .font(ZuroxiaTheme.font(10, weight: .medium))
                    .tracking(1.5)
                    .foregroundStyle(ZuroxiaTheme.textMuted)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "cpu")
                        .foregroundStyle(ZuroxiaTheme.textMuted)
                    Text(FormatHelpers.percentInt(monitor.currentSnapshot.cpu.totalUsage))
                        .font(ZuroxiaTheme.font(12, weight: .bold))
                        .foregroundStyle(cpuColor)
                        .contentTransition(.numericText())
                }
                HStack(spacing: 8) {
                    Image(systemName: "memorychip")
                        .foregroundStyle(ZuroxiaTheme.textMuted)
                    Text(FormatHelpers.percentInt(monitor.currentSnapshot.memory.usedFraction))
                        .font(ZuroxiaTheme.font(12, weight: .bold))
                        .foregroundStyle(memColor)
                        .contentTransition(.numericText())
                }
                HStack(spacing: 8) {
                    Image(systemName: "thermometer.medium")
                        .foregroundStyle(ZuroxiaTheme.textMuted)
                    Text(monitor.currentSnapshot.thermal.level.rawValue.uppercased())
                        .font(ZuroxiaTheme.font(12, weight: .bold))
                        .tracking(1.0)
                        .foregroundStyle(monitor.currentSnapshot.thermal.level.color)
                }
            }
        }
        .padding(24)
        .cyberPanel(borderColor: ZuroxiaTheme.borderLight)
    }

    private var cpuColor: Color {
        let u = monitor.currentSnapshot.cpu.totalUsage
        if u > 0.9 { return ZuroxiaTheme.crimson }
        if u > 0.7 { return .orange }
        return ZuroxiaTheme.cyan
    }

    private var memColor: Color {
        switch monitor.currentSnapshot.memory.pressureLevel {
        case .critical: return ZuroxiaTheme.crimson
        case .warning: return .orange
        case .normal: return ZuroxiaTheme.purple
        }
    }

    // MARK: - Recommendations

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if recommendations.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.title2)
                        .foregroundStyle(ZuroxiaTheme.emerald)
                        .cyberGlow(color: ZuroxiaTheme.emerald)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ALL CLEAR")
                            .font(ZuroxiaTheme.font(12, weight: .bold))
                            .tracking(2.0)
                            .foregroundStyle(ZuroxiaTheme.textPrimary)
                        Text("SYSTEM TELEMETRY REPORTS NOMINAL OPERATIONS.")
                            .font(ZuroxiaTheme.font(10, weight: .medium))
                            .tracking(1.0)
                            .foregroundStyle(ZuroxiaTheme.textSecondary)
                    }
                    Spacer()
                }
                .padding(20)
                .cyberPanel()
                .accessibilityElement(children: .combine)
                .accessibilityLabel("All clear. System is running well.")
            } else {
                ForEach(recommendations) { rec in
                    recommendationCard(rec)
                }
            }
        }
    }

    private func recommendationCard(_ rec: Recommendation) -> some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(severityColor(rec.severity))
                .frame(width: 4)
                .padding(.vertical, 4)
                .cyberGlow(color: severityColor(rec.severity))

            HStack(spacing: 16) {
                Image(systemName: rec.icon)
                    .font(.title2)
                    .foregroundStyle(severityColor(rec.severity))
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 6) {
                    Text(rec.title.uppercased())
                        .font(ZuroxiaTheme.font(11, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(ZuroxiaTheme.textPrimary)
                    Text(rec.detail.uppercased())
                        .font(ZuroxiaTheme.font(9, weight: .medium))
                        .tracking(1.0)
                        .foregroundStyle(ZuroxiaTheme.textSecondary)
                        .lineLimit(3)
                }

                Spacer()

                if let label = rec.actionLabel, let action = rec.action {
                    Button(action: action) {
                        Text(label.uppercased())
                            .font(ZuroxiaTheme.font(9, weight: .bold))
                            .tracking(1.0)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.clear)
                            .foregroundStyle(severityColor(rec.severity))
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(severityColor(rec.severity).opacity(0.5), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .cyberPanel()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(verbatim: "\(rec.severity) recommendation: \(rec.title). \(rec.detail)"))
    }

    // MARK: - Sandbox Limited

    private var sandboxLimitedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("SYSTEM PURGE PROTOCOLS", icon: "bolt.fill", color: ZuroxiaTheme.purple)

            HStack(spacing: 16) {
                Image(systemName: "lock.shield")
                    .font(.title2)
                    .foregroundStyle(.orange)
                    .cyberGlow(color: .orange)
                    
                VStack(alignment: .leading, spacing: 6) {
                    Text("SANDBOX RESTRICTIONS ACTIVE")
                        .font(ZuroxiaTheme.font(11, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(ZuroxiaTheme.textPrimary)
                    Text("MEMORY PURGE, DNS FLUSH, AND CACHE CLEARING REQUIRE ELEVATED PRIVILEGES. USE TERMINAL FOR THESE OPERATIONS.")
                        .font(ZuroxiaTheme.font(9, weight: .medium))
                        .tracking(1.0)
                        .foregroundStyle(ZuroxiaTheme.textSecondary)
                        .lineLimit(3)
                }
                Spacer()
            }
            .padding(20)
            .cyberPanel(borderColor: .orange.opacity(0.3))
        }
    }

    // MARK: - Quick Actions

    private var quickActionsRow: some View {
        HStack(spacing: 16) {
            actionCard(
                title: "PURGE MEMORY",
                icon: "memorychip",
                color: ZuroxiaTheme.cyan,
                subtitle: purgeResult?.uppercased(),
                isBusy: isPurging
            ) {
                guard !isPurging else { return }
                isPurging = true
                purgeResult = nil
                let freeBefore = monitor.currentSnapshot.memory.free
                Task.detached {
                    let ok = ProcessHelper.purgeMemory()
                    try? await Task.sleep(for: .seconds(1))
                    await MainActor.run {
                        if ok {
                            let freeAfter = monitor.currentSnapshot.memory.free
                            let delta = freeAfter > freeBefore ? freeAfter - freeBefore : 0
                            purgeResult = "FREED ~\(FormatHelpers.bytes(delta))"
                        } else {
                            purgeResult = "ELEVATION REQUIRED"
                        }
                        isPurging = false
                    }
                }
            }

            actionCard(
                title: "FLUSH DNS",
                icon: "network",
                color: ZuroxiaTheme.purple,
                subtitle: dnsResult?.uppercased(),
                isBusy: isFlushingDNS
            ) {
                guard !isFlushingDNS else { return }
                isFlushingDNS = true
                dnsResult = nil
                Task.detached {
                    let ok = ProcessHelper.flushDNSCache()
                    await MainActor.run {
                        dnsResult = ok ? "CACHE FLUSHED" : "FAILED"
                        isFlushingDNS = false
                    }
                }
            }

            actionCard(
                title: "CLEAR CACHES",
                icon: "xmark.bin",
                color: .orange,
                subtitle: cacheResult?.uppercased() ?? cacheSubtitle?.uppercased(),
                isBusy: isClearingCaches
            ) {
                guard !isClearingCaches else { return }
                cacheSize = ProcessHelper.estimateUserCacheSize()
                showCacheClearConfirm = true
            }
        }
    }

    private var cacheSubtitle: String? {
        if let size = cacheSize {
            return FormatHelpers.bytes(size)
        }
        return nil
    }

    private func actionCard(title: String, icon: String, color: Color, subtitle: String?, isBusy: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(color.opacity(0.3), lineWidth: 1)
                        .background(Circle().fill(color.opacity(0.1)))
                        .frame(width: 48, height: 48)
                        
                    if isBusy {
                        ProgressView()
                            .controlSize(.small)
                            .tint(color)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 20))
                            .foregroundStyle(color)
                            .cyberGlow(color: color)
                    }
                }

                Text(title)
                    .font(ZuroxiaTheme.font(10, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(ZuroxiaTheme.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(ZuroxiaTheme.font(8, weight: .medium))
                        .tracking(1.0)
                        .foregroundStyle(ZuroxiaTheme.textSecondary)
                        .lineLimit(1)
                } else {
                    Text(" ")
                        .font(ZuroxiaTheme.font(8))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
        .cyberPanel()
        .disabled(isBusy)
        .accessibilityLabel(title)
        .accessibilityHint(subtitle ?? "")
    }

    // MARK: - Resource Hogs

    private var resourceHogsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            let hogCount = settings.resourceHogCount
            let topCPU = Array(monitor.currentSnapshot.processes.topByCPU.prefix(hogCount))
            let topMem = Array(monitor.currentSnapshot.processes.topByMemory.prefix(hogCount))

            if topCPU.isEmpty && topMem.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: "list.number")
                            .font(.largeTitle)
                            .foregroundStyle(ZuroxiaTheme.textMuted)
                        Text("AWAITING TELEMETRY")
                            .font(ZuroxiaTheme.font(12, weight: .bold))
                            .tracking(2.0)
                            .foregroundStyle(ZuroxiaTheme.textSecondary)
                    }
                    Spacer()
                }
                .padding(40)
                .cyberPanel()
            } else {
                HStack(alignment: .top, spacing: 16) {
                    if !topCPU.isEmpty {
                        hogColumn(
                            title: "CPU SPIKES",
                            icon: "cpu",
                            color: ZuroxiaTheme.cyan,
                            processes: topCPU,
                            metric: { FormatHelpers.percent($0.cpuUsage) },
                            bar: { $0.cpuUsage },
                            barColor: { u in u > 0.5 ? ZuroxiaTheme.crimson : u > 0.2 ? .orange : ZuroxiaTheme.cyan }
                        )
                    }
                    if !topMem.isEmpty {
                        hogColumn(
                            title: "MEMORY SPIKES",
                            icon: "memorychip",
                            color: ZuroxiaTheme.purple,
                            processes: topMem,
                            metric: { FormatHelpers.bytes($0.memoryBytes) },
                            bar: { Double($0.memoryBytes) / Double(max(monitor.currentSnapshot.memory.total, 1)) },
                            barColor: { f in f > 0.3 ? ZuroxiaTheme.crimson : f > 0.1 ? .orange : ZuroxiaTheme.purple.opacity(0.8) }
                        )
                    }
                }
            }
        }
    }

    private func hogColumn(
        title: String,
        icon: String,
        color: Color,
        processes: [ProcessInfo_],
        metric: @escaping (ProcessInfo_) -> String,
        bar: @escaping (ProcessInfo_) -> Double,
        barColor: @escaping (Double) -> Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(ZuroxiaTheme.font(11, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(color)
                .cyberGlow(color: color)
                .padding(.bottom, 4)

            ForEach(processes) { proc in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(proc.name.uppercased())
                            .font(ZuroxiaTheme.font(10, weight: .bold))
                            .foregroundStyle(ZuroxiaTheme.textPrimary)
                            .lineLimit(1)
                        Spacer()
                        if !ProcessHelper.isSandboxed && ProcessHelper.isSafeToTerminate(pid: proc.pid) {
                            Button {
                                if settings.confirmBeforeTerminate {
                                    terminateTarget = proc
                                } else {
                                    _ = ProcessHelper.terminateProcess(pid: proc.pid)
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(ZuroxiaTheme.crimson)
                            }
                            .buttonStyle(.plain)
                            .padding(4)
                            .background(ZuroxiaTheme.crimson.opacity(0.1))
                            .clipShape(Circle())
                            .help("Terminate \(proc.name)")
                            .accessibilityLabel("Terminate \(proc.name)")
                        }
                    }

                    let value = min(bar(proc), 1.0)
                    ProgressView(value: value)
                        .tint(barColor(value))

                    HStack {
                        Text("PID \(proc.pid)")
                            .font(ZuroxiaTheme.font(9, weight: .medium))
                            .tracking(1.0)
                            .foregroundStyle(ZuroxiaTheme.textMuted)
                        Spacer()
                        Text(metric(proc))
                            .font(ZuroxiaTheme.font(10, weight: .bold))
                            .foregroundStyle(barColor(value))
                    }
                }
                .padding(16)
                .cyberPanel(borderColor: ZuroxiaTheme.borderFaint)
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func refresh() {
        let thresholds = OptimizeThresholds(from: settings)
        recommendations = RecommendationEngine.analyze(monitor.currentSnapshot, thresholds: thresholds)
        if cacheSize == nil {
            Task.detached {
                let size = ProcessHelper.estimateUserCacheSize()
                await MainActor.run { cacheSize = size }
            }
        }
    }

    private func performCacheClear() {
        isClearingCaches = true
        cacheResult = nil
        Task.detached {
            let freed = ProcessHelper.clearUserCaches()
            let newSize = ProcessHelper.estimateUserCacheSize()
            await MainActor.run {
                cacheResult = "FREED \(FormatHelpers.bytes(freed))"
                cacheSize = newSize
                isClearingCaches = false
            }
        }
    }

    private func severityColor(_ severity: Recommendation.Severity) -> Color {
        switch severity {
        case .info: ZuroxiaTheme.emerald
        case .warning: .orange
        case .critical: ZuroxiaTheme.crimson
        }
    }
}
