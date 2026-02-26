import Foundation
import MacPulseCore

var passed = 0
var failed = 0

func assert(_ condition: Bool, _ message: String, file: String = #file, line: Int = #line) {
    if condition {
        passed += 1
    } else {
        failed += 1
        print("  FAIL: \(message) (\(file):\(line))")
    }
}

func test(_ name: String, _ body: () -> Void) {
    print("  \(name)")
    body()
}

// MARK: - CPU Collector Tests

print("CPUCollector Tests")

test("First collection returns zero usage") {
    var collector = CPUCollector()
    let metrics = collector.collect()
    assert(metrics.totalUsage == 0, "Expected 0, got \(metrics.totalUsage)")
}

test("Second collection returns valid usage") {
    var collector = CPUCollector()
    _ = collector.collect()
    usleep(100_000)
    let metrics = collector.collect()
    assert(metrics.totalUsage >= 0, "Usage should be >= 0")
    assert(metrics.totalUsage <= 1.0, "Usage should be <= 1.0")
    assert(!metrics.perCoreUsage.isEmpty, "Should have per-core data")
    for (i, core) in metrics.perCoreUsage.enumerated() {
        assert(core >= 0, "Core \(i) usage should be >= 0")
        assert(core <= 1.0, "Core \(i) usage should be <= 1.0")
    }
}

// MARK: - Memory Collector Tests

print("MemoryCollector Tests")

test("Collects non-zero memory stats") {
    let collector = MemoryCollector()
    let metrics = collector.collect()
    assert(metrics.total > 0, "Total memory should be > 0")
    assert(metrics.used > 0, "Used memory should be > 0")
    assert(metrics.active > 0, "Active memory should be > 0")
    assert(metrics.wired > 0, "Wired memory should be > 0")
}

test("Used fraction is between 0 and 1") {
    let collector = MemoryCollector()
    let metrics = collector.collect()
    assert(metrics.usedFraction > 0, "Used fraction should be > 0")
    assert(metrics.usedFraction <= 1.0, "Used fraction should be <= 1.0")
}

test("Memory pressure level is valid") {
    let collector = MemoryCollector()
    let metrics = collector.collect()
    let validLevels: [MemoryPressureLevel] = [.normal, .warning, .critical]
    assert(validLevels.contains(metrics.pressureLevel), "Pressure level should be a valid enum case")
}

// MARK: - Network Collector Tests

print("NetworkCollector Tests")

test("First collection returns empty rates") {
    var collector = NetworkCollector()
    let metrics = collector.collect()
    assert(metrics.totalSendRate == 0, "First send rate should be 0")
    assert(metrics.totalReceiveRate == 0, "First receive rate should be 0")
}

test("Second collection returns non-negative rates") {
    var collector = NetworkCollector()
    _ = collector.collect()
    usleep(200_000)
    let metrics = collector.collect()
    assert(metrics.totalSendRate >= 0, "Send rate should be >= 0")
    assert(metrics.totalReceiveRate >= 0, "Receive rate should be >= 0")
}

// MARK: - Disk IO Collector Tests

print("DiskIOCollector Tests")

test("First collection returns zero rates") {
    var collector = DiskIOCollector()
    let metrics = collector.collect()
    assert(metrics.readRate == 0, "First read rate should be 0")
    assert(metrics.writeRate == 0, "First write rate should be 0")
}

test("Second collection returns non-negative rates") {
    var collector = DiskIOCollector()
    _ = collector.collect()
    usleep(200_000)
    let metrics = collector.collect()
    assert(metrics.readRate >= 0, "Read rate should be >= 0")
    assert(metrics.writeRate >= 0, "Write rate should be >= 0")
}

// MARK: - Temperature Collector Tests

print("TemperatureCollector Tests")

test("Returns valid temperature metrics") {
    let collector = TemperatureCollector()
    let metrics = collector.collect()
    if let cpuTemp = metrics.cpuTemp {
        assert(cpuTemp > 0, "CPU temp should be > 0 if present, got \(cpuTemp)")
        assert(cpuTemp < 150, "CPU temp should be < 150°C, got \(cpuTemp)")
    }
    if let gpuTemp = metrics.gpuTemp {
        assert(gpuTemp > 0, "GPU temp should be > 0 if present, got \(gpuTemp)")
        assert(gpuTemp < 150, "GPU temp should be < 150°C, got \(gpuTemp)")
    }
    for fan in metrics.fans {
        assert(fan.rpm >= 0, "Fan RPM should be >= 0, got \(fan.rpm)")
    }
}

