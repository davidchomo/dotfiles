#!/usr/bin/env python3
"""Stream system stats as one JSON object per line (every INTERVAL seconds).

Sensors are looked up by hwmon *name* because hwmonN numbering can change between boots.
The NVIDIA dGPU is only queried while its PCI runtime PM status is "active": calling
nvidia-smi on a suspended dGPU would wake it up and drain the battery.
"""
import glob
import json
import os
import subprocess
import sys
import time

INTERVAL = 2.0
NVIDIA_PCI = "/sys/bus/pci/devices/0000:01:00.0"


def read(path, default=None):
    try:
        with open(path) as f:
            return f.read().strip()
    except OSError:
        return default


def hwmon(name):
    for d in glob.glob("/sys/class/hwmon/hwmon*"):
        if read(f"{d}/name") == name:
            return d
    return None


def milli(path):
    v = read(path)
    return round(int(v) / 1000, 1) if v and v.lstrip("-").isdigit() else None


def cpu_times():
    fields = read("/proc/stat", "").splitlines()[0].split()[1:]
    vals = list(map(int, fields))
    idle = vals[3] + vals[4]  # idle + iowait
    return idle, sum(vals)


def mem():
    info = {}
    for line in read("/proc/meminfo", "").splitlines():
        k, v = line.split(":", 1)
        info[k] = int(v.split()[0])
    total = info["MemTotal"]
    used = total - info["MemAvailable"]
    return round(used / 1048576, 1), round(total / 1048576, 1)


def nvidia_in_use():
    """True if one of our processes (a game, prime-run app) has the NVIDIA device open.

    Only then is it OK to call nvidia-smi: querying an idle-but-awake dGPU every few seconds
    keeps resetting its idle timer, so it would never runtime-suspend again (measured: ~9 W).
    """
    for fd_dir in glob.glob("/proc/[0-9]*/fd"):
        try:
            for fd in os.listdir(fd_dir):
                if os.readlink(f"{fd_dir}/{fd}") == "/dev/nvidia0":
                    return True
        except OSError:
            continue
    return False


_dgpu_cache = {"t": 0.0, "v": None}


def dgpu():
    status = read(f"{NVIDIA_PCI}/power/runtime_status", "unknown")
    if status != "active":
        return {"state": status}
    if not nvidia_in_use():
        return {"state": "idle"}            # awake but unused: don't touch it, let it sleep
    # in use (e.g. a game): read temperature at most every 10 s
    if time.time() - _dgpu_cache["t"] < 10 and _dgpu_cache["v"]:
        return _dgpu_cache["v"]
    _dgpu_cache["t"] = time.time()
    _dgpu_cache["v"] = _query_nvidia_smi()
    return _dgpu_cache["v"]


def _query_nvidia_smi():
    try:
        out = subprocess.run(
            ["nvidia-smi", "--query-gpu=temperature.gpu,utilization.gpu", "--format=csv,noheader,nounits"],
            capture_output=True, text=True, timeout=2,
        ).stdout.strip()
        temp, util = (int(x) for x in out.split(","))
        return {"state": "active", "temp": temp, "util": util}
    except (OSError, ValueError, subprocess.TimeoutExpired):
        return {"state": "active"}


def main():
    k10 = hwmon("k10temp")
    amd = hwmon("amdgpu")
    asus = hwmon("asus")
    amd_busy = os.path.realpath(f"{amd}/device") + "/gpu_busy_percent" if amd else None
    prev_idle, prev_total = cpu_times()
    while True:
        time.sleep(INTERVAL)
        idle, total = cpu_times()
        dt = total - prev_total
        cpu = round(100 * (1 - (idle - prev_idle) / dt)) if dt else 0
        prev_idle, prev_total = idle, total
        used, mtotal = mem()
        busy = read(amd_busy) if amd_busy else None
        data = {
            "cpu": {"load": cpu, "temp": milli(f"{k10}/temp1_input") if k10 else None},
            "igpu": {"temp": milli(f"{amd}/temp1_input") if amd else None,
                     "load": int(busy) if busy and busy.isdigit() else None},
            "dgpu": dgpu(),
            "ram": {"used": used, "total": mtotal},
            "fans": {"cpu": int(read(f"{asus}/fan1_input", "0")) if asus else None,
                     "gpu": int(read(f"{asus}/fan2_input", "0")) if asus else None},
            "battery": {"pct": int(read("/sys/class/power_supply/BAT0/capacity", "0")),
                        "status": read("/sys/class/power_supply/BAT0/status", "")},
        }
        print(json.dumps(data), flush=True)


if __name__ == "__main__":
    try:
        main()
    except (KeyboardInterrupt, BrokenPipeError):
        sys.exit(0)
