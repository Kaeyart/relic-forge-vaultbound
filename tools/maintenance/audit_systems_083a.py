#!/usr/bin/env python3
from __future__ import annotations

import argparse
import datetime as _dt
import re
from pathlib import Path
from typing import Dict, List, Tuple

ROOT = Path.cwd()

SKIP_DIR_NAMES = {
    ".git", ".godot", ".import", ".mono", ".local_project_backups",
    ".patch_backups", ".patch045a_backups", "__pycache__",
}
SKIP_DIR_SUBSTRINGS = ("backup", "backups", ".patch")
ACTIVE_ROOTS = ("scripts", "scenes", "tools")
UI_LAYOUT_NEW_PATTERNS = ("Button.new(", "Label.new(", "Panel.new(", "TextureRect.new(", "VBoxContainer.new(", "HBoxContainer.new(", "GridContainer.new(")
CRITICAL_CLASSES = {
    "RVGameState": "scripts/core/GameState.gd",
    "RVGameRoot": "scripts/core/GameRoot.gd",
    "RVCombatArena": "scripts/combat/CombatArena.gd",
    "RVEnemyActor": "scripts/combat/EnemyActor.gd",
    "RVProjectileActor": "scripts/combat/ProjectileActor.gd",
    "RVGameHUD": "scripts/ui/GameHUD.gd",
    "RVFlaskHUD": "scripts/ui/hud/FlaskHUD.gd",
    "RVFlaskSystem": "scripts/systems/FlaskSystem.gd",
    "RVMapSystem": "scripts/systems/MapSystem.gd",
    "RVMapLayoutSystem": "scripts/systems/MapLayoutSystem.gd",
    "RVMapEncounterDirector": "scripts/systems/MapEncounterDirector.gd",
    "RVMapItemSystem": "scripts/systems/MapItemSystem.gd",
    "RVStashSystem": "scripts/systems/StashSystem.gd",
    "RVItemizationSystem": "scripts/systems/ItemizationSystem.gd",
    "RVCraftingCurrencySystem": "scripts/systems/CraftingCurrencySystem.gd",
    "RVLootFilterSystem": "scripts/systems/LootFilterSystem.gd",
    "RVLootPickupAssistSystem": "scripts/systems/LootPickupAssistSystem.gd",
    "RVProgressionRewardSystem": "scripts/systems/ProgressionRewardSystem.gd",
}

SYSTEMS = {
    "Map device + physical maps": ["scripts/systems/MapSystem.gd", "scripts/systems/MapItemSystem.gd", "scripts/ui/panels/MapDevicePanel.gd"],
    "Continuous map layouts": ["scripts/systems/MapLayoutSystem.gd", "scripts/systems/MapEncounterDirector.gd"],
    "Combat arena runtime": ["scripts/combat/CombatArena.gd", "scripts/systems/CombatGeometrySystem.gd"],
    "Loot pickup pet": ["scripts/systems/LootPickupAssistSystem.gd", "scripts/visuals/LootPickupPetVisual.gd"],
    "Stash tabs + affinity": ["scripts/systems/StashSystem.gd", "scripts/ui/panels/StashPanel.gd"],
    "Itemization core": ["scripts/systems/ItemizationSystem.gd", "scripts/data/ItemBaseDB.gd", "scripts/data/ItemAffixDB.gd"],
    "Crafting currency verbs": ["scripts/systems/CraftingCurrencySystem.gd", "scripts/data/CraftingCurrencyDB.gd"],
    "Loot filter": ["scripts/systems/LootFilterSystem.gd", "scripts/ui/panels/LootFilterPanel.gd", "scenes/ui/panels/LootFilterPanel.tscn"],
    "Flasks + flask HUD": ["scripts/systems/FlaskSystem.gd", "scripts/ui/hud/FlaskHUD.gd", "scenes/ui/hud/FlaskHUD.tscn"],
    "Progression rewards": ["scripts/systems/ProgressionRewardSystem.gd"],
}

def should_skip_dir(path: Path) -> bool:
    name = path.name
    if name in SKIP_DIR_NAMES:
        return True
    if name.startswith("."):
        return True
    low = name.lower()
    return any(part in low for part in SKIP_DIR_SUBSTRINGS)

