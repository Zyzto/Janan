*developer documentation - users can safely ignore this*

[Fork](../FORK.md). I use AI here.

### Used compressions

Release APKs are built with `scripts/ci/build_release_apk.sh`:

- Dart obfuscation and `--split-debug-info`. That usually drops 2-3 MB versus an unobfuscated fat APK.
- ABI-specific APKs (`armeabi-v7a`, `arm64-v8a`, `x86_64`) avoid shipping native code for
  unrelated devices; the universal APK remains available for broad sideload compatibility.
- Android resource configs limited to the locales that have JSON under `assets/translations/`. App strings stay in those JSON files; this only strips unused AndroidX / Play locale packs.
- Unused icons are shaken from the font during release compilation.

Release builds explicitly enable R8 minification and resource shrinking, use the optimized
Android ProGuard defaults, and pick up `android/app/proguard-rules.pro`.

Tagged GitHub Releases attach `janan-YY.0M.MICRO-symbols.zip`, containing Dart symbols and the
R8 mapping. Use that with [the Flutter docs](https://docs.flutter.dev/deployment/obfuscate#read-an-obfuscated-stack-trace) when reading a crash stack.

### Ineffective compressions

- R8 full mode is already the AGP default; no opt-out flag is set here.
- Using the old APK behavior of compressing native libraries shows no to little improvements and is worse for Google Play distribution.
