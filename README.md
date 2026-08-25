# Blood Pressure Monitor

This is my fork of [derdilla/blood-pressure-monitor-fl](https://github.com/derdilla/blood-pressure-monitor-fl). Same story in [FORK.md](FORK.md).

I write a lot of this with AI coding agents. The original project does not accept that, so I am not opening PRs there.

If you want the official app from Play Store, F-Droid, or GitHub Releases, get it from the [original repo](https://github.com/derdilla/blood-pressure-monitor-fl). This fork is source only.

## What is different here

On top of upstream `main`:

- Per-device BLE profiles for GATT, Yonker, and Microlife meters
- Remembered devices under Settings → Features → Bluetooth devices
- Eufy P1 weight plus optional impedance. P2 is unsupported
- Detail screens for blood pressure and weight, including body composition when a profile and ohms are present
- Sync a saved meter on launch, with an AppBar icon

## Build

Needs Flutter 3.47.0.

```
dart run build_runner build
```

in `health_data_store`, then again in `app`. Then:

```
flutter build apk --flavor github
```

or `fdroid` instead of `github`.

More setup notes live in [CONTRIBUTING.md](CONTRIBUTING.md). Those instructions still describe the original project. Treat store and Weblate bits there as upstream, not this fork.

## Features from upstream

- Local measurement store
- Graphs and stats
- CSV, PDF, and SQLite export
- Bluetooth import for [tested meters](docs/bluetooth.md)