def iter_files() -> List[Path]:
    out: List[Path] = []
    for root_name in ACTIVE_ROOTS:
        root = ROOT / root_name
        if not root.exists():
            continue
        for p in root.rglob("*"):
            if any(should_skip_dir(parent) for parent in p.parents if parent != ROOT):
                continue
            if p.is_file() and p.suffix in {".gd", ".tscn", ".tres", ".res", ".cfg", ".json", ".md", ".sh", ".py"}:
                out.append(p)
    return sorted(set(out))

def rel(p: Path) -> str:
    try:
        return str(p.relative_to(ROOT))
    except Exception:
        return str(p)

def read_text(p: Path) -> str:
    try:
        return p.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return p.read_text(errors="replace")

def gd_files() -> List[Path]:
    return [p for p in iter_files() if p.suffix == ".gd"]

def find_global_classes() -> Dict[str, List[Path]]:
    classes: Dict[str, List[Path]] = {}
    rx = re.compile(r"^\s*class_name\s+([A-Za-z_][A-Za-z0-9_]*)\s*$", re.M)
    for p in gd_files():
        text = read_text(p)
        for m in rx.finditer(text):
            classes.setdefault(m.group(1), []).append(p)
    return classes

def line_no(text: str, pos: int) -> int:
    return text.count("\n", 0, pos) + 1

def detect_duplicate_functions(p: Path, text: str) -> List[str]:
    errors = []
    seen: Dict[str, int] = {}
    rx = re.compile(r"^\s*func\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(", re.M)
    for m in rx.finditer(text):
        name = m.group(1)
        ln = line_no(text, m.start())
        if name in seen:
            errors.append(f"**ERROR** `{rel(p)}:{ln}` — Duplicate function '{name}' also declared near line {seen[name]}")
        else:
            seen[name] = ln
    return errors

def detect_duplicate_class_vars(p: Path, text: str) -> List[str]:
    errors = []
    seen: Dict[str, int] = {}
    rx = re.compile(r"^\s*(?:@export\s+)?var\s+([A-Za-z_][A-Za-z0-9_]*)\b", re.M)
    for m in rx.finditer(text):
        name = m.group(1)
        ln = line_no(text, m.start())
        if name in seen:
            errors.append(f"**ERROR** `{rel(p)}:{ln}` — Duplicate class variable '{name}' also declared near line {seen[name]}")
        else:
            seen[name] = ln
    return errors

def detect_headers(p: Path, text: str) -> List[str]:
    errors = []
    cls = list(re.finditer(r"^\s*class_name\s+", text, re.M))
    ext = list(re.finditer(r"^\s*extends\s+", text, re.M))
    if len(cls) > 1:
        errors.append(f"**ERROR** `{rel(p)}` — Duplicate class_name header lines")
    if len(ext) > 1:
        errors.append(f"**ERROR** `{rel(p)}` — Duplicate extends header lines")
    return errors

def detect_get_helper(p: Path, text: str) -> List[str]:
    errors = []
    rx = re.compile(r"^\s*(?:static\s+)?func\s+_get\s*\(\s*state\s*:", re.M)
    for m in rx.finditer(text):
        errors.append(f"**ERROR** `{rel(p)}:{line_no(text, m.start())}` — Invalid custom _get(state, ...) helper conflicts with Godot Object._get(StringName)")
    return errors

def detect_clear_current(p: Path, text: str) -> List[str]:
    if ".clear_current(" in text:
        return [f"**ERROR** `{rel(p)}` — Invalid Camera2D.clear_current() call"]
    return []

def detect_stale_artskin(p: Path, text: str) -> List[str]:
    if "RVMapDeviceArtSkin" in text or "MapDeviceArtSkin.gd" in text:
        return [f"**ERROR** `{rel(p)}` — Stale RVMapDeviceArtSkin runtime-art reference"]
    return []

def detect_unsafe_add_child(p: Path, text: str) -> List[str]:
    errors = []
    if rel(p) != "scripts/combat/CombatArena.gd":
        return errors
    bad_patterns = {
        "projectiles_root.add_child(": "Unsafe add_child on cached projectiles_root; use _rf_live_projectiles_root().add_child(...)",
        "enemies_root.add_child(": "Unsafe add_child on cached enemies_root; use _rf_live_enemies_root().add_child(...)",
    }
    for needle, msg in bad_patterns.items():
        for m in re.finditer(re.escape(needle), text):
            errors.append(f"**ERROR** `{rel(p)}:{line_no(text, m.start())}` — {msg}")
    return errors

