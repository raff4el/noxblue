# Configuring noxblue

## Keybindings

`Mod` is Super. Defaults from `/etc/niri/config.kdl`;
<kbd>Mod</kbd>+<kbd>Shift</kbd>+<kbd>/</kbd> shows niri's own overlay.

| Key | Action |
| --- | --- |
| <kbd>Mod</kbd>+<kbd>Space</kbd> / <kbd>Mod</kbd>+<kbd>D</kbd> | Launcher |
| <kbd>Mod</kbd>+<kbd>V</kbd> | Clipboard history |
| <kbd>Mod</kbd>+<kbd>S</kbd> | Control Center |
| <kbd>Mod</kbd>+<kbd>N</kbd> | Notifications |
| <kbd>Mod</kbd>+<kbd>W</kbd> | Wallpaper picker |
| <kbd>Mod</kbd>+<kbd>,</kbd> | Noctalia settings |
| <kbd>Mod</kbd>+<kbd>X</kbd> | Session menu |
| <kbd>Super</kbd>+<kbd>Alt</kbd>+<kbd>L</kbd> | Lock |
| <kbd>Mod</kbd>+<kbd>T</kbd> | Terminal |
| <kbd>Mod</kbd>+<kbd>Q</kbd> | Close window |
| <kbd>Mod</kbd>+<kbd>O</kbd> / <kbd>Mod</kbd>+<kbd>Tab</kbd> | Overview |
| <kbd>Mod</kbd>+<kbd>H</kbd> <kbd>J</kbd> <kbd>K</kbd> <kbd>L</kbd> or arrows | Move focus |
| <kbd>Mod</kbd>+<kbd>Shift</kbd>+ same | Move window |
| <kbd>Mod</kbd>+<kbd>Ctrl</kbd>+ same | Focus monitor |
| <kbd>Mod</kbd>+<kbd>Shift</kbd>+<kbd>Ctrl</kbd>+ same | Move column to monitor |
| <kbd>Mod</kbd>+<kbd>1</kbd>…<kbd>9</kbd> | Switch workspace |
| <kbd>Mod</kbd>+<kbd>R</kbd> / <kbd>F</kbd> / <kbd>Shift</kbd>+<kbd>F</kbd> | Column width / maximize / fullscreen |
| <kbd>Print</kbd> | Screenshot (niri) |
| <kbd>Shift</kbd>+<kbd>Print</kbd> | Screenshot region with annotation (Noctalia) |
| <kbd>Mod</kbd>+<kbd>Shift</kbd>+<kbd>S</kbd> / <kbd>T</kbd> / <kbd>C</kbd> | Screen Toolkit panel / OCR / colour picker |

## niri

`/etc/niri/config.kdl` is the system default. Extend it in
`~/.config/niri/local.kdl` (included at the end) or replace it with
`~/.config/niri/config.kdl`. The Noctalia-specific parts (startup spawn, the
`honor-xdg-activation-with-invalid-serial` debug flag, the backdrop layer rule)
are explained in the file.

## Noctalia

Merges every `*.toml` in `~/.config/noctalia/`; GUI changes land in
`~/.local/state/noctalia/settings.toml` and override them. The image ships
`[shell] polkit_agent = true` via `/etc/skel`: secureblue has no `pkexec`, and
`run0` needs an agent to show prompts outside a terminal.

### Screen Toolkit

The `/etc/skel` config also enables the community plugin
`alexander/screen-toolkit` and puts its widget on the bar before the clipboard
button (left click: tool panel, right click: colour picker). Noctalia clones the
plugin from GitHub on first start; the image ships the tools it calls.

| Key | Tool |
| --- | --- |
| <kbd>Mod</kbd>+<kbd>Shift</kbd>+<kbd>S</kbd> | Tool panel |
| <kbd>Mod</kbd>+<kbd>Shift</kbd>+<kbd>T</kbd> | OCR a region to the clipboard |
| <kbd>Mod</kbd>+<kbd>Shift</kbd>+<kbd>C</kbd> | Pick a colour |

Any other tool binds the same way:
`noctalia msg plugin alexander/screen-toolkit:service all <tool>` with `qr`,
`palette`, `lens`, `measure`, `annotate`, `recordMp4`, `recordStop`, …

