#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
python3 tools/maintenance/audit_scene_authorship_085k.py --strict --output docs/SCENE_AUTHORSHIP_STATUS.md