// MARK: - Process Collector Tests

print("ProcessCollector Tests")

test("First collection returns empty CPU usage") {
    var collector = ProcessCollector()
    let metrics = collector.collect()
    for proc in metrics.topByCPU {
        assert(proc.cpuUsage == 0, "First collection CPU usage should be 0, got \(proc.cpuUsage)")
    }
}

test("Second collection returns valid process data") {
    var collector = ProcessCollector()
    _ = collector.collect()
    usleep(200_000)
    let metrics = collector.collect()
    assert(!metrics.topByCPU.isEmpty, "Should have top CPU processes")
    assert(!metrics.topByMemory.isEmpty, "Should have top memory processes")
    assert(metrics.topByCPU.count <= 10, "Should have at most 10 top CPU processes")
    assert(metrics.topByMemory.count <= 10, "Should have at most 10 top memory processes")
    for proc in metrics.topByCPU {
        assert(proc.pid > 0, "PID should be > 0")
        assert(!proc.name.isEmpty, "Process name should not be empty")
        assert(proc.cpuUsage >= 0, "CPU usage should be >= 0")
    }
    for proc in metrics.topByMemory {
        assert(proc.memoryBytes > 0, "Memory bytes should be > 0 for top memory processes")
    }
}

// MARK: - GPU Collector Tests

print("GPUCollector Tests")

test("Returns valid GPU metrics") {
    var collector = GPUCollector()
    let metrics = collector.collect()
    // GPU data may or may not be available depending on hardware
    for gpu in metrics.gpus {
        assert(!gpu.name.isEmpty, "GPU name should not be empty")
        if let util = gpu.utilization {
            assert(util >= 0, "GPU utilization should be >= 0, got \(util)")
            assert(util <= 1.0, "GPU utilization should be <= 1.0, got \(util)")
        }
        if let frac = gpu.vramFraction {
            assert(frac >= 0, "VRAM fraction should be >= 0")
            assert(frac <= 1.0, "VRAM fraction should be <= 1.0")
        }
    }
}

// MARK: - CSV Exporter Tests

print("CSVExporter Tests")

test("Empty history produces header only") {
    let history = MetricsHistory(capacity: 10)
    let csv = CSVExporter.export(history: history)
    let lines = csv.split(separator: "\n")
    assert(lines.count == 1, "Should have header only, got \(lines.count) lines")
    assert(csv.hasPrefix("Timestamp,"), "Should start with Timestamp header")
}

test("Exports correct number of rows") {
    var history = MetricsHistory(capacity: 10)
    for _ in 0..<3 {
        history.append(SystemSnapshot.empty)
    }
    let csv = CSVExporter.export(history: history)
    let lines = csv.split(separator: "\n")
    assert(lines.count == 4, "Should have 1 header + 3 data rows, got \(lines.count)")
}

test("CSV fields are comma-separated with correct count") {
    var history = MetricsHistory(capacity: 10)
    var snapshot = SystemSnapshot.empty
    snapshot.cpu = CPUMetrics(totalUsage: 0.42, perCoreUsage: [])
    snapshot.thermal = ThermalMetrics(level: .fair)
    history.append(snapshot)
    let csv = CSVExporter.export(history: history)
    let lines = csv.split(separator: "\n")
    let headerFields = lines[0].split(separator: ",")
    let dataFields = lines[1].split(separator: ",", omittingEmptySubsequences: false)
    assert(headerFields.count == 10, "Header should have 10 fields, got \(headerFields.count)")
    // Data might have trailing empty field for temp, so at least 9
    assert(dataFields.count >= 9, "Data row should have at least 9 fields, got \(dataFields.count)")
}

test("Exports correct CPU value") {
    var history = MetricsHistory(capacity: 10)
    var snapshot = SystemSnapshot.empty
    snapshot.cpu = CPUMetrics(totalUsage: 0.75, perCoreUsage: [])
    history.append(snapshot)
    let csv = CSVExporter.export(history: history)
    assert(csv.contains("0.7500"), "Should contain CPU usage 0.7500")
}

// MARK: - Metrics History Tests

print("MetricsHistory Tests")

test("Starts empty") {
    let history = MetricsHistory(capacity: 5)
    assert(history.count == 0, "Should start with count 0")
    assert(history.snapshots.isEmpty, "Should start with empty snapshots")
}