- **OCR languages**: English and German data are installed, but the plugin
  defaults to `eng` only. Set **OCR language** to `eng+deu` in the plugin's
  settings (the gear under **Settings → Plugins**). Other languages need
  `tesseract-langpack-<code>` in the recipe.
- **Colour picker**: the plugin calls `hyprpicker`, which Fedora does not
  carry. `/usr/bin/hyprpicker` here is a stand-in over `niri msg pick-color`;
  it only does `--format=hex`, which is all the plugin uses.
- **Recording** uses Fedora's `wf-recorder`. It defaults to VP9 + Opus and the
  plugin passes it no codec, so MP4s are VP9 rather than H.264; the plugin's
  codec setting only applies to `wl-screenrec` and `gpu-screen-recorder`,
  neither of which is installed. ffmpeg itself is secureblue's full negativo17
  build with x264, so H.264 works everywhere else.
- **Share**, **Lens** and **Translate** send the capture or text to uguu.se,
  Google and Google Translate. Nothing leaves the machine unless you use them.

For an account that existed before this, copy the `[plugins]`,
`[widget.screen-toolkit]` and `[bar.default]` tables from
`/etc/skel/.config/noctalia/config.toml` into `~/.config/noctalia/`, or run
`noctalia msg plugins enable alexander/screen-toolkit` and add the widget
through the bar's Add-widget picker.

## Shell

Alacritty opens **fish** through `/etc/alacritty/alacritty.toml`; the login
shell stays bash, so `/etc/profile.d` still builds the session environment.
Alacritty reads that file only when you have no config of your own: if you do,
add `import = ["/etc/alacritty/alacritty.toml"]` or your own
`[terminal.shell]`.

`/usr/share/fish/vendor_conf.d/noxblue.fish` shows the login banner in place of
fish's greeting and starts **Starship** with `/usr/share/noxblue/starship.toml`:
OS, directory, git branch/state/status/line counts, toolbox/distrobox container,
detected toolchains, command duration, exit status and time. Copy it to
`~/.config/starship.toml` to customize; once that file exists the image's
config is ignored.

## GTK applications

No gnome-settings-daemon runs here, so GTK apps read
`org.gnome.desktop.interface` from GSettings directly. The image defaults
`color-scheme` to `prefer-dark` and `gtk-theme` to `adw-gtk3-dark`, which
covers both GTK 4 apps and GTK 3 ones like Thunar. To have them follow
Noctalia's own light/dark mode instead, enable the **GTK 3** and **GTK 4**
templates under **Settings → Templates**; they set the same keys per user.

Flatpaks cannot see `/usr/share/themes` on the host, so the theme name above
would resolve to nothing inside a sandbox and GTK would fall back to light
Adwaita -- a dark desktop with light Electron menu bars. The image installs
`org.gtk.Gtk3theme.adw-gtk3-dark` and `org.gtk.Gtk3theme.adw-gtk3` as system
flatpaks to cover both modes. Only the extension matching the active theme
name applies, and system scope reaches user-installed flatpaks.

## Keyring

Unlocked at login through greetd's PAM stack, the way gdm does it. Confirm:

```bash
gdbus call --session -d org.freedesktop.secrets \
  -o /org/freedesktop/secrets/collection/login \
  -m org.freedesktop.DBus.Properties.Get org.freedesktop.Secret.Collection Locked
# expect (<false>,)
```

## Login screen

greetd runs `noctalia-greeter-session` as user `greetd` (Fedora's account, not
upstream's `greeter`). State lives in `/var/lib/noctalia-greeter/`:

- `greeter.toml` is force-copied from
  `files/system/usr/share/noctalia-greeter-theme/` on every boot by tmpfiles.d.
  Edit the repo rather than the live file, or change `C+` to `C` in
  `files/system/usr/lib/tmpfiles.d/noctalia-greeter.conf`.
- `sync.toml` is the greeter's own state and is never touched.

For a wallpaper set `[appearance.wallpaper] path`, or set `scheme = "Synced"`
and use **Settings → Security → Noctalia Greeter → Sync Now**. Sync uses the
legacy `run0` path; the constrained one needs `pkexec` and greeter ≥ 1.5,
neither of which applies here. No AccountsService, so avatars are generic.

> [!WARNING]
> The greeter uses `[keyboard]` in `greeter.toml` (default US), not the system
> layout. Set `layout` before rebooting on a non-US keyboard.
