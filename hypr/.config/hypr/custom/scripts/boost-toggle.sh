#!/bin/sh
# Super+Alt+B: toggle CPU turbo boost via /usr/local/bin/cpu-boost (passwordless sudo rule).
# If cpu-boost isn't installed (see ~/.config/cpu-boost/install.sh) say so instead of failing silently.
if state=$(sudo -n /usr/local/bin/cpu-boost toggle 2>/dev/null); then
    notify-send -a "CPU boost" -i cpu "CPU boost: $state" "$( [ "$state" = on ] && echo 'Plný výkon (až 4,4 GHz)' || echo 'Vypnutý – chladnejšie, max. 3,2 GHz')"
else
    notify-send -a "CPU boost" -i dialog-warning "CPU boost sa nedá prepnúť" "Prepínač cpu-boost nie je nainštalovaný (sudo sh ~/.config/cpu-boost/install.sh)."
fi
