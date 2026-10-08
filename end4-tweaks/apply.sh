#!/bin/sh
# Small tweaks to end-4 (illogical-impulse) that have no setting of their own.
# end-4 updates overwrite them: run this again afterwards (install.sh does).
#   fullscreen-notifications.patch – no notification popups over a full-screen
#   window (games, video); they still go to the right sidebar.
set -e
ii="$HOME/.config/quickshell/ii"
[ -d "$ii" ] || { echo "end-4 not installed"; exit 0; }
cd "$(dirname "$(readlink -f "$0")")"
for p in *.patch; do
    if patch -s -p1 -N --dry-run -d "$ii" < "$p" >/dev/null 2>&1; then
        patch -s -p1 -N -d "$ii" < "$p" && echo "applied: $p"
    elif patch -s -p1 -R --dry-run -d "$ii" < "$p" >/dev/null 2>&1; then
        echo "already applied: $p"
    else
        echo "skipped (end-4 changed): $p"
    fi
done
