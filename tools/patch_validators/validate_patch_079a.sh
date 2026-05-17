#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

test -f scripts/systems/MapLayoutSystem.gd
grep -q "class_name RVMapLayoutSystem" scripts/systems/MapLayoutSystem.gd
grep -q "ARCHETYPE_STRAND_ROAD" scripts/systems/MapLayoutSystem.gd
grep -q "ARCHETYPE_LOOP_CISTERN" scripts/systems/MapLayoutSystem.gd
grep -q "ARCHETYPE_BRANCHING_CATACOMB" scripts/systems/MapLayoutSystem.gd
grep -q "ARCHETYPE_SEWER_AQUEDUCT" scripts/systems/MapLayoutSystem.gd
grep -q "ARCHETYPE_FORTRESS_BASTION" scripts/systems/MapLayoutSystem.gd
grep -q "ARCHETYPE_FORGEWORKS" scripts/systems/MapLayoutSystem.gd
grep -q "ARCHETYPE_SANCTUM_TEMPLE" scripts/systems/MapLayoutSystem.gd
grep -q "ARCHETYPE_VAULT" scripts/systems/MapLayoutSystem.gd
grep -q "ARCHETYPE_OSSUARY_CRYPT" scripts/systems/MapLayoutSystem.gd
grep -q "ARCHETYPE_OPEN_RUINS" scripts/systems/MapLayoutSystem.gd
grep -q "generate_layout" scripts/systems/MapLayoutSystem.gd

echo "Patch 079A validation passed: all 10 continuous map layouts are installed."
