#!/bin/bash
# ==============================================================================
#  KeePassXC Proxy Bridge Wrapper for Flatpak Google Chrome
#  Author: bratiska6-pixel
#  License: MIT
# ==============================================================================

# Application reference for Flatpak KeePassXC
APP_REF="org.keepassxc.KeePassXC/x86_64/stable"

# Search for the installation root (user-level or system-level)
for inst in "$HOME/.local/share/flatpak" "/var/lib/flatpak"; do
    if [ -d "$inst/app/$APP_REF" ]; then
        FLATPAK_INST="$inst"
        break
    fi
done

[ -z "$FLATPAK_INST" ] && exit 1

APP_PATH="$FLATPAK_INST/app/$APP_REF/active"

# Retrieve the exact KDE Platform runtime version from application metadata
RUNTIME_REF=$(awk -F'=' '$1=="runtime" { print $2 }' < "$APP_PATH/metadata")
RUNTIME_PATH="$FLATPAK_INST/runtime/$RUNTIME_REF/active"

# Launch keepassxc-proxy inside the runtime container via flatpak-spawn
exec flatpak-spawn \
    --env=LD_LIBRARY_PATH=/app/lib \
    --app-path="$APP_PATH/files" \
    --usr-path="$RUNTIME_PATH/files" \
    -- /app/bin/keepassxc-proxy "$@"