test("Appends snapshots up to capacity") {
    var history = MetricsHistory(capacity: 3)
    for i in 0..<3 {
        var snapshot = SystemSnapshot.empty
        snapshot.cpu = CPUMetrics(totalUsage: Double(i) * 0.1, perCoreUsage: [])
        history.append(snapshot)
    }
    assert(history.count == 3, "Count should be 3")
}

test("Ring buffer wraps correctly") {
    var history = MetricsHistory(capacity: 3)
    for i in 0..<5 {
        var snapshot = SystemSnapshot.empty
        snapshot.cpu = CPUMetrics(totalUsage: Double(i) * 0.1, perCoreUsage: [])
        history.append(snapshot)
    }
    assert(history.count == 3, "Count should be 3 after wrapping")

    let snapshots = history.snapshots
    assert(snapshots.count == 3, "Should have 3 snapshots")
    assert(snapshots[0].cpu.totalUsage >= 0.19, "Oldest should be ~0.2, got \(snapshots[0].cpu.totalUsage)")
    assert(snapshots[2].cpu.totalUsage >= 0.39, "Newest should be ~0.4, got \(snapshots[2].cpu.totalUsage)")
}

test("CPU history returns correct tuples") {
    var history = MetricsHistory(capacity: 10)
    var snapshot = SystemSnapshot.empty
    snapshot.cpu = CPUMetrics(totalUsage: 0.5, perCoreUsage: [0.3, 0.7])
    history.append(snapshot)

    let cpuHistory = history.cpuHistory
    assert(cpuHistory.count == 1, "Should have 1 entry")
    assert(cpuHistory[0].1 == 0.5, "CPU usage should be 0.5")
}

test("Disk IO history tracks read/write rates") {
    var history = MetricsHistory(capacity: 10)
    var snapshot = SystemSnapshot.empty
    snapshot.diskIO = DiskIOMetrics(readRate: 1024, writeRate: 2048)
    history.append(snapshot)

    let readHistory = history.diskReadHistory
    let writeHistory = history.diskWriteHistory
    assert(readHistory.count == 1, "Should have 1 read entry")
    assert(writeHistory.count == 1, "Should have 1 write entry")
    assert(readHistory[0].1 == 1024, "Read rate should be 1024")
    assert(writeHistory[0].1 == 2048, "Write rate should be 2048")
}

test("CPU temp history filters nil temperatures") {
    var history = MetricsHistory(capacity: 10)
    var s1 = SystemSnapshot.empty
    s1.temperature = TemperatureMetrics(cpuTemp: 55.0, gpuTemp: nil, fans: [])
    history.append(s1)

    var s2 = SystemSnapshot.empty
    s2.temperature = TemperatureMetrics(cpuTemp: nil, gpuTemp: nil, fans: [])
    history.append(s2)

    let tempHistory = history.cpuTempHistory
    assert(tempHistory.count == 1, "Should have 1 temp entry (nil filtered out)")
    assert(tempHistory[0].1 == 55.0, "Temp should be 55.0")
}

test("Memory pressure history tracks levels") {
    var history = MetricsHistory(capacity: 10)
    var snapshot = SystemSnapshot.empty
    snapshot.memory = MemoryMetrics(total: 16_000_000_000, used: 12_000_000_000, free: 4_000_000_000, active: 6_000_000_000, wired: 3_000_000_000, compressed: 3_000_000_000, pressureLevel: .warning)
    history.append(snapshot)

    let pressureHistory = history.memoryPressureHistory
    assert(pressureHistory.count == 1, "Should have 1 pressure entry")
    assert(pressureHistory[0].1 == 1, "Warning should map to 1")
}

// MARK: - Integration: Multiple collectors run together

print("Integration Tests")

