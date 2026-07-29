#!/usr/bin/env bash
set -e

# ── Install Flutter ───────────────────────────────────────────────────────────
FLUTTER_DIR="$HOME/flutter"

if [ ! -d "$FLUTTER_DIR" ]; then
  echo ">>> Cloning Flutter stable..."
  git clone https://github.com/flutter/flutter.git \
    --depth 1 \
    --branch stable \
    "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

# ── Verify Flutter ────────────────────────────────────────────────────────────
flutter --version

# ── Enable web support ────────────────────────────────────────────────────────
flutter config --enable-web

# ── Fetch dependencies ────────────────────────────────────────────────────────
flutter pub get

# ── Build for web ─────────────────────────────────────────────────────────────
flutter build web --release

echo ">>> Build complete. Output in build/web"