def detect_safe_children_signature(p: Path, text: str) -> List[str]:
    errors = []
    rx = re.compile(r"func\s+_rf_safe_children\s*\(\s*root\s*:\s*Node\s*\)")
    for m in rx.finditer(text):
        errors.append(f"**ERROR** `{rel(p)}:{line_no(text, m.start())}` — _rf_safe_children(root: Node) rejects freed roots before safety checks; use Variant")
    return errors

def detect_scene_owned_flaskhud() -> List[str]:
    errors = []
    scene = ROOT / "scenes/ui/GameHUD.tscn"
    flask_scene = ROOT / "scenes/ui/hud/FlaskHUD.tscn"
    if flask_scene.exists():
        if not scene.exists():
            errors.append("**ERROR** `scenes/ui/GameHUD.tscn` — Missing GameHUD scene; cannot scene-own FlaskHUD")
        else:
            text = read_text(scene)
            if "FlaskHUD.tscn" not in text or "FlaskHUD" not in text:
                errors.append("**ERROR** `scenes/ui/GameHUD.tscn` — FlaskHUD.tscn exists but GameHUD.tscn does not scene-own/instance FlaskHUD")
    return errors

def detect_script_created_ui() -> List[str]:
    warnings = []
    for path_str in ["scripts/ui/hud/FlaskHUD.gd", "scripts/ui/panels/LootFilterPanel.gd", "scripts/ui/panels/MapDevicePanel.gd"]:
        p = ROOT / path_str
        if not p.exists():
            continue
        text = read_text(p)
        for pat in UI_LAYOUT_NEW_PATTERNS:
            if pat in text:
                warnings.append(f"**WARNING** `{path_str}` — Creates UI/layout node with `{pat}`; verify scene owns layout")
                break
    return warnings

def detect_cached_get_children_warnings() -> List[str]:
    warnings = []
    watch = ["scripts/systems/CombatPackAISystem.gd", "scripts/combat/CombatArena.gd"]
    for path_str in watch:
        p = ROOT / path_str
        if not p.exists():
            continue
        text = read_text(p)
        for m in re.finditer(r"\.get_children\s*\(", text):
            ln = line_no(text, m.start())
            context = text[max(0, m.start()-100):m.start()+100]
            if "_rf_safe_children" in context:
                continue
            warnings.append(f"**WARNING** `{path_str}:{ln}` — Direct get_children(); prefer safe iteration when root can be freed")
    return warnings

def detect_unresolved_rv_warnings(classes: Dict[str, List[Path]]) -> List[str]:
    warnings = []
    known = set(classes.keys())
    token_rx = re.compile(r"\b(RV[A-Za-z0-9_]+)\b")
    seen: Dict[str, List[str]] = {}
    for p in gd_files():
        text = read_text(p)
        for token in token_rx.findall(text):
            if token in known:
                continue
            if token.endswith("Script"):
                continue
            if token in {"RV"}:
                continue
            seen.setdefault(token, []).append(rel(p))
    for token, paths in sorted(seen.items()):
        unique = sorted(set(paths))[:3]
        warnings.append(f"**WARNING** `GLOBAL_CLASS_REGISTRY` — Referenced RV token '{token}' has no class_name declaration found. Seen in: {', '.join(unique)}")
    return warnings[:25]

def system_inventory() -> List[Tuple[str, str, List[str]]]:
    rows = []
    for system, files in SYSTEMS.items():
        missing = [f for f in files if not (ROOT / f).exists()]
        rows.append((system, "OK" if not missing else "MISSING", missing))
    return rows

