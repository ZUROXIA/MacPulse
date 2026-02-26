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

    /// 0.0 (all critical) … 1.0 (healthy). Computed from current snapshot.
    private var healthScore: Double {
        let snap = monitor.currentSnapshot
        var score = 1.0
        // CPU penalty
        if snap.cpu.totalUsage > 0.9 { score -= 0.25 }
        else if snap.cpu.totalUsage > 0.7 { score -= 0.10 }
        // Memory penalty
        switch snap.memory.pressureLevel {
        case .critical: score -= 0.30
        case .warning: score -= 0.15
        case .normal: break
        }
        // Thermal penalty
        switch snap.thermal.level {
        case .critical: score -= 0.25
        case .serious: score -= 0.10
        case .fair, .nominal: break
        }
        // Disk penalty
        for vol in snap.disk.volumes {
            if vol.usedFraction > 0.95 { score -= 0.15; break }
            else if vol.usedFraction > 0.9 { score -= 0.05; break }
        }
        return max(score, 0)
    }

    private var healthColor: Color {
        if healthScore > 0.7 { return .green }
        if healthScore > 0.4 { return .orange }
        return .red
    }

    private var healthLabel: String {
        if healthScore > 0.7 { return "Healthy" }
        if healthScore > 0.4 { return "Fair" }
        return "Poor"
    }

    // MARK: - Body

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection

                Divider()

                recommendationsSection

                Divider()

                if ProcessHelper.isSandboxed {
                    sandboxLimitedSection
                } else {
                    Text("Quick Actions")
                        .font(.headline)

                    quickActionsRow
                }

                Divider()

                Text("Resource Hogs")
                    .font(.headline)

                resourceHogsSection
            }
        }
        .onAppear { refresh() }
        .onChange(of: monitor.currentSnapshot.timestamp) { refresh() }
        .alert("Terminate Process", isPresented: .init(
            get: { terminateTarget != nil },
            set: { if !$0 { terminateTarget = nil } }
        )) {
            Button("Cancel", role: .cancel) { terminateTarget = nil }
            Button("Terminate", role: .destructive) {
                if let proc = terminateTarget {
                    _ = ProcessHelper.terminateProcess(pid: proc.pid)
                }
                terminateTarget = nil
            }
        } message: {
            if let proc = terminateTarget {
                Text("Are you sure you want to terminate \"\(proc.name)\" (PID \(proc.pid))?")
            }
        }
        .alert("Clear User Caches", isPresented: $showCacheClearConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) { performCacheClear() }
        } message: {
            if let size = cacheSize {
                Text("This will remove approximately \(FormatHelpers.bytes(size)) of cached data. Browser caches are preserved.")
            } else {
                Text("This will remove cached data from ~/Library/Caches/. Browser caches are preserved.")
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
                Text("System Optimization")
                    .font(.title2.bold())
                HStack(spacing: 6) {
                    Circle()
                        .fill(healthColor)
                        .frame(width: 10, height: 10)
                    Text(healthLabel)
                        .foregroundStyle(healthColor)
                        .fontWeight(.medium)
                }
                Text("\(recommendations.count) recommendation\(recommendations.count == 1 ? "" : "s")")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Live stats summary
            VStack(alignment: .trailing, spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "cpu")
                        .foregroundStyle(.secondary)
                    Text(FormatHelpers.percentInt(monitor.currentSnapshot.cpu.totalUsage))
                        .font(.body.monospacedDigit())
                        .foregroundStyle(cpuColor)
                }
                HStack(spacing: 4) {
                    Image(systemName: "memorychip")
                        .foregroundStyle(.secondary)
                    Text(FormatHelpers.percentInt(monitor.currentSnapshot.memory.usedFraction))
                        .font(.body.monospacedDigit())
                        .foregroundStyle(memColor)
                }
                HStack(spacing: 4) {
                    Image(systemName: "thermometer.medium")
                        .foregroundStyle(.secondary)
                    Text(monitor.currentSnapshot.thermal.level.rawValue)
                        .font(.body)
                        .foregroundStyle(monitor.currentSnapshot.thermal.level.color)
                }
            }
        }
    }

    private var cpuColor: Color {
        let u = monitor.currentSnapshot.cpu.totalUsage
        if u > 0.9 { return .red }
        if u > 0.7 { return .orange }
        return .primary
    }

    private var memColor: Color {
        switch monitor.currentSnapshot.memory.pressureLevel {
        case .critical: return .red
        case .warning: return .orange
        case .normal: return .primary
        }
    }

    // MARK: - Recommendations

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommendations")
                .font(.headline)

            if recommendations.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("All Clear")
                            .font(.headline)
                        Text("System is running well. No issues detected.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
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
            // Severity bar
            RoundedRectangle(cornerRadius: 2)
                .fill(severityColor(rec.severity))
                .frame(width: 4)
                .padding(.vertical, 4)

            HStack(spacing: 12) {
                Image(systemName: rec.icon)
                    .font(.title2)
                    .foregroundStyle(severityColor(rec.severity))
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(rec.title)
                        .font(.headline)
                    Text(rec.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }

                Spacer()

                if let label = rec.actionLabel, let action = rec.action {
                    Button(label) { action() }
                        .buttonStyle(.borderedProminent)
                        .tint(severityColor(rec.severity))
                        .controlSize(.small)
                }
            }
            .padding(12)
        }
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(verbatim: "\(rec.severity) recommendation: \(rec.title). \(rec.detail)"))
    }

    // MARK: - Sandbox Limited

    private var sandboxLimitedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Actions")
                .font(.headline)

            HStack(spacing: 12) {
                Image(systemName: "lock.shield")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Limited in App Store Build")
                        .font(.subheadline.bold())
                    Text("Memory purge, DNS flush, and cache clearing require system privileges not available in sandboxed apps. Use Terminal for these operations.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Quick Actions

    private var quickActionsRow: some View {
        HStack(spacing: 12) {
            actionCard(
                title: "Purge Memory",
                icon: "memorychip",
                color: .blue,
                subtitle: purgeResult,
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
                            purgeResult = "Freed ~\(FormatHelpers.bytes(delta))"
                        } else {
                            purgeResult = "Failed (may need privileges)"
                        }
                        isPurging = false
                    }
                }
            }

            actionCard(
                title: "Flush DNS",
                icon: "network",
                color: .purple,
                subtitle: dnsResult,
                isBusy: isFlushingDNS
            ) {
                guard !isFlushingDNS else { return }
                isFlushingDNS = true
                dnsResult = nil
                Task.detached {
                    let ok = ProcessHelper.flushDNSCache()
                    await MainActor.run {
                        dnsResult = ok ? "DNS cache flushed" : "Failed"
                        isFlushingDNS = false
                    }
                }
            }

            actionCard(
                title: "Clear Caches",
                icon: "xmark.bin",
                color: .orange,
                subtitle: cacheResult ?? cacheSubtitle,
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
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    if isBusy {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 18))
                            .foregroundStyle(color)
                    }
                }

                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(.primary)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text(" ")
                        .font(.caption2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
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
                ContentUnavailableView(
                    "No Process Data",
                    systemImage: "list.number",
                    description: Text("Waiting for process data...")
                )
            } else {
                HStack(alignment: .top, spacing: 16) {
                    if !topCPU.isEmpty {
                        hogColumn(
                            title: "Top CPU",
                            icon: "cpu",
                            color: .blue,
                            processes: topCPU,
                            metric: { FormatHelpers.percent($0.cpuUsage) },
                            bar: { $0.cpuUsage },
                            barColor: { u in u > 0.5 ? .red : u > 0.2 ? .orange : .blue }
                        )
                    }
                    if !topMem.isEmpty {
                        hogColumn(
                            title: "Top Memory",
                            icon: "memorychip",
                            color: .orange,
                            processes: topMem,
                            metric: { FormatHelpers.bytes($0.memoryBytes) },
                            bar: { Double($0.memoryBytes) / Double(max(monitor.currentSnapshot.memory.total, 1)) },
                            barColor: { f in f > 0.3 ? .red : f > 0.1 ? .orange : .orange.opacity(0.7) }
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
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.subheadline.bold())
                .foregroundStyle(color)

            ForEach(processes) { proc in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(proc.name)
                            .font(.system(.body, design: .monospaced))
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
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                            .help("Terminate \(proc.name)")
                            .accessibilityLabel("Terminate \(proc.name)")
                        }
                    }

                    let value = min(bar(proc), 1.0)
                    ProgressView(value: value)
                        .tint(barColor(value))

                    HStack {
                        Text("PID \(proc.pid)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(metric(proc))
                            .font(.caption.monospacedDigit().bold())
                            .foregroundStyle(barColor(value))
                    }
                }
                .padding(10)
                .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
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
                cacheResult = "Freed \(FormatHelpers.bytes(freed))"
                cacheSize = newSize
                isClearingCaches = false
            }
        }
    }

    private func severityColor(_ severity: Recommendation.Severity) -> Color {
        switch severity {
        case .info: .green
        case .warning: .orange
        case .critical: .red
        }
    }
}