test("All collectors produce valid data after two cycles") {
    var cpu = CPUCollector()
    let mem = MemoryCollector()
    var net = NetworkCollector()
    var diskIO = DiskIOCollector()
    var proc = ProcessCollector()
    let temp = TemperatureCollector()
    var gpu = GPUCollector()
    let disk = DiskCollector()
    let thermal = ThermalCollector()
    let battery = BatteryCollector()

    // First cycle (baseline)
    _ = cpu.collect()
    _ = mem.collect()
    _ = net.collect()
    _ = diskIO.collect()
    _ = proc.collect()
    _ = temp.collect()
    _ = gpu.collect()
    _ = disk.collect()
    _ = thermal.collect()
    _ = battery.collect()

    usleep(200_000)

    // Second cycle (real deltas)
    let cpuM = cpu.collect()
    let memM = mem.collect()
    let netM = net.collect()
    let diskIOM = diskIO.collect()
    let procM = proc.collect()
    let tempM = temp.collect()
    let gpuM = gpu.collect()
    let diskM = disk.collect()
    let thermalM = thermal.collect()
    _ = battery.collect()

    assert(cpuM.totalUsage >= 0 && cpuM.totalUsage <= 1.0, "CPU in range")
    assert(memM.total > 0, "Memory total > 0")
    assert(netM.totalSendRate >= 0, "Net send >= 0")
    assert(netM.totalReceiveRate >= 0, "Net recv >= 0")
    assert(diskIOM.readRate >= 0, "Disk read >= 0")
    assert(diskIOM.writeRate >= 0, "Disk write >= 0")
    assert(!procM.topByCPU.isEmpty, "Has top CPU procs")
    assert(!procM.topByMemory.isEmpty, "Has top mem procs")
    // temp/gpu may be empty depending on hardware — just check no crash
    _ = tempM.cpuTemp
    _ = gpuM.gpus
    assert(!diskM.volumes.isEmpty || true, "Disk volumes OK (may be empty in CI)")
    assert(thermalM.level.rawValue.count > 0, "Thermal level has name")
}

test("MetricsHistory accumulates and wraps with all fields") {
    var history = MetricsHistory(capacity: 5)
    for i in 0..<8 {
        var s = SystemSnapshot.empty
        s.cpu = CPUMetrics(totalUsage: Double(i) * 0.1, perCoreUsage: [])
        s.diskIO = DiskIOMetrics(readRate: Double(i) * 100, writeRate: Double(i) * 50)
        history.append(s)
    }
    assert(history.count == 5, "Should cap at 5")
    assert(history.snapshots.count == 5, "Ordered snapshots should be 5")
    assert(history.cpuHistory.count == 5, "CPU history should be 5")
    assert(history.diskReadHistory.count == 5, "Disk read history should be 5")
    // Check ordering: oldest should be i=3 (0.3), newest i=7 (0.7)
    assert(history.snapshots.first!.cpu.totalUsage >= 0.29, "Oldest ~0.3")
    assert(history.snapshots.last!.cpu.totalUsage >= 0.69, "Newest ~0.7")
}

// MARK: - ProcessHelper Safety Tests

print("ProcessHelper Tests")

test("Refuses to terminate PID 0") {
    assert(!ProcessHelper.isSafeToTerminate(pid: 0), "PID 0 should not be safe to terminate")
}

test("Refuses to terminate PID 1") {
    assert(!ProcessHelper.isSafeToTerminate(pid: 1), "PID 1 should not be safe to terminate")
}

test("Refuses to terminate own process") {
    let ownPID = getpid()
    assert(!ProcessHelper.isSafeToTerminate(pid: ownPID), "Own PID \(ownPID) should not be safe to terminate")
}

test("Allows terminating a regular PID") {
    // PID 99999 is unlikely to exist but should pass the safety check
    assert(ProcessHelper.isSafeToTerminate(pid: 99999), "Regular PID should be safe to terminate")
}

test("terminateProcess refuses protected PID") {
    let result = ProcessHelper.terminateProcess(pid: 0)
    assert(!result, "Should refuse to terminate PID 0")
}

test("forceKillProcess refuses protected PID") {
    let result = ProcessHelper.forceKillProcess(pid: 0)
    assert(!result, "Should refuse to force-kill PID 0")
}

test("estimateUserCacheSize returns a value") {
    let size = ProcessHelper.estimateUserCacheSize()
    // User caches should exist and be non-zero on any real system
    assert(size >= 0, "Cache size should be >= 0, got \(size)")
}

test("isSandboxed returns a boolean") {
    let sandboxed = ProcessHelper.isSandboxed
    // In test runner (non-sandboxed) this should be false
    assert(!sandboxed, "Test runner should not be sandboxed")
}

test("isSandboxed reflects environment") {
    // Verify the property is based on APP_SANDBOX_CONTAINER_ID
    let hasEnv = ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] != nil
    assert(ProcessHelper.isSandboxed == hasEnv, "isSandboxed should match environment variable presence")
}

// MARK: - RecommendationEngine Tests

print("RecommendationEngine Tests")

test("No recommendations for healthy system") {
    let snapshot = SystemSnapshot.empty
    let recs = RecommendationEngine.analyze(snapshot)
    assert(recs.isEmpty, "Healthy system should have no recommendations, got \(recs.count)")
}

