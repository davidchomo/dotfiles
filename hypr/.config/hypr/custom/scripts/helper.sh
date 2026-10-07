#!/usr/bin/env bash
# Toggle the side shortcut panel (kitty window with class "rice-helper").
pid=$(hyprctl clients -j | jq -r '[.[] | select(.class == "rice-helper")][0].pid // empty')
if [[ -n "$pid" ]]; then
    kill "$pid"
else
    kitty --class rice-helper -o background_opacity=0.85 -o window_padding_width=12 \
        -o font_size=10.5 sh -c "printf '\\033[?25l'; cat '$HOME/.config/hypr/custom/scripts/helper.txt'; exec sleep infinity" &
fi
