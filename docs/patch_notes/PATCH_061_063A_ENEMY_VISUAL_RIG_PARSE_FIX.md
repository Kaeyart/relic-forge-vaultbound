# Patch 061-063A — Enemy Visual Rig Parse Fix

Fixes the parse error in `res://scripts/visuals/EnemyVisualRig.gd` from Patch 061-063.

Changes:
- replaces unsafe nested ternary usage
- removes bad bool/string comparison logic
- avoids unsafe direct Variant-to-typed assignments
- keeps the animated proxy enemy silhouettes and state visual reactions

No scenes, combat logic, skill gems, inventory, or map data are changed.
