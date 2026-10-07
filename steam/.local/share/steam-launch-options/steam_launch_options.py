"""Give every installed Steam game the same launch options (Steam has no global setting).

  $HOME/.local/bin/nvidia-run gamemoderun mangohud %command%

Run while Steam is CLOSED (Steam rewrites localconfig.vdf on exit); the steam-launch-options@<id>.path unit (after Steam exits) calls
this automatically, so newly installed games get it on the next start of Steam.
Games that already have different custom launch options are left alone.
Usage: steam-launch-options [--dry-run] [--quiet]
"""
import pathlib
import re
import shutil
import subprocess
import sys

import vdf

# full path: Steam's PATH does not include ~/.local/bin ("nvidia-run: command not found")
OPTIONS = "$HOME/.local/bin/nvidia-run gamemoderun mangohud %command%"
STEAM = pathlib.Path.home() / ".local/share/Steam"
NOT_GAMES = re.compile(r"Proton|Steam Linux Runtime|Steamworks|Steam Runtime|SteamVR", re.I)

dry = "--dry-run" in sys.argv
quiet = "--quiet" in sys.argv


def say(msg):
    if not quiet:
        print(msg)


# switched off in the settings app (~/.config/rice/settings.json -> games.steamOptions)?
try:
    import json
    if json.loads((pathlib.Path.home() / ".config/rice/settings.json").read_text()).get("games", {}).get("steamOptions", True) is False:
        say("vypnuté v nastaveniach (Hry → Steam voľby)")
        sys.exit(0)
except (OSError, ValueError):
    pass

if subprocess.run(["pgrep", "-x", "steam"], capture_output=True).returncode == 0:
    say("Steam beží – zavri ho (Steam → Exit), inak by zmeny pri ukončení prepísal.")
    sys.exit(1)

games = {}
for acf in (STEAM / "steamapps").glob("appmanifest_*.acf"):
    state = vdf.loads(acf.read_text(errors="replace")).get("AppState", {})
    name = state.get("name", "")
    if state.get("appid") and not NOT_GAMES.search(name):
        games[state["appid"]] = name

for cfg in (STEAM / "userdata").glob("*/config/localconfig.vdf"):
    data = vdf.loads(cfg.read_text(errors="replace"), mapper=vdf.VDFDict)
    store = data["UserLocalConfigStore"]
    for key in ("Software", "Valve", "Steam", "apps"):
        if key not in store:
            store[key] = vdf.VDFDict()
        store = store[key]
    apps = store

    changed = []
    for appid, name in sorted(games.items(), key=lambda kv: kv[1]):
        if appid not in apps:
            apps[appid] = vdf.VDFDict()
        current = apps[appid].get("LaunchOptions", "")
        if current == OPTIONS:
            continue
        if current and "nvidia-run" not in current:
            say(f"  ponechávam vlastné voľby: {name}: {current}")
            continue
        if "LaunchOptions" in apps[appid]:
            del apps[appid]["LaunchOptions"]
        apps[appid]["LaunchOptions"] = OPTIONS
        changed.append(name)

    if changed and not dry:
        shutil.copy2(cfg, cfg.with_suffix(".vdf.bak-launchopts"))
        cfg.write_text(vdf.dumps(data, pretty=True))
    for name in changed:
        say(f"  {'(skúška) ' if dry else ''}nastavené: {name}")
    if not changed:
        say("  všetky hry už majú voľby nastavené")
