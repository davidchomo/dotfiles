#!/bin/sh
# One-time install (needs sudo). Emergency: kernel cmdline "noryzenadj" skips the service.
#  Disable: sudo systemctl disable --now ryzenadj-tune.timer
# Remove completely:              sudo sh ~/.config/ryzenadj-tune/install.sh uninstall
set -e
# Power limits / temperature cap are tuned for ASUS ROG Zephyrus G14 GA401Q* (Ryzen 7 5800HS).
# Other machines need their own values – refuse unless FORCE=1.
if [ "${1:-}" != uninstall ] && ! grep -q "GA401Q" /sys/class/dmi/id/product_name 2>/dev/null && [ "${FORCE:-0}" != 1 ]; then
    echo "ryzenadj-tune is tuned for ASUS G14 GA401Q only (this is: $(cat /sys/class/dmi/id/product_name 2>/dev/null)). Not installing."
    exit 1
fi
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
systemctl daemon-reload
systemctl enable --now ryzenadj-tune.timer
echo "installed; timer: $(systemctl is-active ryzenadj-tune.timer)"
