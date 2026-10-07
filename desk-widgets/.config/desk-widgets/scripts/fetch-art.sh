#!/usr/bin/env bash
# Download Spotify cover art to a local cache and print the file path.
# (Quickshell-git crashed inside its own network stack loading https images, so widgets only
# ever load local files.)
url="$1"
dir="$HOME/.cache/desk-widgets/art"
mkdir -p "$dir"
f="$dir/$(printf %s "$url" | md5sum | cut -c1-16).jpg"
if [[ ! -s "$f" ]]; then
    curl -sfL --max-time 10 -o "$f.part" "$url" && mv "$f.part" "$f" || { rm -f "$f.part"; exit 1; }
fi
echo "$f"
# keep the cache small
ls -1t "$dir" | tail -n +60 | while read -r old; do rm -f "$dir/$old"; done
