# Inštalácia – Hyprland rice (end-4 + doplnky)

Tieto dotfiles sú **doplnky nad [end-4 / illogical-impulse](https://github.com/end-4/dots-hyprland)**:
widgety na plochu, Claude Code v bočnom paneli, Steam/NVIDIA nastavenia, MangoHud, skratky…
Samotný vzhľad (bar, panely, farby z tapety) je z end-4.

> ⚠️ Pred inštaláciou si sprav zálohu: `cp -r ~/.config ~/.config.bak-$(date +%F)`
> a ak máš btrfs + snapper aj snapshot: `sudo snapper -c root create -d "pred rice"`.

## 1. Predpoklady
- Arch / **CachyOS**, Hyprland **≥ 0.55 s Lua configom** (`~/.config/hypr/hyprland.lua`).
- Balíky:
  ```fish
  sudo pacman -S --needed git jq uv python mangohud gamemode lib32-gamemode playerctl brightnessctl
  ```
  Voliteľné: `kdeconnect sshfs` (mobil), `steam`, `brave-bin` (prehliadač s HW dekódovaním videa).

## 2. end-4
```fish
git clone https://github.com/end-4/dots-hyprland ~/.cache/dots-hyprland
cd ~/.cache/dots-hyprland
./setup install --skip-sysupdate --skip-plasmaintg
```
- Na otázky odpovedaj `y` (aj na zálohu).
- Ak pacman nahlási konflikt `adw-gtk-theme` vs `adw-gtk-theme-git`: v druhom termináli
  `sudo pacman -U --asdeps ~/.cache/yay/adw-gtk-theme-git/*.pkg.tar.zst` (odpovedz `y`), potom v installeri `r`.
- end-4 prepíše `~/.config/fish` a `~/.config/kitty` – ak si chceš nechať svoje, vráť ich zo zálohy.

## 3. Tieto dotfiles
```fish
git clone <adresa-repozitára> ~/dotfiles
cd ~/dotfiles
./install.sh --check      # iba kontrola, nič nemení
./install.sh              # nainštaluje (existujúce súbory zálohuje ako *.bak-<dátum>)
./install.sh kitty fish   # + aj môj terminál a fish (voliteľné)
```
Skript sa dá spustiť opakovane. Sám zistí:
- **hybridný notebook AMD + NVIDIA** → Hyprland pobeží len na AMD, NVIDIA v nečinnosti spí,
  hry ju dostanú cez `nvidia-run` (inde sa nič nemení),
- Steam účty → hry dostanú spúšťacie voľby automaticky (pozri nižšie),
- Claude Code (ak máš `claude`) → pridá ho do AI panela.

## 4. Monitory
Uprav `~/.config/hypr/custom/local.lua` (príklady sú v ňom), názvy monitorov ukáže `hyprctl monitors`.
Potom sa **odhlás a prihlás**.

## 5. Voliteľné (sudo)
| Čo | Príkaz |
|---|---|
| Oprava „prihlasovacia obrazovka sa niekedy neukáže“ (greetd) | `sudo install -Dm644 ~/dotfiles/system/etc/systemd/system/greetd.service.d/10-wait-for-gpu.conf /etc/systemd/system/greetd.service.d/10-wait-for-gpu.conf` |
| Prepínač CPU boostu (Super+Alt+B) | `sudo sh ~/.config/cpu-boost/install.sh && sudo systemctl disable cpu-boost.service` |
| `ryzenadj-tune` (limity CPU) | **iba ASUS G14 GA401Q** – na inom PC sa odmietne nainštalovať |

## 6. Funkcie
- **Super+F1** – panel s najdôležitejšími skratkami, **Super+/** – všetky skratky end-4.
- **Widgety** na externom monitore (iný monitor: premenná `DESK_WIDGETS_SCREEN`, napr. `HDMI-A-1`):
  - kalendár: tajnú iCal adresu z Google Calendar (Nastavenia → kalendár → *Tajná adresa vo formáte iCal*)
    vlož do `~/.config/desk-widgets/secrets/ical-url`,
  - fotky: `~/Pictures/Desk` (alebo z mobilu cez KDE Connect, tlačidlo ↻ vo widgete),
  - Spotify, systém (teploty, záťaž).
- **Steam**: každá hra dostane `$HOME/.local/bin/nvidia-run gamemoderun mangohud %command%`.
  Zapíše sa po ukončení Steamu (Steam → Exit) – potom ho znova otvor. Hry s vlastnými voľbami ostanú bez zmeny.
  Ručne: zavri Steam a spusti `steam-launch-options`.
- **MangoHud**: limit 60 FPS (ľavý Shift+F1 prepína 60/120/bez limitu), pravý Shift+F12 skryje.
- **AI panel** (Super+A): Claude Code s plnými právami nad počítačom – pozor, čo mu povieš.

## Keď niečo nejde
- **Po prihlásení čierna obrazovka / Hyprland nenaštartuje** (hybridný notebook):
  na inom TTY (Ctrl+Alt+F3) `rm ~/.config/hypr/gpu-amd` a prihlás sa znova.
- **Hra nejde na NVIDIA**: MangoHud musí ukazovať názov NVIDIA karty; skontroluj spúšťacie voľby.
- **Všetko vrátiť**: zmaž symlinky, ktoré `install.sh` vytvoril, a premenuj `*.bak-<dátum>` späť.
