-- Overrides of ~/.config/hypr/hyprland/variables.lua (only if the app is installed;
-- otherwise end-4's "first available" defaults stay)
if is_file_exists("/usr/bin/kitty") then terminal = "kitty -1" end
if is_file_exists("/usr/bin/brave") then browser = "brave" end
