#!/usr/bin/env bash
# Generate Riverpod and other build_runner outputs the app tests and APKs need.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

flutter pub get --enforce-lockfile
dart run build_runner build --delete-conflicting-outputs
