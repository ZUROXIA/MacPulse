# MacPulse

A high-performance macOS system utility designed for the ZUROXIA Command Deck. Built with native Swift and SwiftUI, MacPulse provides real-time system diagnostics through an aggressive, data-dense Cyberpunk aesthetic.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

**Cyberpunk Command Deck UI**
- **Zuroxia Theme** — A custom-engineered design system featuring chamfered geometric panels, neon glowing accents (Cyan, Purple, Emerald, Crimson), and technical monospaced typography.
- **Dynamic Menu Bar** — Live telemetry pulses in the system tray with customizable mini-graphs and data-streams.

**Defense & Telemetry**
- **Defense Matrix** — Real-time monitoring of the macOS BSD Packet Filter (`pfctl`) and active TCP socket connections (Inbound/Outbound IP mapping).
- **Telemetry Stream** — A live, filtered feed of the macOS unified system log (`/usr/bin/log`), targeting kernel events and application errors.

**Detailed Monitoring**
- **CPU** — Per-core utilization grids, total processor load, core temperatures, and fan RPM controls.
- **Memory** — Active/Wired/Compressed/Free breakdown with real-time memory pressure state mapping.
- **Disk** — Accurate APFS volume capacity tracking (boot and external), plus high-frequency Read/Write I/O throughput.
- **Network** — Interface-specific bandwidth mapping (Wi-Fi, Ethernet, VPN) and total transfer accumulation.
- **Power** — Internal battery health, cycle counts, and **Bluetooth Peripheral Tracking** (AirPods, Magic Mouse, Keyboards).
- **GPU** — Renderer utilization and VRAM allocation statistics.

**Optimization & Tools**
- **System Purge** — Aggressive developer-centric optimization targeting massive caches (Xcode DerivedData, Homebrew, NPM, CocoaPods, Gradle).
- **Network Recovery** — Native DNS cache flushing and memory pressure stabilization.
- **Persistence** — Time-series metric storage via an embedded SQLite3 database (survives restarts).
- **CSV Export** — Full telemetry history export for external performance analysis.

## Install

### Mac App Store

Coming soon.

### From DMG

Download the latest `.dmg` from [Releases](../../releases), open it, and drag MacPulse to Applications.

### From Source

Requires Xcode 15+ / Swift 5.9+ and macOS 14 Sonoma or later.

```bash
git clone https://github.com/ZUROXIA/MacPulse.git
cd MacPulse
make run
```

### Build Commands

```bash
make build     # Compile release binary
make bundle    # Create .app bundle with icon and entitlements
make run       # Build, bundle, and launch
make install   # Copy to /Applications
make dmg       # Create distributable DMG
make test      # Run test suite (248 assertions)
make archive   # Xcode archive for App Store submission
make export    # Export archive for App Store Connect upload
make clean     # Remove build artifacts
```

## Architecture

```
Sources/
  MacPulse/             # Core library (MacPulseCore)
    App/                # AppState
    Collectors/         # CPU, Memory, Disk, Network, Battery, GPU,
                        # Temperature, Thermal, DiskIO, Process, Defense
    Models/             # Metric structs (all Sendable)
    Services/           # SystemMonitor, MetricsHistory, MetricsStore,
                        # AlertManager, CSVExporter, UpdateChecker,
                        # LogStreamService, AppSettings
    Utilities/          # SMCHelper, MachHelpers, ProcessHelper
    Views/
      MenuBar/          # Popover and quick stats
      Detail/           # Full detail window (CPU, Memory, Defense, etc.)
      Shared/           # ZuroxiaTheme, GaugeView, LiveChart, 
                        # DualLineChart, SparklineView
  MacPulseApp/          # @main entry point, Settings scene
```

**Key design decisions:**
- **Zuroxia UI Engine** — Custom `ChamferedRectangle` shape rendering for zero-latency UI performance.
- **Async Data Collection** — Shell-based metrics (netstat/pfctl) offloaded to detached background tasks to prevent UI thread blocking.
- **Swift 6 Ready** — Fully audited for strict concurrency and `Sendable` compliance.
- **No Dependencies** — Uses system libraries (SQLite3, IOKit, Mach) and native Frameworks only.

## App Store vs DMG

The App Store version runs inside an App Sandbox. Some features that require elevated privileges are gracefully limited:

| Feature | DMG | App Store |
|---------|-----|-----------|
| CPU / Memory / Disk / Network monitoring | Yes | Yes |
| Battery / Thermal / GPU stats | Yes | Yes |
| Defense Matrix (Connections) | Yes | Limited |
| Defense Matrix (Firewall rules) | Yes | No |
| Telemetry Stream (System Logs) | Yes | No |
| Terminate processes | Yes | No |
| System Purge (Xcode/NPM/etc) | Yes | No |
| Temperature / fan via SMC | Yes | No |

## Requirements

- macOS 14.0 Sonoma or later
- Apple Silicon or Intel Mac

## License

MIT
