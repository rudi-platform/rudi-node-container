#!/bin/bash
# ==================================================================================================
# Regenerates ./npmci/package-lock.json from the current state of all module package.json files.
# Only updates the lockfile without installing node_modules.
# ==================================================================================================
set -euo pipefail

PRJ_DIR="$(cd "$(dirname "$0")" && pwd)"
NPMCI_DIR="${PRJ_DIR}/npmci"

cd "$NPMCI_DIR"

# Create symlinks for workspace members if they don't exist
for module in catalog storage manager jwtauth; do
    target="${NPMCI_DIR}/rudi-${module}"
    if [ ! -L "$target" ]; then
        ln -snf "../src/rudi-${module}" "$target"
    fi
done

# Regenerate only the lockfile (no node_modules)
npm install --workspaces --package-lock-only
