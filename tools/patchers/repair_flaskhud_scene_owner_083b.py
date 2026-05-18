#!/usr/bin/env python3
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path.cwd()
GAMEHUD_SCENE = ROOT / "scenes/ui/GameHUD.tscn"
FLASK_SCENE = ROOT / "scenes/ui/hud/FlaskHUD.tscn"
GAMEHUD_SCRIPT = ROOT / "scripts/ui/GameHUD.gd"

def read(p: Path) -> str:
    return p.read_text(encoding="utf-8")

def write(p: Path, text: str) -> None:
    p.write_text(text, encoding="utf-8")

def ensure_flaskhud_scene_instance() -> None:
    if not FLASK_SCENE.exists():
        print("WARN: FlaskHUD scene missing; cannot instance it into GameHUD.")
        return
    if not GAMEHUD_SCENE.exists():
        print("WARN: GameHUD.tscn missing; cannot instance FlaskHUD.")
        return

    text = read(GAMEHUD_SCENE)
    if "FlaskHUD.tscn" in text and "FlaskHUD" in text:
        print("GameHUD.tscn already appears to scene-own FlaskHUD.")
        return

    backup = GAMEHUD_SCENE.with_suffix(".tscn.083b.bak")
    if not backup.exists():
        write(backup, text)

    ext_id = "flask_hud_scene"
    ext_line = f'[ext_resource type="PackedScene" path="res://scenes/ui/hud/FlaskHUD.tscn" id="{ext_id}"]'
    lines = text.splitlines()

    insert_idx = 1
    for i, line in enumerate(lines):
        if line.startswith("[ext_resource"):
            insert_idx = i + 1
    lines.insert(insert_idx, ext_line)

    lines.extend([
        "",
        f'[node name="FlaskHUD" parent="." instance=ExtResource("{ext_id}")]',
        "unique_name_in_owner = true",
        "visible = true",
    ])
    write(GAMEHUD_SCENE, "\n".join(lines) + "\n")
    print("Inserted FlaskHUD scene instance into GameHUD.tscn.")

def ensure_gamehud_script_binding() -> None:
    if not GAMEHUD_SCRIPT.exists():
        return
    text = read(GAMEHUD_SCRIPT)
    original = text

    if "flask_hud" not in text:
        lines = text.splitlines()
        insert_at = 0
        for i, line in enumerate(lines[:20]):
            if line.startswith("extends ") or line.startswith("class_name "):
                insert_at = i + 1
        lines.insert(insert_at, '@onready var flask_hud: Node = get_node_or_null("%FlaskHUD")')
        text = "\n".join(lines) + "\n"

    update_call = '\n\tif flask_hud == null:\n\t\tflask_hud = get_node_or_null("%FlaskHUD")\n\tif flask_hud != null and flask_hud.has_method("update_from_state"):\n\t\tflask_hud.call("update_from_state", state)\n'
    if 'flask_hud.call("update_from_state"' not in text and "flask_hud.call('update_from_state'" not in text:
        m = re.search(r"func\s+update_from_state\s*\([^)]*\)\s*->\s*void\s*:\n", text)
        if m:
            insert_pos = m.end()
            text = text[:insert_pos] + update_call + text[insert_pos:]
        else:
            text += "\nfunc update_from_state(state: RVGameState) -> void:\n" + update_call

    if text != original:
        backup = GAMEHUD_SCRIPT.with_suffix(".gd.083b.bak")
        if not backup.exists():
            write(backup, original)
        write(GAMEHUD_SCRIPT, text)
        print("Ensured GameHUD.gd binds FlaskHUD.")

def main() -> None:
    ensure_flaskhud_scene_instance()
    ensure_gamehud_script_binding()

if __name__ == "__main__":
    main()
