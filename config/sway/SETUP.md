# Sway desktop setup

Plain sway on Debian 13 (trixie), managed by hand. Graphical tools take care of
system settings; everything else lives in `~/.config/sway/config`.

All config files (and this file) live in the dotfiles repo `~/.dotfiles`
and are symlinked into place by [rcm](https://github.com/thoughtbot/rcm)'s
`rcup`. Editing `~/.config/...` edits the repo; commit the change there.

## Packages

```sh
sudo apt install sway network-manager-gnome blueman pavucontrol nwg-displays nwg-look lxpolkit waybar desktop-base swaylock swayidle jq
```

| Area          | Tool                                         | Package                 |
|---------------|----------------------------------------------|-------------------------|
| Network       | `nm-applet` (tray), `nm-connection-editor`   | `network-manager-gnome` |
| Bluetooth     | `blueman-applet` (tray), `blueman-manager`   | `blueman`               |
| Sound         | `pavucontrol` (works with PipeWire)          | `pavucontrol`           |
| Displays      | `nwg-displays`                               | `nwg-displays`          |
| GTK theme, fonts, cursor | `nwg-look`                        | `nwg-look`              |
| Admin password prompts | `lxpolkit` (polkit agent)          | `lxpolkit`              |
| Status bar and tray | `waybar` (replaces swaybar)            | `waybar`                |
| Wallpaper     | `swaybg` (comes with sway), Debian artwork   | `desktop-base`          |
| Screen lock   | `swaylock`, auto-lock with `swayidle`        | `swaylock` `swayidle`   |

The network and Bluetooth tools need these services to be active:

```sh
systemctl is-active NetworkManager bluetooth
```

## Files

Repo path → installed path: `~/.dotfiles/config/X` → `~/.config/X`.

```
~/.config/sway/
├── config     main sway config (Debian default plus the changes below)
├── outputs    display layout, written by nwg-displays (NOT in the repo)
└── SETUP.md   this file

~/.config/waybar/
├── config.jsonc   bar modules and click actions
└── style.css      bar colors and fonts

~/.config/foot/
└── foot.ini       terminal look (alacritty-style, One Dark)

~/.config/swaylock/
└── config         lock screen look (wallpaper, One Dark indicator)

~/.local/share/fonts/JetBrainsMonoNerdFont/   Nerd Font (not from apt, NOT in the repo)

~/.claude/CLAUDE.md   tells Claude Code to keep this file up to date
```

Not tracked: `outputs` (machine-specific monitor names, written by
nwg-displays) and the Nerd Font files (install them, see "Nerd Font").
To add a new config file to the repo:

```sh
mkdir -p ~/.dotfiles/config/<app>
mv ~/.config/<app>/<file> ~/.dotfiles/config/<app>/
cd ~/.dotfiles && rcup config/<app>/<file>   # creates the symlink
```

## Changes from the Debian default config

1. **Display layout include**, after the "Output configuration" section:
   ```
   include ~/.config/sway/outputs
   ```
   Run `nwg-displays`, arrange the screens, then click **Apply**. It writes
   `~/.config/sway/outputs`, which this line loads. If the file is missing,
   sway ignores the include and uses its automatic layout. The file is
   machine-specific, so it's not in the dotfiles repo.

2. **Touchpad: reversed ("natural") scrolling and tap to click** (input section):
   ```
   input type:touchpad {
       natural_scroll enabled
       tap enabled
       tap_button_map lrm
   }
   ```
   Tap to click: one-finger tap is a left click, two-finger tap a right click,
   three-finger tap a middle click (`lrm` = left/right/middle; `lmr` would
   swap the two- and three-finger taps). Tapping is off by default in sway.
   To reverse the mouse wheel too, add the same block with `type:pointer`.
   Device names: `swaymsg -t get_inputs`. Docs: `man 5 sway-input`.

3. **Swedish keyboard layout**:
   ```
   input type:keyboard {
       xkb_layout se
   }
   ```

4. **Polkit agent and tray applets autostart** (end of file):
   ```
   exec lxpolkit
   exec nm-applet --indicator
   exec blueman-applet
   ```
   `--indicator` makes nm-applet use the StatusNotifier tray protocol, which
   is the one waybar's tray supports.
   `lxpolkit` shows a password dialog when a GUI app needs admin rights
   (e.g. blueman, system-wide network connections). Plain sway has none,
   so without it those actions fail silently.

5. **waybar instead of swaybar**: the whole `bar { ... }` block is replaced by:
   ```
   bar {
       swaybar_command waybar
   }
   ```
   Why: swaybar in sway 1.10 shows tray icons but can't open their menus, so
   clicking the nm-applet icon did nothing. waybar supports tray menus.
   Sway starts and restarts waybar itself (also on `$mod+Shift+c`).

6. **Volume keys use `wpctl`** (Utilities section). Debian's default config
   uses `pactl`, which is in `pulseaudio-utils` and not installed here, so
   the keys did nothing. The system runs PipeWire, whose `wpctl` comes with
   `wireplumber`:
   ```
   bindsym --locked XF86AudioMute exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
   bindsym --locked XF86AudioLowerVolume exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
   bindsym --locked XF86AudioRaiseVolume exec wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+
   bindsym --locked XF86AudioMicMute exec wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
   ```
   `-l 1.0` caps the volume at 100%. Brightness keys use `brightnessctl`,
   which works unchanged.

7. **Minimal window style (Regolith-like)**, section "Window appearance",
   just before the key bindings:
   ```
   default_border pixel 2
   default_floating_border pixel 2
   gaps inner 6
   hide_edge_borders smart
   client.focused          #4c7899 #285577 #ffffff #7aa6c8   #4c7899
   client.focused_inactive #777777 #323232 #aaaaaa #777777   #777777
   client.unfocused        #777777 #222222 #888888 #777777   #777777
   client.urgent           #900000 #900000 #ffffff #900000   #900000
   ```
   There are no title bars, just a 2px frame: blue on the focused window,
   gray (`#777777`) on the others. Windows have 6px gaps between them,
   and a window alone on its workspace has no frame (`hide_edge_borders smart`).
   `child_border` (the last column) is the frame color; `indicator` shows
   where the next window will split. Tabbed and stacked layouts still show
   tab titles.
   - `default_border` only applies to new windows. To restyle open windows:
     `swaymsg '[all] border pixel 2'`.
   - Toggle one window's title bar: `swaymsg border toggle`.
   - Change gaps live: `swaymsg gaps inner all set 6` (the config value is
     the default for new workspaces).
   - Docs: `man 5 sway` (search for `client.focused`, `gaps`,
     `hide_edge_borders`).

8. **Wallpaper** (Output configuration section, below the commented example):
   ```
   output * bg /usr/share/desktop-base/ceratopsian-theme/wallpaper/contents/images/1920x1200.svg fill
   ```
   Debian 13's "Ceratopsian" artwork from `desktop-base`, in the 1920x1200 size
   that matches the laptop screen (other sizes are in the same folder). sway
   runs `swaybg` to draw it; SVG works through gdk-pixbuf's SVG loader.
   - `*` = all monitors; use a name like `eDP-1` for a per-monitor image
     (`swaymsg -t get_outputs` lists the names).
   - Modes: `fill` (cover and crop), `fit`, `stretch`, `center`, `tile`.
     Plain color: `output * bg #282c34 solid_color`.
   - Other Debian themes are in `/usr/share/desktop-base/*-theme/wallpaper/`.
     More wallpapers: `sway-backgrounds`, `gnome-backgrounds`,
     `plasma-workspace-wallpapers`.

9. **Screen locking** (Idle configuration section, plus a key binding):
   ```
   exec swayidle -w \
            timeout 300 'swaylock -f' \
            timeout 600 'swaymsg "output * power off"' resume 'swaymsg "output * power on"' \
            before-sleep 'swaylock -f' \
            lock 'swaylock -f'

   bindsym $mod+Escape exec swaylock -f
   ```
   - `$mod+Escape` locks right away (same key as Regolith; `$mod+l` is
     focus-right).
   - Locks after 5 min idle; screen turns off after 10 min and comes back on
     at the next key press or mouse movement.
   - `before-sleep` locks before suspend (e.g. closing the lid), so the screen
     is already locked on wake. `-w` makes the system wait until the lock is up.
   - `lock` makes `loginctl lock-session` lock too.
   - `-f` sends swaylock to the background once the screen is locked.
   - Unlock: type your password and press Enter. Pressing Enter with nothing
     typed is ignored.

   Look (`~/.config/swaylock/config`): the Ceratopsian wallpaper and a One
   Dark indicator. Blue while typing, orange on backspace, red on a wrong
   password, orange ring when Caps Lock is on. Failed attempts are counted.
   Option names: `swaylock --help`, written without the leading `--`.
   `swayidle` is started by `exec`, so after changing its timeouts, log out and
   back in, or run `pkill swayidle` and start the new command with `swaymsg exec`.

10. **Browser key binding** (variables at the top, plus Key bindings > Basics):
    ```
    set $browser firefox-esr

    bindsym $mod+Shift+Return exec $browser
    ```
    `$mod+Shift+Return` opens Firefox ESR, next to `$mod+Return` for the
    terminal. To use another browser, change `$browser`.

## waybar

Right side, left to right: volume, network, Bluetooth, screen brightness,
battery, tray. Labels are plain text (`vol`, `wifi`, `bt`, ...), so no icon font
is needed. For icons, install `fonts-font-awesome` and put glyphs in the
`format` strings.

| Module      | Left-click               | Other                                 |
|-------------|--------------------------|---------------------------------------|
| `vol`       | `pavucontrol`            | scroll: volume, right-click: mute     |
| `wifi`/`eth`| `nm-connection-editor`   | hover: interface and IP               |
| `bt`        | `blueman-manager`        | hover: connected devices              |
| clock       |                          | hover: calendar                       |
| tray icons  | app-specific             | right-click: the app's menu           |

After editing `~/.config/waybar/*`, reload sway (`$mod+Shift+c`) to restart
waybar. To see errors, run `waybar` in a terminal (stop the running one first
with `pkill waybar`). Docs: `man waybar`, `man waybar-<module>`.

## Terminal (foot)

The terminal is `foot` (`set $term foot` in the sway config, opened with
`$mod+Return`). It's built for Wayland, fast and light. It's styled like
alacritty with the One Dark theme:

- One Dark colors, copied from alacritty's official theme repo
  (`alacritty/alacritty-theme`, `themes/one_dark.toml`): background
  `#282c34`, foreground `#abb2bf`, plus the 16 ANSI colors. To try another
  theme, copy its `primary`/`normal`/`bright` values into `[colors]` as
  `foreground`/`background`/`regular0-7`/`bright0-7` (without the `#`).
- JetBrainsMono Nerd Font at 11pt (the icon glyphs are needed by starship)
- no padding, steady block cursor

Config: `~/.config/foot/foot.ini`. Changes apply to newly opened terminals.
Check it with `foot --check-config`. Docs: `man 5 foot.ini`; the commented
defaults are in `/etc/xdg/foot/foot.ini`.

Why not alacritty itself: foot is native Wayland, uses less memory, supports
sixel images, and was already installed. Both leave tabs and splits to sway.

## Nerd Font

JetBrainsMono Nerd Font v3.5.1, installed only for this user (Debian doesn't
package Nerd Fonts). Only the standard `JetBrainsMonoNerdFont-*.ttf`
variant is installed, not the `Mono` or `Propo` variants:

```sh
mkdir -p ~/tmp-nf && cd ~/tmp-nf
curl -fLO https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/JetBrainsMono.tar.xz
tar -xJf JetBrainsMono.tar.xz
mkdir -p ~/.local/share/fonts/JetBrainsMonoNerdFont
cp JetBrainsMonoNerdFont-*.ttf ~/.local/share/fonts/JetBrainsMonoNerdFont/
fc-cache -f && cd && rm -rf ~/tmp-nf
fc-match 'JetBrainsMono Nerd Font'   # should print JetBrainsMonoNerdFont-Regular.ttf
```

To update, repeat with a newer release tag from
https://github.com/ryanoasis/nerd-fonts/releases.

## Everyday use

| Task                         | How                                              |
|------------------------------|--------------------------------------------------|
| Wi-Fi / VPN                  | Right-click tray network icon, or click `wifi` in the bar |
| Pair Bluetooth device        | Click `bt` in the bar, or right-click tray icon  |
| Volume, output/input device  | Click `vol` in the bar (`pavucontrol`)           |
| Monitor layout / resolution  | `nwg-displays`, then **Apply**                   |
| GTK theme, icons, font, cursor | `nwg-look`, then **Apply**                     |
| Lock screen                  | `$mod+Escape`                                    |
| Open web browser             | `$mod+Shift+Return`                              |
| Move workspace to other display | `$mod+m` (needs `jq`)                       |
| Reload sway config           | `$mod+Shift+c` (`exec` lines only run at login; `exec_always` runs on every reload) |
| Check config for errors      | `sway -C -c ~/.config/sway/config`               |

## Replicating on a new machine

1. Install the packages above (the apt command in "Packages").
2. Install rcm and clone the dotfiles:
   ```sh
   sudo apt install rcm
   git clone git@github.com:dwretman/dotfiles.git ~/.dotfiles
   ```
3. Link everything. The first run points at the host's rcrc (it excludes
   `README.md`), and it gets linked to `~/.rcrc` for later runs:
   ```sh
   env RCRC=~/.dotfiles/host-$(hostname)/rcrc rcup
   ```
   On a host without a `host-<hostname>` dir, plain `rcup -x README.md` works.
   If a real file is already in the way (e.g. Debian's default sway config),
   rcup asks before replacing it.
4. Install the Nerd Font (see "Nerd Font").
5. Run `nwg-displays` to set up the monitor layout (writes `outputs`).
6. Check device names with `swaymsg -t get_inputs` if you need per-device input
   settings.
7. Log out and back in, so that the `exec` autostart lines run.
