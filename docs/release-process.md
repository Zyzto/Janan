# Release process

## Versioning

App versions are calendar versions: `YY.0M.MICRO+BUILD`

| Part | Meaning | Example |
|------|---------|---------|
| `YY` | Two-digit year | `26` |
| `0M` | Zero-padded month | `08` |
| `MICRO` | Release index in that month, starting at `0` | `0`, `1`, `10` |
| `BUILD` | Android `versionCode` / iOS `CFBundleVersion`. Always increments. Used for in-app upgrades (`last_version`). | `58` |

Examples:

- First August 2026 release: `26.08.0+58`
- Second that month: `26.08.1+59`
- First September release: `26.09.0+60`

The name lives in `pubspec.yaml`. Flutter keeps the leading zero on the month. Tag GitHub releases as `v26.08.0`.

`tools/release_tool` computes the next `YY.0M.MICRO` from the current UTC month and increments `BUILD`.

## App release checklist

How this tree ships APKs: [docs/ci.md](ci.md).

1. `version:` in `pubspec.yaml` matches the tag (`v26.08.0` for `26.08.0+58`).
2. Tag and push. Actions signs with this fork's keystore secrets and attaches one APK for each
   ABI (`armeabi-v7a`, `arm64-v8a`, `x86_64`), a `-universal.apk`, and one symbols archive.
3. Obtainium follows that GitHub Release.

Do not upload this APK to Play or F-Droid. Those listings are not ours.
