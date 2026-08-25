# CI and releases

This is the [Zyzto fork](../FORK.md). I do not own Play Store, F-Droid, Weblate, or derdilla's signing key. CI here only builds this tree.

## Workflows

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| [`.github/workflows/ci.yml`](../.github/workflows/ci.yml) | Push to `main`, every PR | Analyze, test, package tests, debug `fdroid` APK |
| [`.github/workflows/release.yml`](../.github/workflows/release.yml) | Tag `vX.Y.Z` | Tests, signed `github` APK, GitHub Release |

Obtainium watches those GitHub Releases.

The old upstream workflows (Play Fastlane, golden auto-push, `/build` labels) are gone. Those assumed the official store listing.

## Secrets

Tag releases need a keystore **you** created. Not the Play or F-Droid key.

| Secret | Contents |
|--------|----------|
| `KEYSTORE_BASE64` | Base64 of your `.jks` / `.keystore` |
| `KEYSTORE_PASSWORD` | Keystore password |
| `KEY_ALIAS` | Key alias |
| `KEY_PASSWORD` | Key password |

```bash
keytool -genkeypair -v \
  -keystore fork-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias fork
base64 -w0 fork-upload.jks
```

Paste that into the repo secrets. Keep the jks file off git. `app/android/key.properties` is gitignored.

Without those secrets, `Release` fails on purpose. A debug-signed APK must not land on Obtainium.

## Application id

The tree still ships `com.derdilla.bloodPressureApp`. That id belongs to upstream. This fork's APK uses a different signature, so it cannot update a Play or F-Droid install. Uninstall the store build first, or you get a signature mismatch. Data from the store app does not transfer automatically.

I am not claiming that package name. It is leftover from the fork.

## Cutting a release

1. `main` is green on `CI`.
2. The secrets above are set.
3. `version:` in `app/pubspec.yaml` is `X.Y.Z+N`. The tag is `vX.Y.Z`.

```bash
git tag v1.8.15
git push origin v1.8.15
```

4. Actions publishes `blood-pressure-monitor-1.8.15.apk`. Obtainium picks it up.

## Local

```bash
bash ./scripts/ci/codegen.sh
cd app
flutter analyze
flutter test
flutter build apk --debug --flavor fdroid
```

Release signing locally: put `key.properties` under `app/android/` as Flutter documents, then `flutter build apk --release --flavor github`.
