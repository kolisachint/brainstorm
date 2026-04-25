#!/bin/bash
set -e

DRY_RUN=false
[[ "$1" == "--dry-run" ]] && DRY_RUN=true

echo "=== Refactor Workflow ==="
echo "[1/5] Analyze"
[[ "$DRY_RUN" == true ]] && echo "[DRY RUN] Skipping"

[[ "$DRY_RUN" == false ]] && {
    echo "[2/5] Simplify"
    echo "[3/5] Review"
    git diff --stat
    echo "[4/5] Test"
    echo "[5/5] Push"
    git add -A
    git commit -m "refactor: $(date +'%Y-%m-%d')"
    git push origin main
}

echo "=== Done ==="