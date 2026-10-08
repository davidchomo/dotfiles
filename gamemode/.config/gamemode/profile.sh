#!/bin/sh
# gamemode hook: switch power-profiles-daemon to "performance" while a game runs, then restore
# the profile that was active before (Balanced/Quiet). In Performance the ryzenadj-tune timer
# leaves the CPU temperature cap at the firmware default, so games get full CPU power.
# If "games.boostInGames" is on in the settings app (~/.config/rice/settings.json) and the
# cpu-boost tool is installed, CPU boost is switched on for the game and restored afterwards.
rt="${XDG_RUNTIME_DIR:-/tmp}"
state="$rt/gamemode-prev-profile"
boost_state="$rt/gamemode-prev-boost"
settings="$HOME/.config/rice/settings.json"
boost_in_games=$(jq -r '.games.boostInGames // false' "$settings" 2>/dev/null || echo false)
case "$1" in
    start)
        [ -f "$state" ] || powerprofilesctl get > "$state"
        powerprofilesctl set performance
        msg="Výkonový profil zapnutý"
        if [ "$boost_in_games" = true ] && prev=$(sudo -n /usr/local/bin/cpu-boost status 2>/dev/null); then
            [ -f "$boost_state" ] || echo "$prev" > "$boost_state"
            sudo -n /usr/local/bin/cpu-boost on >/dev/null && msg="$msg + CPU boost"
        fi
        # no notification here: it would pop up over the game as it starts
        : "$msg" ;;
    end)
        powerprofilesctl set "$(cat "$state" 2>/dev/null || echo balanced)"
        rm -f "$state"
        if [ -f "$boost_state" ]; then
            sudo -n /usr/local/bin/cpu-boost "$(cat "$boost_state")" >/dev/null 2>&1
            rm -f "$boost_state"
        fi
        notify-send -a GameMode -i applications-games "GameMode" "Späť na $(powerprofilesctl get)" ;;
esac