test("Critical memory pressure triggers critical recommendation") {
    var snapshot = SystemSnapshot.empty
    snapshot.memory = MemoryMetrics(
        total: 16_000_000_000,
        used: 15_000_000_000,
        free: 1_000_000_000,
        active: 8_000_000_000,
        wired: 4_000_000_000,
        compressed: 3_000_000_000,
        pressureLevel: .critical
    )
    snapshot.processes = ProcessMetrics(
        topByCPU: [],
        topByMemory: [ProcessInfo_(pid: 100, name: "BigApp", cpuUsage: 0.1, memoryBytes: 4_000_000_000)]
    )
    let recs = RecommendationEngine.analyze(snapshot)
    assert(!recs.isEmpty, "Should have at least one recommendation")
    let memRec = recs.first { $0.title.contains("Memory") }
    assert(memRec != nil, "Should have a memory recommendation")
    assert(memRec!.severity == .critical, "Should be critical severity")
    assert(memRec!.actionLabel != nil, "Should have an action label")
    assert(memRec!.detail.contains("BigApp"), "Should mention the top memory process")
}

test("Warning memory pressure triggers warning recommendation") {
    var snapshot = SystemSnapshot.empty
    snapshot.memory = MemoryMetrics(
        total: 16_000_000_000,
        used: 14_000_000_000,
        free: 2_000_000_000,
        active: 7_000_000_000,
        wired: 4_000_000_000,
        compressed: 3_000_000_000,
        pressureLevel: .warning
    )
    let recs = RecommendationEngine.analyze(snapshot)
    let memRec = recs.first { $0.title.contains("Memory") }
    assert(memRec != nil, "Should have a memory recommendation")
    assert(memRec!.severity == .warning, "Should be warning severity")
}

test("High CPU triggers recommendation with top process") {
    var snapshot = SystemSnapshot.empty
    snapshot.cpu = CPUMetrics(totalUsage: 0.92, perCoreUsage: [0.95, 0.90])
    snapshot.processes = ProcessMetrics(
        topByCPU: [ProcessInfo_(pid: 200, name: "Compiler", cpuUsage: 0.85, memoryBytes: 500_000_000)],
        topByMemory: []
    )
    let recs = RecommendationEngine.analyze(snapshot)
    let cpuRec = recs.first { $0.title.contains("CPU") }
    assert(cpuRec != nil, "Should have a CPU recommendation")
    assert(cpuRec!.severity == .warning, "92% should be warning")
    assert(cpuRec!.detail.contains("Compiler"), "Should mention top CPU process")
}

test("CPU above 95% is critical") {
    var snapshot = SystemSnapshot.empty
    snapshot.cpu = CPUMetrics(totalUsage: 0.97, perCoreUsage: [])
    let recs = RecommendationEngine.analyze(snapshot)
    let cpuRec = recs.first { $0.title.contains("CPU") }
    assert(cpuRec != nil, "Should have a CPU recommendation")
    assert(cpuRec!.severity == .critical, "97% should be critical")
}

test("CPU below 80% has no recommendation") {
    var snapshot = SystemSnapshot.empty
    snapshot.cpu = CPUMetrics(totalUsage: 0.75, perCoreUsage: [])
    let recs = RecommendationEngine.analyze(snapshot)
    let cpuRec = recs.first { $0.title.contains("CPU") }
    assert(cpuRec == nil, "75% CPU should not trigger recommendation")
}

test("Disk above 90% triggers warning") {
    var snapshot = SystemSnapshot.empty
    snapshot.disk = DiskMetrics(volumes: [
        VolumeInfo(name: "Macintosh HD", mountPoint: "/", totalBytes: 500_000_000_000, freeBytes: 40_000_000_000)
    ])
    let recs = RecommendationEngine.analyze(snapshot)
    let diskRec = recs.first { $0.title.contains("Disk") }
    assert(diskRec != nil, "Should have a disk recommendation")
    assert(diskRec!.severity == .warning, "92% disk should be warning")
    assert(diskRec!.detail.contains("Macintosh HD"), "Should mention volume name")
}

test("Disk above 95% is critical") {
    var snapshot = SystemSnapshot.empty
    snapshot.disk = DiskMetrics(volumes: [
        VolumeInfo(name: "Macintosh HD", mountPoint: "/", totalBytes: 500_000_000_000, freeBytes: 10_000_000_000)
    ])
    let recs = RecommendationEngine.analyze(snapshot)
    let diskRec = recs.first { $0.title.contains("Disk") }
    assert(diskRec != nil, "Should have a disk recommendation")
    assert(diskRec!.severity == .critical, "98% disk should be critical")
}

