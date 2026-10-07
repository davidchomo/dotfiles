#!/bin/sh
# gamemode hook: switch power-profiles-daemon to "performance" while a game runs, then restore
# the profile that was active before (Balanced/Quiet). In Performance the ryzenadj-tune timer
# leaves the CPU temperature cap at the firmware default, so games get full CPU power.
state="${XDG_RUNTIME_DIR:-/tmp}/gamemode-prev-profile"
case "$1" in
    start)
        [ -f "$state" ] || powerprofilesctl get > "$state"
        powerprofilesctl set performance
        notify-send -a GameMode -i applications-games "GameMode" "Výkonový profil zapnutý" ;;
    end)
        powerprofilesctl set "$(cat "$state" 2>/dev/null || echo balanced)"
        rm -f "$state"
        notify-send -a GameMode -i applications-games "GameMode" "Späť na $(powerprofilesctl get)" ;;
esac
