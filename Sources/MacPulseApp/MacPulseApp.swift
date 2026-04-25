import SwiftUI
import MacPulseCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    var openDetailWindow: (() -> Void)?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
        // Small delay to let SwiftUI scenes register
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            openDetailWindow?()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if UserDefaults.standard.bool(forKey: "fan.forcedActive") {
            SMCHelper.setFanMode(forced: false)
            UserDefaults.standard.set(false, forKey: "fan.forcedActive")
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            openDetailWindow?()
            NSApp.activate(ignoringOtherApps: true)
        }
        return true
    }
}

@main
struct MacPulseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var monitor = SystemMonitor()
    @State private var appState = AppState()
    @State private var settings = AppSettings()
    @State private var updateChecker = UpdateChecker()
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(monitor: monitor, appState: appState)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "gauge.medium")
                if monitor.isReady {
                    if settings.menuBarGraphMode {
                        MenuBarGraphView(
                            data: Array(monitor.history.cpuHistory.suffix(20).map(\.1))
                        )
                    } else {
                        if settings.showCPUInMenuBar {
                            Text(FormatHelpers.percentInt(monitor.currentSnapshot.cpu.totalUsage))
                                .monospacedDigit()
                        }
                        if settings.showMemoryInMenuBar {
                            Text("M:" + FormatHelpers.percentInt(monitor.currentSnapshot.memory.usedFraction))
                                .monospacedDigit()
                        }
                        if settings.showNetworkInMenuBar {
                            Text("\u{2191}\(FormatHelpers.bytesPerSecond(monitor.currentSnapshot.network.totalSendRate))")
                                .monospacedDigit()
                        }
                    }
                }
            }
            .onAppear {
                monitor.start()
                appDelegate.openDetailWindow = { [openWindow] in
                    openWindow(id: "detail")
                }
                // Open on launch
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "detail")
                }
            }
        }
        .menuBarExtraStyle(.window)

        Window("MacPulse — System Monitor", id: "detail") {
            DetailWindow(monitor: monitor, appState: appState)
                .frame(minWidth: 700, minHeight: 500)
        }
        .defaultSize(width: 800, height: 600)

        Settings {
            VStack(spacing: 0) {
                SettingsView(monitor: monitor, settings: settings)
                Divider().background(ZuroxiaTheme.borderFaint)
                HStack {
                    CheckForUpdatesView(updateChecker: updateChecker)
                        .font(ZuroxiaTheme.font(10, weight: .bold))
                        .foregroundStyle(ZuroxiaTheme.cyan)
                    Spacer()
                    Text("v\(updateChecker.currentVersion)")
                        .font(ZuroxiaTheme.font(10, weight: .bold))
                        .foregroundStyle(ZuroxiaTheme.textMuted)
                }
                .padding()
            }
            .frame(width: 400, height: 500)
            .applyZuroxiaEnvironment()
        }
    }

    init() {
        _monitor = State(initialValue: SystemMonitor())
        _appState = State(initialValue: AppState())
        _settings = State(initialValue: AppSettings())
        _updateChecker = State(initialValue: UpdateChecker())
    }
}
