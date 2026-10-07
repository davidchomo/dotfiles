#!/bin/sh
# One-time install (needs sudo).  Undo: sudo sh ~/.config/cpu-boost/install.sh uninstall
# Boost always starts ON after boot; Super+Alt+B (or `sudo cpu-boost off`) turns it off until reboot.
set -e
D="$(dirname "$(readlink -f "$0")")"
if [ "${1:-}" = uninstall ]; then
    systemctl disable --now cpu-boost.timer 2>/dev/null || true
    /usr/local/bin/cpu-boost on 2>/dev/null || true
    rm -f /usr/local/bin/cpu-boost /etc/systemd/system/cpu-boost.service /etc/systemd/system/cpu-boost.timer /etc/sudoers.d/91-cpu-boost
    rm -rf /var/lib/cpu-boost /run/cpu-boost
    systemctl daemon-reload; echo "cpu-boost removed, boost is on"; exit 0
fi
if [ ! -e /sys/devices/system/cpu/cpufreq/boost ] && [ ! -e /sys/devices/system/cpu/cpufreq/policy0/boost ]; then
    echo "This CPU/driver has no boost switch. Not installing."; exit 1
fi
install -m 755 -o root -g root "$D/cpu-boost" /usr/local/bin/cpu-boost
install -m 644 -o root -g root "$D/cpu-boost.service" /etc/systemd/system/cpu-boost.service
install -m 644 -o root -g root "$D/cpu-boost.timer" /etc/systemd/system/cpu-boost.timer
echo "${SUDO_USER:-$(logname 2>/dev/null || echo root)} ALL=(root) NOPASSWD: /usr/local/bin/cpu-boost" > /etc/sudoers.d/91-cpu-boost
chmod 440 /etc/sudoers.d/91-cpu-boost
visudo -c -q
rm -rf /var/lib/cpu-boost                       # old version kept a persistent state here
systemctl daemon-reload
systemctl disable cpu-boost.service 2>/dev/null || true   # old version ran it at boot
systemctl enable --now cpu-boost.timer
/usr/local/bin/cpu-boost on >/dev/null
echo "installed; boost: $(/usr/local/bin/cpu-boost status)"
