#!/usr/bin/env bash
# Print the Flutter version pinned in the workspace pubspec.yaml.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VERSION=$(sed -n -E "s/.*flutter:\s*(.*)/\1/p" "$ROOT_DIR/pubspec.yaml")
if [[ -z "$VERSION" ]]; then
  echo "No flutter: version in pubspec.yaml" >&2
  exit 1
fi
echo "$VERSION"
