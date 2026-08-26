#!/usr/bin/env bash
# Print name and code from pubspec.yaml (version: 26.08.0+58).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
raw=$(sed -n -E "s/^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+).*/\1 \2/p" "$ROOT_DIR/pubspec.yaml")
if [[ -z "$raw" ]]; then
  echo "Could not read version from pubspec.yaml" >&2
  exit 1
fi
# shellcheck disable=SC2086
set -- $raw
echo "name=$1"
echo "code=$2"
