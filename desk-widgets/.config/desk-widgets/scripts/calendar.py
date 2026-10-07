#!/usr/bin/env python3
"""Print upcoming Google Calendar events as JSON.

Reads the secret iCal address from ~/.config/desk-widgets/secrets/ical-url (one URL per line,
several calendars allowed). The last successful download is cached so the widget still works
offline. Run with the desk-widgets venv (icalendar + recurring-ical-events).
"""
import datetime as dt
import sys
import json
import pathlib
import urllib.request

import icalendar
import recurring_ical_events

HOME = pathlib.Path.home()
URL_FILE = HOME / ".config/desk-widgets/secrets/ical-url"
CACHE_DIR = HOME / ".cache/desk-widgets"
DAYS_AHEAD = 60
if "--days" in sys.argv:  # set from the settings app (RiceSettings.widgets.calendarDays)
    DAYS_AHEAD = max(1, int(sys.argv[sys.argv.index("--days") + 1]))
MAX_EVENTS = 8


def fetch(url, cache):
    try:
        with urllib.request.urlopen(url, timeout=20) as r:
            data = r.read()
        cache.write_bytes(data)
        cache.chmod(0o600)  # private calendar data
        return data, False
    except OSError:
        if cache.exists():
            return cache.read_bytes(), True
        raise


def as_local(value):
    """Return (aware local datetime, all_day) for a DTSTART/DTEND value."""
    if isinstance(value, dt.datetime):
        if value.tzinfo is None:
            value = value.astimezone()
        return value.astimezone(), False
    return dt.datetime.combine(value, dt.time.min).astimezone(), True


def main():
    if not URL_FILE.exists():
        return {"status": "no-url", "events": []}
    urls = [u.strip() for u in URL_FILE.read_text().splitlines() if u.strip()]
    CACHE_DIR.mkdir(mode=0o700, parents=True, exist_ok=True)

    now = dt.datetime.now().astimezone()
    until = now + dt.timedelta(days=DAYS_AHEAD)
    events, offline = [], False
    for i, url in enumerate(urls):
        try:
            raw, stale = fetch(url, CACHE_DIR / f"calendar-{i}.ics")
        except OSError:
            offline = True
            continue
        offline |= stale
        cal = icalendar.Calendar.from_ical(raw)
        for ev in recurring_ical_events.of(cal).between(now - dt.timedelta(days=1), until):
            start, all_day = as_local(ev["DTSTART"].dt)
            end = as_local(ev["DTEND"].dt)[0] if "DTEND" in ev else start
            if end <= now:
                continue
            events.append({
                "title": str(ev.get("SUMMARY", "(bez názvu)")),
                "location": str(ev.get("LOCATION", "")),
                "start": start.isoformat(),
                "end": end.isoformat(),
                "allDay": all_day,
            })
    events.sort(key=lambda e: e["start"])
    return {"status": "offline" if offline else "ok", "events": events[:MAX_EVENTS],
            "updated": now.isoformat(timespec="minutes")}


if __name__ == "__main__":
    try:
        print(json.dumps(main(), ensure_ascii=False))
    except Exception as e:  # never crash the widget; report instead
        print(json.dumps({"status": "error", "error": str(e), "events": []}))