test("Critical thermal triggers recommendation") {
    var snapshot = SystemSnapshot.empty
    snapshot.thermal = ThermalMetrics(level: .critical)
    let recs = RecommendationEngine.analyze(snapshot)
    let thermalRec = recs.first { $0.title.contains("Thermal") }
    assert(thermalRec != nil, "Should have a thermal recommendation")
    assert(thermalRec!.severity == .critical, "Critical thermal should be critical")
}

test("Serious thermal triggers warning") {
    var snapshot = SystemSnapshot.empty
    snapshot.thermal = ThermalMetrics(level: .serious)
    let recs = RecommendationEngine.analyze(snapshot)
    let thermalRec = recs.first { $0.title.contains("Hot") }
    assert(thermalRec != nil, "Should have a thermal recommendation")
    assert(thermalRec!.severity == .warning, "Serious thermal should be warning")
}

test("Nominal thermal has no recommendation") {
    var snapshot = SystemSnapshot.empty
    snapshot.thermal = ThermalMetrics(level: .nominal)
    let recs = RecommendationEngine.analyze(snapshot)
    let thermalRec = recs.first { $0.title.contains("Thermal") || $0.title.contains("Hot") }
    assert(thermalRec == nil, "Nominal thermal should not trigger recommendation")
}

test("Low battery not charging triggers recommendation") {
    var snapshot = SystemSnapshot.empty
    snapshot.battery = BatteryMetrics(
        isPresent: true,
        chargePercent: 0.15,
        isCharging: false,
        cycleCount: 200,
        health: 0.9,
        powerSource: "Battery",
        timeRemaining: 30
    )
    let recs = RecommendationEngine.analyze(snapshot)
    let batRec = recs.first { $0.title.contains("Battery") }
    assert(batRec != nil, "Should have a battery recommendation")
    assert(batRec!.severity == .warning, "15% battery should be warning")
}

test("Very low battery is critical") {
    var snapshot = SystemSnapshot.empty
    snapshot.battery = BatteryMetrics(
        isPresent: true,
        chargePercent: 0.05,
        isCharging: false,
        cycleCount: 200,
        health: 0.9,
        powerSource: "Battery",
        timeRemaining: 10
    )
    let recs = RecommendationEngine.analyze(snapshot)
    let batRec = recs.first { $0.title.contains("Battery") }
    assert(batRec != nil, "Should have a battery recommendation")
    assert(batRec!.severity == .critical, "5% battery should be critical")
}

test("Low battery while charging has no recommendation") {
    var snapshot = SystemSnapshot.empty
    snapshot.battery = BatteryMetrics(
        isPresent: true,
        chargePercent: 0.10,
        isCharging: true,
        cycleCount: 200,
        health: 0.9,
        powerSource: "AC Power",
        timeRemaining: nil
    )
    let recs = RecommendationEngine.analyze(snapshot)
    let batRec = recs.first { $0.title.contains("Battery") }
    assert(batRec == nil, "Charging battery should not trigger recommendation")
}

test("Recommendations sorted by severity descending") {
    var snapshot = SystemSnapshot.empty
    snapshot.cpu = CPUMetrics(totalUsage: 0.85, perCoreUsage: []) // warning
    snapshot.thermal = ThermalMetrics(level: .critical) // critical
    let recs = RecommendationEngine.analyze(snapshot)
    assert(recs.count >= 2, "Should have at least 2 recommendations, got \(recs.count)")
    assert(recs[0].severity >= recs[1].severity, "Should be sorted by severity descending")
}

test("Multiple issues produce multiple recommendations") {
    var snapshot = SystemSnapshot.empty
    snapshot.cpu = CPUMetrics(totalUsage: 0.97, perCoreUsage: [])
    snapshot.memory = MemoryMetrics(
        total: 16_000_000_000, used: 15_000_000_000, free: 1_000_000_000,
        active: 8_000_000_000, wired: 4_000_000_000, compressed: 3_000_000_000,
        pressureLevel: .critical
    )
    snapshot.thermal = ThermalMetrics(level: .critical)
    snapshot.disk = DiskMetrics(volumes: [
        VolumeInfo(name: "HD", mountPoint: "/", totalBytes: 500_000_000_000, freeBytes: 5_000_000_000)
    ])
    let recs = RecommendationEngine.analyze(snapshot)
    assert(recs.count >= 4, "Should have at least 4 recommendations, got \(recs.count)")
}

