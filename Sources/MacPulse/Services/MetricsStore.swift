import Foundation
import SQLite3

/// Persists metrics snapshots to a SQLite database so data survives app restarts.
/// Thread-safe: all operations are serialized on a dedicated queue.
public final class MetricsStore: @unchecked Sendable {
    private var db: OpaquePointer?
    private let path: String
    private let queue = DispatchQueue(label: "com.macpulse.metricsstore")

    public init() {
        let fallback = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? fallback
        let dir = appSupport.appendingPathComponent("MacPulse", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.path = dir.appendingPathComponent("metrics.sqlite").path
        queue.sync {
            openDB()
            createTable()
        }
    }

    deinit {
        let db = self.db
        _ = queue.sync { sqlite3_close(db) }
    }

    private func openDB() {
        sqlite3_open(path, &db)
    }

    private func createTable() {
        let sql = """
        CREATE TABLE IF NOT EXISTS snapshots (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp REAL NOT NULL,
            cpu_usage REAL NOT NULL,
            memory_used_fraction REAL NOT NULL,
            memory_used INTEGER NOT NULL,
            memory_total INTEGER NOT NULL,
            memory_pressure INTEGER NOT NULL DEFAULT 0,
            net_send_rate REAL NOT NULL,
            net_recv_rate REAL NOT NULL,
            disk_read_rate REAL NOT NULL,
            disk_write_rate REAL NOT NULL,
            thermal_level TEXT NOT NULL,
            cpu_temp REAL
        );
        CREATE INDEX IF NOT EXISTS idx_timestamp ON snapshots(timestamp);
        """
        sqlite3_exec(db, sql, nil, nil, nil)
    }

    public func save(_ snapshot: SystemSnapshot) {
        queue.async { [weak self] in
            guard let self, let db = self.db else { return }
            let sql = """
            INSERT INTO snapshots (timestamp, cpu_usage, memory_used_fraction, memory_used, memory_total, memory_pressure, net_send_rate, net_recv_rate, disk_read_rate, disk_write_rate, thermal_level, cpu_temp)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
            """
            var stmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
            defer { sqlite3_finalize(stmt) }

            sqlite3_bind_double(stmt, 1, snapshot.timestamp.timeIntervalSince1970)
            sqlite3_bind_double(stmt, 2, snapshot.cpu.totalUsage)
            sqlite3_bind_double(stmt, 3, snapshot.memory.usedFraction)
            sqlite3_bind_int64(stmt, 4, Int64(snapshot.memory.used))
            sqlite3_bind_int64(stmt, 5, Int64(snapshot.memory.total))
            sqlite3_bind_int(stmt, 6, Int32(snapshot.memory.pressureLevel.rawValue))
            sqlite3_bind_double(stmt, 7, snapshot.network.totalSendRate)
            sqlite3_bind_double(stmt, 8, snapshot.network.totalReceiveRate)
            sqlite3_bind_double(stmt, 9, snapshot.diskIO.readRate)
            sqlite3_bind_double(stmt, 10, snapshot.diskIO.writeRate)
            sqlite3_bind_text(stmt, 11, (snapshot.thermal.level.rawValue as NSString).utf8String, -1, nil)
            if let temp = snapshot.temperature.cpuTemp {
                sqlite3_bind_double(stmt, 12, temp)
            } else {
                sqlite3_bind_null(stmt, 12)
            }

            sqlite3_step(stmt)
        }
    }

    /// Load recent snapshots from the database (last `maxAge` seconds).
    public func loadRecent(maxAge: TimeInterval = 600) -> [SystemSnapshot] {
        queue.sync {
            guard let db else { return [] }
            let cutoff = Date().timeIntervalSince1970 - maxAge
            let sql = "SELECT timestamp, cpu_usage, memory_used_fraction, memory_used, memory_total, memory_pressure, net_send_rate, net_recv_rate, disk_read_rate, disk_write_rate, thermal_level, cpu_temp FROM snapshots WHERE timestamp > ? ORDER BY timestamp ASC;"

            var stmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
            defer { sqlite3_finalize(stmt) }

            sqlite3_bind_double(stmt, 1, cutoff)

            var results: [SystemSnapshot] = []
            while sqlite3_step(stmt) == SQLITE_ROW {
                let timestamp = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 0))
                let cpuUsage = sqlite3_column_double(stmt, 1)
                let memUsed = UInt64(sqlite3_column_int64(stmt, 3))
                let memTotal = UInt64(sqlite3_column_int64(stmt, 4))
                let pressureRaw = Int(sqlite3_column_int(stmt, 5))
                let pressure = MemoryPressureLevel(rawValue: pressureRaw) ?? .normal
                let netSend = sqlite3_column_double(stmt, 6)
                let netRecv = sqlite3_column_double(stmt, 7)
                let diskRead = sqlite3_column_double(stmt, 8)
                let diskWrite = sqlite3_column_double(stmt, 9)

                let thermalStr: String
                if let ptr = sqlite3_column_text(stmt, 10) {
                    thermalStr = String(cString: ptr)
                } else {
                    thermalStr = "Nominal"
                }
                let thermalLevel = ThermalLevel(rawValue: thermalStr) ?? .nominal

                let cpuTemp: Double?
                if sqlite3_column_type(stmt, 11) != SQLITE_NULL {
                    cpuTemp = sqlite3_column_double(stmt, 11)
                } else {
                    cpuTemp = nil
                }

                let memFree = memTotal > memUsed ? memTotal - memUsed : 0
                let snapshot = SystemSnapshot(
                    timestamp: timestamp,
                    cpu: CPUMetrics(totalUsage: cpuUsage, perCoreUsage: []),
                    memory: MemoryMetrics(total: memTotal, used: memUsed, free: memFree, active: 0, wired: 0, compressed: 0, pressureLevel: pressure),
                    disk: .zero,
                    battery: .unavailable,
                    network: NetworkMetrics(interfaces: [], totalSendRate: netSend, totalReceiveRate: netRecv),
                    thermal: ThermalMetrics(level: thermalLevel),
                    diskIO: DiskIOMetrics(readRate: diskRead, writeRate: diskWrite),
                    temperature: TemperatureMetrics(cpuTemp: cpuTemp, gpuTemp: nil, fans: [])
                )
                results.append(snapshot)
            }
            return results
        }
    }

    /// Prune old data (keep last 24 hours).
    public func prune(olderThan: TimeInterval = 86400) {
        queue.async { [weak self] in
            guard let self, let db = self.db else { return }
            let cutoff = Date().timeIntervalSince1970 - olderThan
            let sql = "DELETE FROM snapshots WHERE timestamp < ?;"
            var stmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
            defer { sqlite3_finalize(stmt) }
            sqlite3_bind_double(stmt, 1, cutoff)
            sqlite3_step(stmt)
        }
    }
}
