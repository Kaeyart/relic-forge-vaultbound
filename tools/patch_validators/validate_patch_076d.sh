#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

if grep -R "RVMapDeviceArtSkin" scripts/ui/panels scripts/visuals 2>/dev/null; then
  echo "Patch 076D failed: leftover RVMapDeviceArtSkin reference in runtime scripts."
  exit 1
fi

echo "Patch 076D validation passed: no runtime panel references to RVMapDeviceArtSkin remain."
