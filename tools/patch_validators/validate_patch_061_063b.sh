#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game
[ -f scripts/visuals/SpellVFXSystem.gd ]
grep -q "static func emit_skill" scripts/visuals/SpellVFXSystem.gd
grep -q "class_name RVSpellVFXSystem" scripts/visuals/SpellVFXSystem.gd
echo "Patch 061-063B validation passed."
