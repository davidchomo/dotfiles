#!/bin/sh
# One-time install (needs sudo). Undo: sudo sh ~/.config/cpu-boost/install.sh uninstall
set -e
if [ "${1:-}" != uninstall ] && [ ! -w /sys/devices/system/cpu/cpufreq/boost ] && [ ! -e /sys/devices/system/cpu/cpufreq/boost ]; then
    echo "This CPU/driver has no global boost switch (/sys/devices/system/cpu/cpufreq/boost). Not installing."; exit 1
fi
D="$(dirname "$(readlink -f "$0")")"
if [ "${1:-}" = uninstall ]; then
    systemctl disable --now cpu-boost.service 2>/dev/null || true
    /usr/local/bin/cpu-boost on 2>/dev/null || true
    rm -f /usr/local/bin/cpu-boost /etc/systemd/system/cpu-boost.service /etc/sudoers.d/91-cpu-boost
    rm -rf /var/lib/cpu-boost
    systemctl daemon-reload; echo "cpu-boost removed, boost is on"; exit 0
fi
install -m 755 -o root -g root "$D/cpu-boost" /usr/local/bin/cpu-boost
install -m 644 -o root -g root "$D/cpu-boost.service" /etc/systemd/system/cpu-boost.service
echo "${SUDO_USER:-debury} ALL=(root) NOPASSWD: /usr/local/bin/cpu-boost" > /etc/sudoers.d/91-cpu-boost
chmod 440 /etc/sudoers.d/91-cpu-boost
visudo -c -q
systemctl daemon-reload
systemctl enable cpu-boost.service
echo "installed; current boost: $(/usr/local/bin/cpu-boost status)"
