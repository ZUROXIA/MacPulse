# Contributing to MacPulse

Thank you for your interest in contributing to MacPulse! This guide covers everything you need to get started.

## Prerequisites

- macOS 14.0 Sonoma or later
- Xcode 15+ / Swift 5.9+
- Apple Silicon or Intel Mac

## Getting Started

```bash
git clone https://github.com/ZUROXIA/MacPulse.git
cd MacPulse
make run
```

## Build Commands

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

### Key Design Decisions

- `@Observable` (macOS 14 Observation framework) for reactive UI
- `@MainActor` isolation on SystemMonitor for thread safety
- Ring buffer with pre-computed ordered snapshots for O(1) reads
- Direct IOKit/Mach/proc APIs — no shelling out to system commands
- SQLite3 (system library) for persistence — no SPM dependencies

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

## Submitting Changes

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Make your changes
4. Run the tests (`make test`)
5. Commit your changes (`git commit -m 'Add my feature'`)
6. Push to the branch (`git push origin feature/my-feature`)
7. Open a Pull Request

## Reporting Issues

- Use [GitHub Issues](../../issues) for bug reports and feature requests
- Search existing issues before opening a new one
- Provide as much detail as possible (macOS version, hardware, steps to reproduce)
