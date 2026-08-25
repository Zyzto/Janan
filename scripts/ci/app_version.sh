#!/usr/bin/env bash
# Print name and code from app/pubspec.yaml (version: 1.8.15+57).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
raw=$(sed -n -E "s/^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+).*/\1 \2/p" "$ROOT_DIR/app/pubspec.yaml")
if [[ -z "$raw" ]]; then
  echo "Could not read version from app/pubspec.yaml" >&2
  exit 1
fi
# shellcheck disable=SC2086
set -- $raw
echo "name=$1"
echo "code=$2"
