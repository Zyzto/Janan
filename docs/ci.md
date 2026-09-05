# CI and releases

This is the [Zyzto fork](../FORK.md). I do not own Play Store, F-Droid, Weblate, or derdilla's signing key. CI here only builds this tree.

## Workflows

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| [`.github/workflows/ci.yml`](../.github/workflows/ci.yml) | Push to `main`, every PR | Analyze, test, translation JSON check, debug APK |
| [`.github/workflows/pr.yml`](../.github/workflows/pr.yml) | Pull requests | Extra PR lints, goldens, optional labeled test/build |
| [`.github/workflows/release.yml`](../.github/workflows/release.yml) | Tag `vYY.0M.MICRO` | Tests, signed ABI APKs plus universal APK, GitHub Release |

Obtainium watches those GitHub Releases.

The old upstream workflows (Play Fastlane, workspace package CI) are gone.

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

Paste that into the repo secrets. Keep the jks file off git. `android/key.properties` is gitignored.

Without those secrets, `Release` fails on purpose. A debug-signed APK must not land on Obtainium.

## Application id

Janan ships as `com.shenepoy.janan`. It installs next to the upstream app (`com.derdilla.bloodPressureApp`). A store install and this APK cannot replace each other.

## Cutting a release

1. `main` is green on `CI`.
2. The secrets above are set.
3. `version:` in `pubspec.yaml` is `YY.0M.MICRO+N`. The tag is `vYY.0M.MICRO`.

```bash
git tag v26.08.0
git push origin v26.08.0
```

4. Actions publishes `janan-26.08.0-armeabi-v7a.apk`, `janan-26.08.0-arm64-v8a.apk`,
   `janan-26.08.0-x86_64.apk`, and `janan-26.08.0-universal.apk` plus one symbols archive.
   Obtainium can use the universal APK or the device-specific APK for smaller downloads.

See [docs/release-process.md](release-process.md) for CalVer.

## Local

```bash
bash ./scripts/ci/codegen.sh
flutter analyze
flutter test
flutter build apk --debug
```

Release signing locally: put `key.properties` under `android/` as Flutter documents, then
`bash ./scripts/ci/build_release_apk.sh`. That enables R8/resource shrinking, obfuscates Dart,
builds all three ABI APKs plus a universal APK, and writes a symbols archive containing Dart
symbols and the R8 mapping.
