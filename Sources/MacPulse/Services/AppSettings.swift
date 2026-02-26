import Foundation
import SwiftUI
import ServiceManagement

@MainActor
@Observable
public final class AppSettings {
    public var updateInterval: TimeInterval {
        didSet { UserDefaults.standard.set(updateInterval, forKey: "updateInterval") }
    }

    public var showCPUInMenuBar: Bool {
        didSet { UserDefaults.standard.set(showCPUInMenuBar, forKey: "showCPUInMenuBar") }
    }

    public var showMemoryInMenuBar: Bool {
        didSet { UserDefaults.standard.set(showMemoryInMenuBar, forKey: "showMemoryInMenuBar") }
    }

    public var showNetworkInMenuBar: Bool {
        didSet { UserDefaults.standard.set(showNetworkInMenuBar, forKey: "showNetworkInMenuBar") }
    }

    public var menuBarGraphMode: Bool {
        didSet { UserDefaults.standard.set(menuBarGraphMode, forKey: "menuBarGraphMode") }
    }

    public var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            updateLoginItem()
        }
    }

    // MARK: - Optimize

    public var cpuWarningThreshold: Double {
        didSet { UserDefaults.standard.set(cpuWarningThreshold, forKey: "opt.cpuWarning") }
    }

    public var cpuCriticalThreshold: Double {
        didSet { UserDefaults.standard.set(cpuCriticalThreshold, forKey: "opt.cpuCritical") }
    }

    public var diskWarningThreshold: Double {
        didSet { UserDefaults.standard.set(diskWarningThreshold, forKey: "opt.diskWarning") }
    }

    public var batteryWarningThreshold: Double {
        didSet { UserDefaults.standard.set(batteryWarningThreshold, forKey: "opt.batteryWarning") }
    }

    public var resourceHogCount: Int {
        didSet { UserDefaults.standard.set(resourceHogCount, forKey: "opt.hogCount") }
    }

    public var confirmBeforeTerminate: Bool {
        didSet { UserDefaults.standard.set(confirmBeforeTerminate, forKey: "opt.confirmTerminate") }
    }

    public var enableMemoryRule: Bool {
        didSet { UserDefaults.standard.set(enableMemoryRule, forKey: "opt.ruleMemory") }
    }

    public var enableCPURule: Bool {
        didSet { UserDefaults.standard.set(enableCPURule, forKey: "opt.ruleCPU") }
    }

    public var enableDiskRule: Bool {
        didSet { UserDefaults.standard.set(enableDiskRule, forKey: "opt.ruleDisk") }
    }

    public var enableThermalRule: Bool {
        didSet { UserDefaults.standard.set(enableThermalRule, forKey: "opt.ruleThermal") }
    }

    public var enableBatteryRule: Bool {
        didSet { UserDefaults.standard.set(enableBatteryRule, forKey: "opt.ruleBattery") }
    }

    public static let intervals: [(String, TimeInterval)] = [
        ("1 second", 1),
        ("2 seconds", 2),
        ("5 seconds", 5),
        ("10 seconds", 10),
    ]

    public static let hogCountOptions = [3, 5, 10]

    public init() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "updateInterval") == nil {
            defaults.set(2.0, forKey: "updateInterval")
        }
        if defaults.object(forKey: "showCPUInMenuBar") == nil {
            defaults.set(true, forKey: "showCPUInMenuBar")
        }
        if defaults.object(forKey: "showMemoryInMenuBar") == nil {
            defaults.set(false, forKey: "showMemoryInMenuBar")
        }
        if defaults.object(forKey: "showNetworkInMenuBar") == nil {
            defaults.set(false, forKey: "showNetworkInMenuBar")
        }

        self.menuBarGraphMode = defaults.bool(forKey: "menuBarGraphMode")
        self.updateInterval = defaults.double(forKey: "updateInterval")
        self.showCPUInMenuBar = defaults.bool(forKey: "showCPUInMenuBar")
        self.showMemoryInMenuBar = defaults.bool(forKey: "showMemoryInMenuBar")
        self.showNetworkInMenuBar = defaults.bool(forKey: "showNetworkInMenuBar")
        self.launchAtLogin = defaults.bool(forKey: "launchAtLogin")

        // Optimize defaults
        self.cpuWarningThreshold = defaults.object(forKey: "opt.cpuWarning") != nil
            ? defaults.double(forKey: "opt.cpuWarning") : 0.8
        self.cpuCriticalThreshold = defaults.object(forKey: "opt.cpuCritical") != nil
            ? defaults.double(forKey: "opt.cpuCritical") : 0.95
        self.diskWarningThreshold = defaults.object(forKey: "opt.diskWarning") != nil
            ? defaults.double(forKey: "opt.diskWarning") : 0.9
        self.batteryWarningThreshold = defaults.object(forKey: "opt.batteryWarning") != nil
            ? defaults.double(forKey: "opt.batteryWarning") : 0.2
        self.resourceHogCount = defaults.object(forKey: "opt.hogCount") != nil
            ? defaults.integer(forKey: "opt.hogCount") : 3
        self.confirmBeforeTerminate = defaults.object(forKey: "opt.confirmTerminate") != nil
            ? defaults.bool(forKey: "opt.confirmTerminate") : true
        self.enableMemoryRule = defaults.object(forKey: "opt.ruleMemory") != nil
            ? defaults.bool(forKey: "opt.ruleMemory") : true
        self.enableCPURule = defaults.object(forKey: "opt.ruleCPU") != nil
            ? defaults.bool(forKey: "opt.ruleCPU") : true
        self.enableDiskRule = defaults.object(forKey: "opt.ruleDisk") != nil
            ? defaults.bool(forKey: "opt.ruleDisk") : true
        self.enableThermalRule = defaults.object(forKey: "opt.ruleThermal") != nil
            ? defaults.bool(forKey: "opt.ruleThermal") : true
        self.enableBatteryRule = defaults.object(forKey: "opt.ruleBattery") != nil
            ? defaults.bool(forKey: "opt.ruleBattery") : true
    }

    private func updateLoginItem() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Silently fail — user may not have permission
        }
    }
}
