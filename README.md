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

## Requirements

- macOS 14.0 Sonoma or later
- Apple Silicon or Intel Mac

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, architecture details, and guidelines.

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
