#!/usr/bin/env bash
# ==============================================================================
# Itqan Mobile App - Production Release Build Automation (Bash)
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR/../app"

echo "========================================================"
echo "  🕌 ITQAN - Production Release Build Generator"
echo "========================================================"

cd "$APP_DIR"

echo "📦 Resolving Flutter dependencies..."
flutter pub get

echo "🚀 Building Google Play Android App Bundle (AAB)..."
flutter build appbundle --release

echo "📱 Building Split Release APKs..."
flutter build apk --release --split-per-abi

if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "🍎 Building iOS Release Archive (macOS only)..."
  flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
fi

echo "🎉 All release builds generated successfully!"

