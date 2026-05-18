#!/usr/bin/env bash
set -euo pipefail
cd /home/kaey/Desktop/Game

fail=0

for f in scripts/ui/UIPanelRoot.gd scripts/ui/GameHUD.gd scripts/core/GameRoot.gd; do
  [ -f "$f" ] || continue
  if grep -nE '(^|[[:space:]])mouse_filter[[:space:]]*=' "$f" | grep -vE '\.mouse_filter|\)\.mouse_filter' >/tmp/085s_mouse_filter_hits.txt; then
    echo "[085S][ERROR] Bare mouse_filter assignment remains in $f:"
    cat /tmp/085s_mouse_filter_hits.txt
    fail=1
  fi
  if grep -n '_rf_085n_sync_input_ownership\|_rf_085n_apply_mouse_filter_to_controls' "$f" >/tmp/085s_residual_hits.txt; then
    echo "[085S][ERROR] Residual 085N input helper remains in $f:"
    cat /tmp/085s_residual_hits.txt
    fail=1
  fi
  if grep -nE 'panels is Control|hud is Control|panels as Control|hud as Control' "$f" >/tmp/085s_bad_cast_hits.txt; then
    echo "[085S][ERROR] Impossible Control cast/check remains in $f:"
    cat /tmp/085s_bad_cast_hits.txt
    fail=1
  fi
done

if grep -R --line-number 'Camera2D.clear_current\|\.clear_current()' scripts scenes 2>/dev/null; then
  echo "[085S][ERROR] Invalid Camera2D.clear_current call remains."
  fail=1
fi

if [ "$fail" -ne 0 ]; then
  exit 1
fi

echo "[085S] Validator passed."
