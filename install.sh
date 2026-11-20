#!/usr/bin/env bash
# Installs (or with --uninstall removes) the plasmoid for the current user.
set -euo pipefail

ID="com.drvy.tintish2taskbar"
HERE="$(cd "$(dirname "$0")" && pwd)"
DEST="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/plasmoids/$ID"

if [[ "${1:-}" == "--uninstall" ]]; then
    rm -rf "$DEST"
    echo "Removed $DEST"
    exit 0
fi

mkdir -p "$DEST"
rsync -a --delete "$HERE/$ID/" "$DEST/"
echo "Installed to $DEST. Restart plasmashell (kquitapp6 plasmashell; kstart plasmashell) and add 'Tintish2 Taskbar' to a horizontal panel."
