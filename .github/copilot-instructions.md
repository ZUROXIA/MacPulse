# Copilot Instructions for MacPulse

## Project Overview

MacPulse is a lightweight native macOS menu bar system monitor built with Swift 5.9+ and SwiftUI. It displays real-time CPU, memory, disk, network, battery, GPU, thermal, and process metrics with no external SPM dependencies — only system frameworks (IOKit, StoreKit, Foundation, Darwin, Charts).

- **Requires:** macOS 14 Sonoma+, Xcode 15+ / Swift 5.9+
- **Platforms:** Apple Silicon and Intel

## Build, Run, and Test

All common tasks are driven by `make`:

```bash
make build     # swift build -c release
make bundle    # Assemble .app bundle (icon + entitlements + resources)
make run       # bundle + launch
make install   # Copy to /Applications
make test      # swift build (debug) + run MacPulseTests executable
make dmg       # Create distributable DMG
make archive   # Xcode archive for App Store
make export    # Export archive for App Store Connect
make clean     # Remove .build/ and MacPulse.app
```

Run `make test` to execute all tests. Do **not** use `swift test`; the test target is a standalone executable (`MacPulseTests`), not an XCTest bundle.

## Architecture

```
Sources/
  MacPulse/           # Core library (MacPulseCore)
    App/              # AppState — UI navigation state (@Observable)
    Collectors/       # One per metric: CPUCollector, MemoryCollector, DiskCollector,
                      # NetworkCollector, BatteryCollector, GPUCollector,
                      # TemperatureCollector, ThermalCollector, DiskIOCollector,
                      # ProcessCollector
    Models/           # Sendable value types: CPUMetrics, MemoryMetrics, etc.
    Services/         # SystemMonitor, MetricsHistory, MetricsStore (SQLite),
                      # AlertManager, AppSettings, UpdateChecker, CSVExporter,
                      # RecommendationEngine
    Utilities/        # MachHelpers, SMCHelper, ProcessHelper (IOKit/Mach wrappers)
    Views/
      MenuBar/        # MenuBarView, QuickStatRow
      Detail/         # One detail view per metric tab + SettingsView, OptimizeView
      Shared/         # GaugeView, LiveChart, DualLineChart, SparklineView,
                      # MenuBarGraphView, FormatHelpers
  MacPulseApp/        # @main entry point — MenuBarExtra + Window + Settings scenes
  MacPulseWidget/     # WidgetKit extension (requires Xcode for full build)
Tests/
  MacPulseTests/      # Standalone executable, custom test runner, ~200 assertions
```

### Data flow

1. **Collectors** — stateful (`mutating func collect() -> Metrics`), compute deltas between calls, use Mach/IOKit/proc APIs directly.
2. **SystemMonitor** — `@MainActor @Observable` coordinator; owns all collectors, a repeating `Timer`, `MetricsHistory`, `MetricsStore`, and `AlertManager`.
3. **MetricsHistory** — ring buffer (300 items) with pre-computed history arrays rebuilt once per sample for O(1) view reads.
4. **MetricsStore** — SQLite3 persistence (up to 600 snapshots); loaded on start, written asynchronously via `Task.detached`.
5. **Views** — observe `SystemMonitor` directly; read `monitor.currentSnapshot` and `monitor.history.*`; never call services directly.

## Coding Conventions

### Thread Safety
- `@Observable` (macOS 14 Observation framework) on all observable classes — **not** `ObservableObject`.
- `@MainActor` on UI-bound services: `SystemMonitor`, `AppSettings`, `AlertManager`, `UpdateChecker`.
- All model structs are `Sendable`; use `@unchecked Sendable` only with explicit serial-queue protection.
- Use `Task.detached` for background SQLite / I/O work.

### Naming
- Types: PascalCase with descriptive suffix — `CPUCollector`, `AlertManager`, `GaugeView`, `MachHelpers`.
- Properties/methods: camelCase — `totalUsage`, `usedFraction`, `pressureLevel`.
- Enums: PascalCase type, lowercase cases — `enum MemoryPressureLevel { case normal, warning, critical }`.
- Non-instantiable helper enums with static methods: `enum FormatHelpers { static func bytes(...) }`.

### Models
- All metric structs are `Sendable` value types.
- Provide `.zero` / `.empty` / `.unavailable` static constants for default/fallback states.
- Derived values go in computed properties (e.g., `usedFraction`, `total`).

### Views
- Pass `SystemMonitor`, `AppState`, and `AppSettings` references into views; views never instantiate services.
- Use `@Bindable` for two-way binding to `@Observable` objects.
- Every interactive element needs `.accessibilityLabel`, `.accessibilityValue`, and `.accessibilityAddTraits(.updatesFrequently)`.
- Use `.monospacedDigit()` on numeric displays (CPU %, memory, network rates).
- Charts use the SwiftUI `Charts` framework with `.catmullRom` interpolation on `LiveChart`.

### Error Handling
- Use nil-coalescing for graceful fallbacks on system API calls — do **not** throw from collectors.
- Show "Feature unavailable in sandbox" UI where App Store entitlements prevent access.

### Resource Management
- Use `defer` for Mach memory deallocation (`vm_deallocate`).
- Store the repeating timer as an optional and call `invalidate()` on stop.

## Testing

Tests live in `Tests/MacPulseTests/main.swift` and use a minimal custom framework:

```swift
func assert(_ condition: Bool, _ message: String, file: String = #file, line: Int = #line)
func test(_ name: String, _ body: () -> Void)
```

- New tests follow the pattern: call `collect()` once to establish a baseline, sleep briefly (`usleep`), call again, then assert on the result.
- Validate metric bounds (e.g., `0...1` for usage fractions, `0...150` for temperatures).
- Add tests for every new collector or service behaviour change.
- Run with `make test`.

## Key Files

| File | Purpose |
|------|---------|
| `Sources/MacPulse/Services/SystemMonitor.swift` | Central coordinator — start here when tracing data flow |
| `Sources/MacPulse/Services/MetricsHistory.swift` | Ring buffer for historical metric arrays |
| `Sources/MacPulse/Services/AppSettings.swift` | UserDefaults-backed settings |
| `Sources/MacPulse/Collectors/MetricsCollector.swift` | Collector protocol definition |
| `Sources/MacPulse/Views/Shared/FormatHelpers.swift` | Formatting utilities (bytes, percent, duration) |
| `Sources/MacPulseApp/MacPulseApp.swift` | App entry point and scene configuration |
| `Tests/MacPulseTests/main.swift` | All tests |
| `Makefile` | All build/test/distribution commands |
| `Package.swift` | SPM configuration — no external dependencies |
