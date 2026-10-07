#!/usr/bin/env bash
# One-way photo sync Pixel -> ~/Pictures/Desk over KDE Connect (sftp), on demand.
# Only ADDS new photos from the phone folder Pictures/Desk; never deletes anything locally
# (photos can also be dragged into ~/Pictures/Desk by hand). Nothing on the phone is modified.
set -uo pipefail

PHONE_DIR="Pictures/Desk"
DEST="$HOME/Pictures/Desk"
APP="Fotky z Pixelu"

notify() { notify-send -a "$APP" -i smartphone "$@"; }

dev=$(kdeconnect-cli -a --id-only 2>/dev/null | head -n1)
if [[ -z "$dev" ]]; then
    notify "Pixel nie je dostupný" "Mobil musí byť na rovnakej Wi-Fi a mať otvorený KDE Connect."
    exit 1
fi

obj="/modules/kdeconnect/devices/$dev/sftp"
iface="org.kde.kdeconnect.device.sftp"
if [[ "$(busctl --user --timeout=40 call org.kde.kdeconnect "$obj" "$iface" mountAndWait 2>/dev/null)" != "b true" ]]; then
    err=$(busctl --user call org.kde.kdeconnect "$obj" "$iface" getMountError 2>/dev/null | sed 's/^s "//; s/"$//')
    notify "Nepodarilo sa pripojiť Pixel" "${err:-Povoľ v KDE Connect „Filesystem expose“.}"
    exit 1
fi
mnt=$(busctl --user call org.kde.kdeconnect "$obj" "$iface" mountPoint | sed 's/^s "//; s/"$//')
src="$mnt/storage/emulated/0/$PHONE_DIR"

if [[ ! -d "$src" ]]; then
    notify "V Pixeli chýba priečinok" "Vytvor $PHONE_DIR a daj doň fotky pre plochu."
    exit 1
fi

mkdir -p "$DEST"
log=$(rsync -rt --ignore-existing --out-format='%o %n' \
    --include='*.[jJ][pP][gG]' --include='*.[jJ][pP][eE][gG]' \
    --include='*.[pP][nN][gG]' --include='*.[wW][eE][bB][pP]' --exclude='*' \
    "$src/" "$DEST/" 2>&1)
rc=$?
if (( rc != 0 )); then
    notify "Synchronizácia zlyhala" "rsync skončil s kódom $rc"
    exit $rc
fi

added=$(grep -c '^send ' <<<"$log")
total=$(find "$DEST" -maxdepth 1 -type f | wc -l)
notify "Fotky synchronizované" "Pridané: $added · spolu na ploche: $total"
