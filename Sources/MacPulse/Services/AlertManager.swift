import Foundation
import UserNotifications

@MainActor
@Observable
public final class AlertManager {
    public var cpuAlertEnabled: Bool {
        didSet { UserDefaults.standard.set(cpuAlertEnabled, forKey: "cpuAlertEnabled") }
    }
    public var diskAlertEnabled: Bool {
        didSet { UserDefaults.standard.set(diskAlertEnabled, forKey: "diskAlertEnabled") }
    }

    public var cpuThreshold: Double = 0.9
    public var cpuSustainedSeconds: TimeInterval = 30

    private var highCPUSince: Date?
    private var lastCPUAlertTime: Date?
    private var lastDiskAlertTime: Date?
    private var hasRequestedPermission = false

    /// Minimum interval between repeated alerts of the same type.
    private let alertCooldown: TimeInterval = 300 // 5 minutes

    public init() {
        let defaults = UserDefaults.standard
        self.cpuAlertEnabled = defaults.object(forKey: "cpuAlertEnabled") != nil
            ? defaults.bool(forKey: "cpuAlertEnabled")
            : true
        self.diskAlertEnabled = defaults.object(forKey: "diskAlertEnabled") != nil
            ? defaults.bool(forKey: "diskAlertEnabled")
            : true
        // Don't request notification permission here — defer until first alert
    }

    /// Request notification permission lazily, only when we actually need to send.
    private func ensurePermission() {
        guard !hasRequestedPermission else { return }
        hasRequestedPermission = true
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    public func evaluate(snapshot: SystemSnapshot) {
        if cpuAlertEnabled {
            evaluateCPU(snapshot.cpu.totalUsage)
        }
        if diskAlertEnabled {
            evaluateDisk(snapshot.disk)
        }
    }

    // MARK: - CPU Alert

    private func evaluateCPU(_ usage: Double) {
        let now = Date()

        if usage > cpuThreshold {
            if highCPUSince == nil {
                highCPUSince = now
            }
            if let since = highCPUSince,
               now.timeIntervalSince(since) >= cpuSustainedSeconds,
               shouldSendAlert(lastTime: lastCPUAlertTime) {
                sendNotification(
                    title: "High CPU Usage",
                    body: "CPU has been above \(FormatHelpers.percentInt(cpuThreshold)) for \(Int(cpuSustainedSeconds))s (currently \(FormatHelpers.percentInt(usage)))"
                )
                lastCPUAlertTime = now
                highCPUSince = nil
            }
        } else {
            highCPUSince = nil
        }
    }

    // MARK: - Disk Alert

    private func evaluateDisk(_ disk: DiskMetrics) {
        for volume in disk.volumes {
            if volume.usedFraction > 0.95 && shouldSendAlert(lastTime: lastDiskAlertTime) {
                sendNotification(
                    title: "Disk Almost Full",
                    body: "\(volume.name) is \(FormatHelpers.percentInt(volume.usedFraction)) full (\(FormatHelpers.bytes(volume.freeBytes)) free)"
                )
                lastDiskAlertTime = Date()
                break
            }
        }
    }

    // MARK: - Helpers

    private func shouldSendAlert(lastTime: Date?) -> Bool {
        guard let last = lastTime else { return true }
        return Date().timeIntervalSince(last) >= alertCooldown
    }

    private func sendNotification(title: String, body: String) {
        ensurePermission()

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}
