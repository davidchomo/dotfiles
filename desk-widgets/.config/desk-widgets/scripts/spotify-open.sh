#!/usr/bin/env bash
# Focus the running Spotify window (switching to its workspace), or start Spotify.
addr=$(hyprctl clients -j | jq -r '[.[] | select(.class | test("^spotify$"; "i"))][0].address // empty')
if [[ -n "$addr" ]]; then
    hyprctl dispatch "hl.dsp.focus({ window = \"address:$addr\" })" >/dev/null
else
    setsid -f spotify-launcher >/dev/null 2>&1
fi