def run_audit() -> Tuple[List[str], List[str], Dict[str, List[Path]]]:
    errors: List[str] = []
    warnings: List[str] = []
    classes = find_global_classes()

    for cls, paths in classes.items():
        if len(paths) > 1:
            first = rel(paths[0])
            for p in paths[1:]:
                errors.append(f"**ERROR** `{rel(p)}:1` — Duplicate global class '{cls}' also declared in {first}")

    for cls, expected in CRITICAL_CLASSES.items():
        p = ROOT / expected
        if not p.exists():
            errors.append(f"**ERROR** `{expected}` — Missing critical global class file for {cls}")
        elif cls not in classes:
            errors.append(f"**ERROR** `{expected}` — Expected class_name {cls} not found")

    for p in gd_files():
        text = read_text(p)
        errors.extend(detect_duplicate_functions(p, text))
        errors.extend(detect_duplicate_class_vars(p, text))
        errors.extend(detect_headers(p, text))
        errors.extend(detect_get_helper(p, text))
        errors.extend(detect_clear_current(p, text))
        errors.extend(detect_stale_artskin(p, text))
        errors.extend(detect_unsafe_add_child(p, text))
        errors.extend(detect_safe_children_signature(p, text))

    errors.extend(detect_scene_owned_flaskhud())
    warnings.extend(detect_script_created_ui())
    warnings.extend(detect_cached_get_children_warnings())
    warnings.extend(detect_unresolved_rv_warnings(classes))
    return errors, warnings, classes

def write_report(path: Path, errors: List[str], warnings: List[str], classes: Dict[str, List[Path]]) -> None:
    now = _dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    lines: List[str] = []
    lines.append("# Relic Forge: Vaultbound — Systems Status")
    lines.append("")
    lines.append(f"Generated by Patch 083B audit on `{now}`.")
    lines.append("")
    lines.append("## Audit Summary")
    lines.append("")
    lines.append(f"- Errors: **{len(errors)}**")
    lines.append(f"- Warnings: **{len(warnings)}**")
    lines.append(f"- Global classes found: **{len(classes)}**")
    lines.append("")
    lines.append("## System Inventory")
    lines.append("")
    lines.append("| System | Status | Missing Files |")
    lines.append("|---|---:|---|")
    for system, status, missing in system_inventory():
        lines.append(f"| {system} | **{status}** | {', '.join(missing) if missing else '—'} |")
    lines.append("")
    lines.append("## Current Strengths")
    lines.append("")
    lines.append("- Physical maps, map device flow, map stash, map completion, active portal entries, and persistent map re-entry exist as a usable ARPG loop.")
    lines.append("- Loot pickup assist, loot filter, stash tabs/affinity, item bases/affixes, crafting verbs, flasks, and progression rewards are present enough for tuning.")
    lines.append("- Scene-authored UI remains the production rule. Scripts should bind state; scenes should own layout.")
    lines.append("")
    lines.append("## Highest-Risk Areas")
    lines.append("")
    lines.append("1. `CombatArena.gd` is overloaded and still the highest-risk file.")
    lines.append("2. `GameState.gd` is a large save schema. New fields must be declared once and defaulted once.")
    lines.append("3. Continuous map collision is playable but still V1; enemies are constrained rather than pathfinding around blockers.")
    lines.append("4. Itemization/crafting/drop rates exist structurally but need tuning across actual map runs.")
    lines.append("")
    lines.append("## Recommended Next Production Steps")
    lines.append("")
    lines.append("1. Keep this audit at zero ERROR entries before adding large systems.")
    lines.append("2. Do a short map QA pass: open map, kill packs, portal out/in, die/re-enter, complete boss, verify cleanup.")
    lines.append("3. Start `083C — CombatArena Decomposition Prep`: extract root/layer helpers, map persistence, projectile collision, and reward/exit helpers without changing gameplay.")
    lines.append("4. Then do `084A — Drop Economy Tuning`: XP, gem XP, item level, forge potential, rarity, boss rewards, map drops, and flask upgrade drops.")
    lines.append("")
    lines.append("## Errors")
    lines.append("")
    if errors:
        lines.extend(f"- {e}" for e in errors)
    else:
        lines.append("- None.")
    lines.append("")
    lines.append("## Warnings")
    lines.append("")
    if warnings:
        lines.extend(f"- {w}" for w in warnings)
    else:
        lines.append("- None.")
    lines.append("")
    lines.append("## Global Classes Found")
    lines.append("")
    for cls in sorted(classes.keys()):
        lines.append(f"- `{cls}` → `{rel(classes[cls][0])}`")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--write", default="docs/SYSTEMS_STATUS.md")
    ap.add_argument("--strict", action="store_true")
    args = ap.parse_args()

    errors, warnings, classes = run_audit()
    write_report(ROOT / args.write, errors, warnings, classes)

    print(f"083B audit: {len(errors)} errors, {len(warnings)} warnings, {len(classes)} global classes")
    print(f"Wrote {args.write}")
    if args.strict and errors:
        for e in errors:
            print(e)
        return 1
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
