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
    // Temperature may or may not be available depending on hardware/permissions
    if let cpuTemp = metrics.cpuTemp {
        assert(cpuTemp > 0, "CPU temp should be > 0 if present, got \(cpuTemp)")
        assert(cpuTemp < 150, "CPU temp should be < 150°C, got \(cpuTemp)")
    }
    if let gpuTemp = metrics.gpuTemp {
        assert(gpuTemp > 0, "GPU temp should be > 0 if present, got \(gpuTemp)")
        assert(gpuTemp < 150, "GPU temp should be < 150°C, got \(gpuTemp)")
    }
    // fans array is valid even if empty (e.g. fanless MacBooks)
    for fan in metrics.fans {
        assert(fan.rpm >= 0, "Fan RPM should be >= 0, got \(fan.rpm)")
    }
}

// MARK: - Process Collector Tests

print("ProcessCollector Tests")

test("First collection returns empty CPU usage") {
    var collector = ProcessCollector()
    let metrics = collector.collect()
    // First call has no delta, so CPU usage will be 0 for all
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

// MARK: - Summary

print("")
print("Results: \(passed) passed, \(failed) failed")

if failed > 0 {
    exit(1)
}
