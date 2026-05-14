#!/usr/bin/env bash
set -euo pipefail

PROJECT="/home/kaey/Desktop/Game"
REPO_NAME="relic-forge-vaultbound"

cd "$PROJECT"

echo "== RELIC FORGE GITHUB SETUP =="
echo "Project: $PROJECT"
echo "Repo:    $REPO_NAME"
echo

echo "== Checking dependencies =="
if ! command -v git >/dev/null 2>&1; then
    echo "Installing git..."
    sudo apt update
    sudo apt install -y git
fi

if ! command -v gh >/dev/null 2>&1; then
    echo "GitHub CLI 'gh' not found."
    echo "Trying normal apt install first..."
    sudo apt update
    sudo apt install -y gh || true
fi

if ! command -v gh >/dev/null 2>&1; then
    echo
    echo "ERROR: gh is still not installed."
    echo "Install GitHub CLI manually from:"
    echo "https://cli.github.com/"
    exit 1
fi

echo
echo "== Creating Godot .gitignore =="
cat > .gitignore <<'GITIGNORE'
# Godot 4 editor/import cache
.godot/
.import/

# Godot generated/imported files
*.import
*.translation

# Exports/builds
build/
builds/
exports/
*.pck
*.exe
*.x86_64
*.app
*.apk
*.aab

# Local/editor junk
.DS_Store
Thumbs.db
*.tmp
*.bak
*.swp
*~

# Logs
*.log

# Local backups / downloaded patch zips
*_backup/
backups/
Game_backups/
*.zip

# Export presets may contain local paths or credentials
export_presets.cfg
GITIGNORE

mkdir -p docs

echo
echo "== Creating AI project context file =="
cat > docs/AI_PROJECT_CONTEXT.md <<'CTX'
# AI Project Context — RELIC FORGE: VAULTBOUND

## Current project path

`/home/kaey/Desktop/Game`

## Engine

Godot 4.

## Current design direction

This is now a top-down 2D buildcraft dungeon-crawler ARPG, not a one-off prototype and not an isometric sprite project.

The player should start weak, enter a dungeon, find or draft a small number of skills, then mutate those skills into absurd late-run build engines through gear, passives, skill-tree nodes, relics, and dungeon modifiers.

The main fantasy is buildcraft:
- skill chaining
- equipment synergies
- passive-tree identity
- per-skill trees
- respec/testing convenience
- long-form dungeon runs around 20–30 minutes
- runs that start simple and end with ridiculous chained effects

## Current patch state

Patch 003 is installed.

Patch 003 introduced:
- Skill Draft start
- longer dungeon route pacing
- per-skill trees
- respec
- chain triggers
- cascade_engine
- fivefold_cascade
- Void Rift
- Blade Trap
- guide panel
- inventory/passive/build panels

## Workflow rule

Do not rewrite the whole game unless explicitly requested.

Future work should be delivered as targeted patches:
- new files
- replacement scripts
- small terminal commands
- clear patch notes
- migration instructions

Always preserve working systems unless replacing them deliberately.

## Current important files

- `project.godot`
- `scenes/Main.tscn`
- `scripts/Main.gd`
- `docs/PATCH_003_DESIGN_LOCK.md`
- `docs/PATCH_003_SYSTEM_EXPLANATION.md`
- `README.md`

## Design priorities

1. Reliability first.
2. Build variety second.
3. Dungeon crawler structure third.
4. UI readability and QOL always matter.
5. Existing working systems should not be casually destroyed.

## Build direction

The game should support builds like:
- Fireball causing Storm Lance, Frost Nova, Void Rift, and Blade Trap chains
- Frostfire detonator
- trap/void curse loops
- bleed duelist
- lightning cascade caster
- blood/self-damage caster
- summon/corpse engine later
- contract-scaling greed builds

The player should be able to respec easily and test builds without punishment.
CTX

echo
echo "== Creating patch workflow file =="
cat > docs/PATCH_WORKFLOW.md <<'WORKFLOW'
# Patch Workflow

## Rule

This repo is now the source of truth. Do not replace the whole project with a new generated zip unless the project is unrecoverable.

## Normal patch format

Each future patch should include:

1. What changed.
2. Which files changed.
3. Terminal commands to apply it.
4. How to test it.
5. What exact behavior confirms success.

## Preferred patch style

Prefer:
- editing `scripts/Main.gd`
- adding docs
- adding data files
- adding scenes only when needed

Avoid:
- total rewrites
- random file reorganization
- changing controls without documenting them
- deleting working systems
- huge architecture changes before the current loop is stable

## Local test loop

After every patch:

1. Open Godot.
2. Press Play.
3. Test the newest feature.
4. If an error appears, copy the first red error line.
5. Commit only after it runs or after the error state is understood.

## Commit message examples

- `patch 003 baseline`
- `fix skill draft selection crash`
- `add chain trigger debug panel`
- `expand fireball skill tree`
- `improve dungeon room pacing`
WORKFLOW

echo
echo "== Creating changelog if missing =="
if [ ! -f docs/CHANGELOG.md ]; then
cat > docs/CHANGELOG.md <<'CHANGELOG'
# Changelog

## Patch 003 baseline

Installed current Godot 4 buildcraft dungeon-crawler slice.

Core features:
- skill draft start
- six active skills
- item/equipment build flags
- passive choices
- skill trees
- dungeon route progression
- chain/cascade systems
- respec and guide panels
CHANGELOG
fi

echo
echo "== Initializing git repo =="
if [ ! -d .git ]; then
    git init
fi

git branch -M main

echo
echo "== Setting git identity if missing =="
if ! git config user.name >/dev/null; then
    git config user.name "Kaey"
fi

if ! git config user.email >/dev/null; then
    git config user.email "konrad.franconi@gmail.com"
fi

echo
echo "== Git status =="
git status --short

echo
echo "== First commit =="
git add .
git commit -m "patch 003 baseline" || echo "Nothing new to commit."

echo
echo "== GitHub login check =="
if ! gh auth status >/dev/null 2>&1; then
    echo
    echo "You need to log in to GitHub."
    echo "A browser login should open. Choose GitHub.com, HTTPS, and authenticate."
    gh auth login -w
fi

echo
echo "== Creating GitHub repo and pushing =="
if gh repo view "$REPO_NAME" >/dev/null 2>&1; then
    echo "Repo already exists on GitHub."
else
    echo "Creating PUBLIC repo so ChatGPT can inspect it when you provide the link."
    gh repo create "$REPO_NAME" --public --source=. --remote=origin --push
fi

if ! git remote get-url origin >/dev/null 2>&1; then
    gh repo set-default "$REPO_NAME"
    git remote add origin "https://github.com/$(gh api user --jq .login)/$REPO_NAME.git"
fi

git push -u origin main

echo
echo "== DONE =="
echo "Repo URL:"
gh repo view --json url --jq .url
