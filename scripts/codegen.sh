#!/usr/bin/env bash
# Regenerate all freezed models and riverpod provider boilerplate.
# Run this after checking out the repo or editing any @freezed / @riverpod file.
set -euo pipefail
cd "$(dirname "$0")/.."
flutter pub get
dart run build_runner build --delete-conflicting-outputs
echo "✓ Code generation complete"
