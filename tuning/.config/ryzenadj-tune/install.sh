#!/bin/sh
# One-time install (needs sudo).  Disable: sudo systemctl disable --now ryzenadj-tune.timer
# Remove completely:              sudo sh ~/.config/ryzenadj-tune/install.sh uninstall
set -e
D="$(dirname "$(readlink -f "$0")")"
if [ "${1:-}" = uninstall ]; then
    systemctl disable --now ryzenadj-tune.timer 2>/dev/null || true
    rm -f /usr/local/bin/ryzenadj-tune /etc/systemd/system/ryzenadj-tune.service \
          /etc/systemd/system/ryzenadj-tune.timer /etc/modules-load.d/ryzen_smu.conf
    systemctl daemon-reload
    echo "removed; limits return to firmware defaults on next profile change or reboot"; exit 0
fi
install -m 755 -o root -g root "$D/ryzenadj-tune" /usr/local/bin/ryzenadj-tune
install -m 644 -o root -g root "$D/ryzenadj-tune.service" /etc/systemd/system/ryzenadj-tune.service
install -m 644 -o root -g root "$D/ryzenadj-tune.timer" /etc/systemd/system/ryzenadj-tune.timer
echo ryzen_smu > /etc/modules-load.d/ryzen_smu.conf
systemctl daemon-reload
systemctl enable --now ryzenadj-tune.timer
echo "installed; timer: $(systemctl is-active ryzenadj-tune.timer)"
