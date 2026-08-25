#!/usr/bin/env bash
# Generate freezed / settings / mock code the app tests and APKs need.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

flutter pub get --enforce-lockfile

(cd health_data_store && dart run build_runner build --delete-conflicting-outputs)
(cd app && dart run build_runner build --delete-conflicting-outputs --build-filter "lib/model/storage/*.dart")
(cd app && dart run build_runner build --delete-conflicting-outputs --build-filter "test/**/*.dart")
