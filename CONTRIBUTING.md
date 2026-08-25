# Contributing

This is the [Zyzto fork](https://github.com/Zyzto/blood-pressure-monitor-fl) of [derdilla/blood-pressure-monitor-fl](https://github.com/derdilla/blood-pressure-monitor-fl). See [FORK.md](FORK.md).

I use AI coding agents on this tree. If that bothers you, use upstream instead.

Work you send here is under the same license as the project.

## Issues

Open them on this fork if they are about the extra BLE work or this build. Open them [upstream](https://github.com/derdilla/blood-pressure-monitor-fl/issues) if they are about the official app.

## Build

Needs Flutter 3.47.0.

1. [Install Flutter](https://docs.flutter.dev/get-started/install)
2. `git clone https://github.com/Zyzto/blood-pressure-monitor-fl.git`
3. `dart run build_runner build` in `health_data_store`
4. `dart run build_runner build` in `app`

Then:

- `flutter run --flavor github`
- `flutter build apk --flavor github` or `--flavor fdroid`

CI, signing secrets, and Obtainium releases are in [docs/ci.md](docs/ci.md). I do not own Play or the upstream key.


After you change a `@GenerateSettings` file:

`dart run build_runner build --build-filter="lib/model/storage/*.dart"`

Data formats and style notes are in [docs](docs/). Those files started as upstream docs.

## Pull requests

PRs on this fork are fine. Say if a change was AI-assisted. I am not forwarding them to derdilla.
