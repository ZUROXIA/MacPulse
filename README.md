# MacPulse

A lightweight macOS menu bar app for real-time system monitoring. Built with Swift and SwiftUI, no Electron, no web views — just native performance.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

**Menu Bar**
- Live CPU, memory, and network stats in the menu bar
- Optional mini graph mode showing CPU history
- Click to expand the monitoring popover with sparkline charts

**Detailed Monitoring**
- **CPU** — Per-core usage, total utilization, temperature, fan speeds
- **Memory** — Used/free/wired breakdown, pressure level indicator
- **Disk** — Volume capacity, read/write I/O rates
- **Network** — Per-interface throughput, cumulative transfer totals
- **Battery** — Charge level, power source, cycle count, health
- **GPU** — Utilization percentage, VRAM usage
- **Thermal** — System thermal state with history
- **Processes** — Top processes by CPU and memory, sortable table

**Additional**
- Historical data persistence via SQLite (survives restarts)
- CSV export for all metrics
- Configurable alerts (CPU >90% sustained, disk >95% full)
- Customizable update interval (1s–10s)
- Launch at login support
- VoiceOver accessible gauges and charts
- Automatic update checking via GitHub Releases (DMG builds)
- App Store version with sandbox-aware graceful degradation

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
make test      # Run test suite (205 assertions)
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
                        # Temperature, Thermal, DiskIO, Process
    Models/             # Metric structs (all Sendable)
    Services/           # SystemMonitor, MetricsHistory, MetricsStore,
                        # AlertManager, CSVExporter, UpdateChecker,
                        # AppSettings
    Utilities/          # SMCHelper, MachHelpers
    Views/
      MenuBar/          # Popover and quick stats
      Detail/           # Full detail window (CPU, Memory, Disk, etc.)
      Shared/           # GaugeView, LiveChart, DualLineChart,
                        # SparklineView, MenuBarGraphView
  MacPulseApp/          # @main entry point, Settings scene
  MacPulseWidget/       # WidgetKit extension (requires Xcode)
Tests/
  MacPulseTests/        # 205 assertions across all collectors
```

**Key design decisions:**
- `@Observable` (macOS 14 Observation framework) for reactive UI
- `@MainActor` isolation on SystemMonitor for thread safety
- Ring buffer with pre-computed ordered snapshots for O(1) reads
- Direct IOKit/Mach/proc APIs — no shelling out to system commands
- SQLite3 (system library) for persistence — no SPM dependencies

## Configuration

Open Settings (`Cmd+,`) to configure:

| Setting | Default | Description |
|---------|---------|-------------|
| Update interval | 2s | How often metrics are sampled |
| Menu bar mode | Text | Text stats or mini graph |
| Show CPU % | On | Toggle CPU in menu bar |
| Show Memory % | Off | Toggle memory in menu bar |
| Show Network | Off | Toggle network rate in menu bar |
| CPU alert | On | Notify when CPU >90% for 30s |
| Disk alert | On | Notify when any volume >95% full |
| Launch at login | Off | Start MacPulse on system boot |

## App Store vs DMG

The App Store version runs inside an App Sandbox. Some features that require elevated privileges are gracefully limited:

| Feature | DMG | App Store |
|---------|-----|-----------|
| CPU / Memory / Disk / Network monitoring | Yes | Yes |
| Battery / Thermal / GPU stats | Yes | Yes |
| Process list (top by CPU/memory) | Yes | Limited |
| Terminate processes | Yes | No |
| Purge memory | Yes | No |
| Flush DNS cache | Yes | No |
| Clear user caches | Yes | No |
| Temperature / fan via SMC | Yes | No |
| Update checking | GitHub Releases | App Store |

The App Store build shows an informational message where unavailable features would appear, and hides terminate buttons.

## Requirements

- macOS 14.0 Sonoma or later
- Apple Silicon or Intel Mac

## License

MIT
