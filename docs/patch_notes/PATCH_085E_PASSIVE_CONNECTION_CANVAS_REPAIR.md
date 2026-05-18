# Patch 085E — Passive Connection Canvas Repair

Fixes a passive tree parser/runtime mismatch where `PassiveTreeConnectionCanvas.gd` assumed `RVPassiveAtlasDB.nodes()` returned dictionaries, while the repaired database may return node IDs.

## Fixes

- Rewrites `PassiveTreeConnectionCanvas.gd` to accept either dictionary nodes or string node IDs.
- Uses `RVPassiveAtlasDB.node_by_id()` for string IDs.
- Uses `RVPassiveAtlasDB.connected_ids()` for connection drawing.
- Removes typed `for node: Dictionary in PassiveDBScript.nodes()` iteration.
- Keeps connection drawing scene-owned and script-rendered only.

## Install

Run:

```bash
cd /home/kaey/Downloads
rm -rf patch_085e_passive_connection_canvas_repair
unzip -o patch_085e_passive_connection_canvas_repair.zip -d /home/kaey/Downloads

cd /home/kaey/Desktop/Game
bash /home/kaey/Downloads/patch_085e_passive_connection_canvas_repair/install_patch_085e.sh

tools/patch_validators/validate_patch_085e.sh
tools/validate_all.sh
git status
```
