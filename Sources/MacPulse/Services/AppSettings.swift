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

    public var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            updateLoginItem()
        }
    }

    public static let intervals: [(String, TimeInterval)] = [
        ("1 second", 1),
        ("2 seconds", 2),
        ("5 seconds", 5),
        ("10 seconds", 10),
    ]

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

        self.updateInterval = defaults.double(forKey: "updateInterval")
        self.showCPUInMenuBar = defaults.bool(forKey: "showCPUInMenuBar")
        self.showMemoryInMenuBar = defaults.bool(forKey: "showMemoryInMenuBar")
        self.showNetworkInMenuBar = defaults.bool(forKey: "showNetworkInMenuBar")
        self.launchAtLogin = defaults.bool(forKey: "launchAtLogin")
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