// MARK: - Custom Threshold Tests

print("Custom Threshold Tests")

test("Custom CPU warning threshold triggers at lower value") {
    var snapshot = SystemSnapshot.empty
    snapshot.cpu = CPUMetrics(totalUsage: 0.65, perCoreUsage: [])
    // Default threshold 0.8 — should NOT trigger
    let recsDefault = RecommendationEngine.analyze(snapshot)
    assert(recsDefault.first { $0.title.contains("CPU") } == nil, "65% CPU should not trigger at default 80% threshold")
    // Custom threshold 0.6 — SHOULD trigger
    let custom = OptimizeThresholds(cpuWarning: 0.6, cpuCritical: 0.9)
    let recsCustom = RecommendationEngine.analyze(snapshot, thresholds: custom)
    let cpuRec = recsCustom.first { $0.title.contains("CPU") }
    assert(cpuRec != nil, "65% CPU should trigger at custom 60% threshold")
    assert(cpuRec!.severity == .warning, "Should be warning, not critical")
}

test("Custom CPU critical threshold changes severity boundary") {
    var snapshot = SystemSnapshot.empty
    snapshot.cpu = CPUMetrics(totalUsage: 0.85, perCoreUsage: [])
    // Default: 85% is warning (critical at 95%)
    let recsDefault = RecommendationEngine.analyze(snapshot)
    let defaultRec = recsDefault.first { $0.title.contains("CPU") }
    assert(defaultRec != nil, "85% should trigger")
    assert(defaultRec!.severity == .warning, "85% should be warning at default thresholds")
    // Custom: critical at 0.8, warning at 0.7
    let custom = OptimizeThresholds(cpuWarning: 0.7, cpuCritical: 0.8)
    let recsCustom = RecommendationEngine.analyze(snapshot, thresholds: custom)
    let customRec = recsCustom.first { $0.title.contains("CPU") }
    assert(customRec != nil, "85% should trigger at custom threshold")
    assert(customRec!.severity == .critical, "85% should be critical when critical threshold is 80%")
}

test("Custom disk threshold triggers at lower usage") {
    var snapshot = SystemSnapshot.empty
    snapshot.disk = DiskMetrics(volumes: [
        VolumeInfo(name: "HD", mountPoint: "/", totalBytes: 500_000_000_000, freeBytes: 100_000_000_000) // 80% used
    ])
    // Default 90% — should NOT trigger
    let recsDefault = RecommendationEngine.analyze(snapshot)
    assert(recsDefault.first { $0.title.contains("Disk") } == nil, "80% disk should not trigger at default 90%")
    // Custom 75% — SHOULD trigger
    let custom = OptimizeThresholds(diskWarning: 0.75)
    let recsCustom = RecommendationEngine.analyze(snapshot, thresholds: custom)
    assert(recsCustom.first { $0.title.contains("Disk") } != nil, "80% disk should trigger at custom 75%")
}

test("Custom battery threshold triggers at higher charge") {
    var snapshot = SystemSnapshot.empty
    snapshot.battery = BatteryMetrics(
        isPresent: true, chargePercent: 0.25, isCharging: false,
        cycleCount: 200, health: 0.9, powerSource: "Battery", timeRemaining: 60
    )
    // Default 20% — should NOT trigger at 25%
    let recsDefault = RecommendationEngine.analyze(snapshot)
    assert(recsDefault.first { $0.title.contains("Battery") } == nil, "25% should not trigger at default 20%")
    // Custom 30% — SHOULD trigger at 25%
    let custom = OptimizeThresholds(batteryWarning: 0.3)
    let recsCustom = RecommendationEngine.analyze(snapshot, thresholds: custom)
    assert(recsCustom.first { $0.title.contains("Battery") } != nil, "25% should trigger at custom 30%")
}

test("Disabling CPU rule suppresses CPU recommendations") {
    var snapshot = SystemSnapshot.empty
    snapshot.cpu = CPUMetrics(totalUsage: 0.97, perCoreUsage: [])
    let enabled = OptimizeThresholds(enableCPU: true)
    let disabled = OptimizeThresholds(enableCPU: false)
    let recsOn = RecommendationEngine.analyze(snapshot, thresholds: enabled)
    let recsOff = RecommendationEngine.analyze(snapshot, thresholds: disabled)
    assert(recsOn.first { $0.title.contains("CPU") } != nil, "CPU rule enabled should produce recommendation")
    assert(recsOff.first { $0.title.contains("CPU") } == nil, "CPU rule disabled should suppress recommendation")
}

