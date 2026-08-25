<!-- markdownlint-disable MD033 MD060 -->

<h1 align="center">Blood Pressure Monitor</h1>

<p align="center">
  <strong>Personal fork.</strong> I do not own the app, the name, Play, F-Droid, or the original signing key.<br/>
  Upstream is <a href="https://github.com/derdilla/blood-pressure-monitor-fl">derdilla/blood-pressure-monitor-fl</a>.
</p>

<p align="center">
  <a href="https://github.com/Zyzto/blood-pressure-monitor-fl/releases/latest"><img alt="release" src="https://img.shields.io/github/v/release/Zyzto/blood-pressure-monitor-fl?style=flat-square&color=546E7A" /></a>
  <a href="https://github.com/Zyzto/blood-pressure-monitor-fl/actions/workflows/ci.yml"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/Zyzto/blood-pressure-monitor-fl/ci.yml?style=flat-square&label=CI" /></a>
  <a href="https://github.com/Zyzto/blood-pressure-monitor-fl"><img alt="repo" src="https://img.shields.io/badge/github-Zyzto%2Fblood--pressure--monitor--fl-C0C0C0?style=flat-square" /></a>
  <a href="https://apps.obtainium.imranr.dev/redirect.html?r=obtainium://add/https://github.com/Zyzto/blood-pressure-monitor-fl/releases"><img alt="Obtainium" src="https://img.shields.io/badge/Obtainium-add-546E7A?style=flat-square&logo=android&logoColor=white" /></a>
  <img alt="flutter" src="https://img.shields.io/badge/Flutter-3.47.0-C0C0C0?style=flat-square&logo=flutter&logoColor=white" />
  <a href="LICENSE.md"><img alt="license" src="https://img.shields.io/badge/license-GPL--3.0-546E7A?style=flat-square" /></a>
</p>

<p align="center">
  <a href="https://github.com/Zyzto/blood-pressure-monitor-fl/releases/latest">Latest release</a>
  ·
  <a href="#install">Install</a>
  ·
  <a href="FORK.md">Fork notes</a>
  ·
  <a href="docs/ci.md">CI</a>
  ·
  <a href="https://github.com/derdilla/blood-pressure-monitor-fl">Upstream</a>
</p>

I write a lot of this with AI. Upstream does not accept that, so I do not send PRs there. Same story in [FORK.md](FORK.md).

If you want the official Play, F-Droid, or GitHub build, get it from [upstream](https://github.com/derdilla/blood-pressure-monitor-fl). Those listings are not mine.

## Install

This fork is not on any store.

| Option | |
|--------|--|
| **Obtainium** (recommended) | [![Obtainium](https://img.shields.io/badge/Obtainium-add-546E7A?style=flat-square&logo=android&logoColor=white)](https://apps.obtainium.imranr.dev/redirect.html?r=obtainium://add/https://github.com/Zyzto/blood-pressure-monitor-fl/releases) — tracks [GitHub Releases](https://github.com/Zyzto/blood-pressure-monitor-fl/releases) on this fork |
| **APK** | `blood-pressure-monitor-<version>.apk` from the [latest release](https://github.com/Zyzto/blood-pressure-monitor-fl/releases/latest) |

The package id is still `com.derdilla.bloodPressureApp`. I did not choose that and I do not own it. This APK is signed with my key, not Play or F-Droid, so it cannot update a store install. Uninstall the official app first.

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
bash ./scripts/ci/codegen.sh
cd app
flutter build apk --flavor github
```

or `fdroid` instead of `github`. CI and signing are in [docs/ci.md](docs/ci.md). More setup is in [CONTRIBUTING.md](CONTRIBUTING.md).

## Features from upstream

- Local measurement store
- Graphs and stats
- CSV, PDF, and SQLite export
- Bluetooth import for [tested meters](docs/bluetooth.md)