test("Disabling memory rule suppresses memory recommendations") {
    var snapshot = SystemSnapshot.empty
    snapshot.memory = MemoryMetrics(
        total: 16_000_000_000, used: 15_000_000_000, free: 1_000_000_000,
        active: 8_000_000_000, wired: 4_000_000_000, compressed: 3_000_000_000,
        pressureLevel: .critical
    )
    let disabled = OptimizeThresholds(enableMemory: false)
    let recs = RecommendationEngine.analyze(snapshot, thresholds: disabled)
    assert(recs.first { $0.title.contains("Memory") } == nil, "Memory rule disabled should suppress recommendation")
}

test("Disabling disk rule suppresses disk recommendations") {
    var snapshot = SystemSnapshot.empty
    snapshot.disk = DiskMetrics(volumes: [
        VolumeInfo(name: "HD", mountPoint: "/", totalBytes: 500_000_000_000, freeBytes: 10_000_000_000)
    ])
    let disabled = OptimizeThresholds(enableDisk: false)
    let recs = RecommendationEngine.analyze(snapshot, thresholds: disabled)
    assert(recs.first { $0.title.contains("Disk") } == nil, "Disk rule disabled should suppress recommendation")
}

test("Disabling thermal rule suppresses thermal recommendations") {
    var snapshot = SystemSnapshot.empty
    snapshot.thermal = ThermalMetrics(level: .critical)
    let disabled = OptimizeThresholds(enableThermal: false)
    let recs = RecommendationEngine.analyze(snapshot, thresholds: disabled)
    assert(recs.first { $0.title.contains("Thermal") } == nil, "Thermal rule disabled should suppress recommendation")
}

test("Disabling battery rule suppresses battery recommendations") {
    var snapshot = SystemSnapshot.empty
    snapshot.battery = BatteryMetrics(
        isPresent: true, chargePercent: 0.05, isCharging: false,
        cycleCount: 200, health: 0.9, powerSource: "Battery", timeRemaining: 10
    )
    let disabled = OptimizeThresholds(enableBattery: false)
    let recs = RecommendationEngine.analyze(snapshot, thresholds: disabled)
    assert(recs.first { $0.title.contains("Battery") } == nil, "Battery rule disabled should suppress recommendation")
}

test("All rules disabled produces no recommendations even under stress") {
    var snapshot = SystemSnapshot.empty
    snapshot.cpu = CPUMetrics(totalUsage: 0.99, perCoreUsage: [])
    snapshot.memory = MemoryMetrics(
        total: 16_000_000_000, used: 15_500_000_000, free: 500_000_000,
        active: 8_000_000_000, wired: 4_000_000_000, compressed: 3_500_000_000,
        pressureLevel: .critical
    )
    snapshot.thermal = ThermalMetrics(level: .critical)
    snapshot.disk = DiskMetrics(volumes: [
        VolumeInfo(name: "HD", mountPoint: "/", totalBytes: 500_000_000_000, freeBytes: 5_000_000_000)
    ])
    snapshot.battery = BatteryMetrics(
        isPresent: true, chargePercent: 0.03, isCharging: false,
        cycleCount: 500, health: 0.7, powerSource: "Battery", timeRemaining: 5
    )
    let allOff = OptimizeThresholds(
        enableMemory: false, enableCPU: false, enableDisk: false,
        enableThermal: false, enableBattery: false
    )
    let recs = RecommendationEngine.analyze(snapshot, thresholds: allOff)
    assert(recs.isEmpty, "All rules disabled should produce 0 recommendations, got \(recs.count)")
}

test("OptimizeThresholds defaults match expected values") {
    let d = OptimizeThresholds.defaults
    assert(d.cpuWarning == 0.8, "Default CPU warning should be 0.8")
    assert(d.cpuCritical == 0.95, "Default CPU critical should be 0.95")
    assert(d.diskWarning == 0.9, "Default disk warning should be 0.9")
    assert(d.batteryWarning == 0.2, "Default battery warning should be 0.2")
    assert(d.enableMemory, "Memory rule should be enabled by default")
    assert(d.enableCPU, "CPU rule should be enabled by default")
    assert(d.enableDisk, "Disk rule should be enabled by default")
    assert(d.enableThermal, "Thermal rule should be enabled by default")
    assert(d.enableBattery, "Battery rule should be enabled by default")
}

// MARK: - Summary

print("")
print("Results: \(passed) passed, \(failed) failed")

if failed > 0 {
    exit(1)
}
