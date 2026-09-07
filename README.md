<div align="center">

# noxblue

**[secureblue](https://secureblue.dev) underneath, [niri](https://github.com/YaLTeR/niri) + [Noctalia](https://noctalia.dev) on top.**

[![build](https://github.com/raff4el/noxblue/actions/workflows/build.yml/badge.svg)](https://github.com/raff4el/noxblue/actions/workflows/build.yml)
[![built with BlueBuild](https://img.shields.io/badge/built%20with-BlueBuild-blue)](https://blue-build.org/)
[![Fedora 44](https://img.shields.io/badge/Fedora-44-51a2da)](https://fedoraproject.org/)

</div>

secureblue's hardened Fedora Sway Atomic image with the Sway session swapped
for **niri** (compositor), **Noctalia** (shell) and **greetd +
noctalia-greeter** (login). Noctalia is a single native binary covering bar, launcher,
notifications, clipboard history, lock screen, wallpapers, polkit agent and
screenshots, and it ships in Fedora's own repos: no COPRs.

| | |
| --- | --- |
| **Base** | secureblue `sericea-main-hardened` (Fedora Sway Atomic 44) |
| **Compositor** | niri 26.04 |
| **Shell** | Noctalia 5 |
| **Login** | greetd + noctalia-greeter |
| **Terminal** | Alacritty, Nushell |
| **Extras** | Homebrew (secureblue's `brew-proxy`), Flathub (system + user), zram tuned for desktop use |
| **Flatpaks** | Flatseal, Warehouse, Mission Center, Clapper, Loupe |

## Install

> [!WARNING]
> Rebasing to a custom image is [experimental](https://www.fedoraproject.org/wiki/Changes/OstreeNativeContainerStable).
> Keep `rpm-ostree rollback` and a TTY in mind in case the session does not come up.

### From secureblue

secureblue's container policy rejects anything not explicitly listed, so the
usual "rebase unsigned, then signed" route fails before it starts. Trust the key
first, then rebase signed directly:

```bash
git clone https://github.com/raff4el/noxblue && cd noxblue

# 1. Trust the signing key
run0 install -Dm644 cosign.pub /etc/pki/containers/noxblue.pub

# 2. Declare that the repository carries sigstore attachments
printf 'docker:\n  ghcr.io/raff4el/noxblue:\n    use-sigstore-attachments: true\n' \
  > /tmp/noxblue-registry.yaml
run0 install -Dm644 /tmp/noxblue-registry.yaml \
  /etc/containers/registries.d/raff4el-noxblue.yaml

# 3. Add the policy entry
python3 - <<'PY'
import json, pathlib
p = json.loads(pathlib.Path('/etc/containers/policy.json').read_text())
p['transports']['docker']['ghcr.io/raff4el/noxblue'] = [{
    'type': 'sigstoreSigned',
    'keyPath': '/etc/pki/containers/noxblue.pub',
    'signedIdentity': {'type': 'matchRepository'},
}]
pathlib.Path('/tmp/policy.json').write_text(json.dumps(p, indent=4) + '\n')
PY
run0 cp /etc/containers/policy.json /etc/containers/policy.json.bak
run0 install -Dm644 /tmp/policy.json /etc/containers/policy.json

# 4. Rebase
run0 -i rpm-ostree rebase ostree-image-signed:docker://ghcr.io/raff4el/noxblue:latest
systemctl reboot
```

Use `sudo` in place of `run0` if your image still has it.

Once it works, hand the files back to the image. ostree keeps local copies in
`/etc` forever, so yours would otherwise shadow a rotated key:

```bash
run0 cp /usr/etc/containers/policy.json /etc/containers/policy.json
run0 cp /usr/etc/pki/containers/noxblue.pub /etc/pki/containers/noxblue.pub
run0 rm /etc/containers/registries.d/raff4el-noxblue.yaml /etc/containers/policy.json.bak
run0 ostree admin config-diff | grep -E 'containers|pki'   # expect no output
```

### From stock Fedora Atomic

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/raff4el/noxblue:latest
systemctl reboot
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/raff4el/noxblue:latest
systemctl reboot
```

`latest` follows new builds but stays on the Fedora release pinned in
`recipes/recipe.yml`. Verify independently with
`cosign verify --key cosign.pub ghcr.io/raff4el/noxblue`.

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
| <kbd>Mod</kbd>+<kbd>1</kbd>…<kbd>9</kbd> | Switch workspace |
| <kbd>Mod</kbd>+<kbd>R</kbd> / <kbd>F</kbd> / <kbd>Shift</kbd>+<kbd>F</kbd> | Column width / maximize / fullscreen |
| <kbd>Print</kbd> | Screenshot (niri) |
| <kbd>Shift</kbd>+<kbd>Print</kbd> | Screenshot region with annotation (Noctalia) |

## Trade-offs vs stock secureblue

- **Screencopy is unrestricted.** Under niri any `wlr-screencopy` client can
  capture the whole desktop. secureblue's Sway image blanks the wlr screencast
  portal for this reason, but that only covers Sway's portal config, not
  niri's. This is the main property lost by swapping the session.
- **Sway is still on the image.** The base's own session (sway, sddm, waybar,
  foot, swaylock) is installed but never started. Removing it is an opt-in
  block in the recipe.
- **Homebrew** comes from the secureblue base, not this recipe, through its
  `brew-proxy` DBus service. Bottles are still unsigned binaries outside the
  image's signing chain.
- **Fonts** (Nerd Fonts, Google Fonts) are downloaded unsigned at build time.
  Inter and Fira Code come from Fedora.
- **Terra** supplies exactly one package at build time, `noctalia-greeter`,
  restricted with `includepkgs`, GPG-checked and removed from the finished
  image. See `files/dnf/terra.repo`.
- **No Xwayland.** Add `xwayland-satellite` to the recipe for X11 apps.
- **The login screen lists local accounts.** noctalia-greeter cannot hide them.

Weak dependencies are off for the whole package set; everything needed is
listed explicitly in `recipes/recipe.yml`.

## Configuration

**niri.** `/etc/niri/config.kdl` is the system default. Extend it in
`~/.config/niri/local.kdl` (included at the end) or replace it with
`~/.config/niri/config.kdl`. The Noctalia-specific parts (startup spawn, the
`honor-xdg-activation-with-invalid-serial` debug flag, the backdrop layer rule)
are explained in the file.

**Noctalia.** Merges every `*.toml` in `~/.config/noctalia/`; GUI changes land
in `~/.local/state/noctalia/settings.toml` and override them. The image ships
`[shell] polkit_agent = true` via `/etc/skel`: secureblue has no `pkexec`, and
`run0` needs an agent to show prompts outside a terminal. Accounts that existed
before the rebase must copy `/etc/skel/.config/noctalia/config.toml` by hand.

**Keyring.** Unlocked at login through greetd's PAM stack, same as under gdm.
Confirm with:

```bash
gdbus call --session -d org.freedesktop.secrets \
  -o /org/freedesktop/secrets/collection/login \
  -m org.freedesktop.DBus.Properties.Get org.freedesktop.Secret.Collection Locked
# expect (<false>,)
```

**Login screen.** greetd runs `noctalia-greeter-session` as user `greetd`
(Fedora's account, not upstream's `greeter`). State lives in
`/var/lib/noctalia-greeter/`: `greeter.toml` is force-copied from
`files/system/usr/share/noctalia-greeter-theme/` on every boot by tmpfiles.d,
so edit the repo rather than the live file (or change `C+` to `C` in
`files/system/usr/lib/tmpfiles.d/noctalia-greeter.conf`); `sync.toml` is the
greeter's own state and is never touched. For a wallpaper set
`[appearance.wallpaper] path`, or set `scheme = "Synced"` and use
**Settings → Security → Noctalia Greeter → Sync Now**. Sync uses the legacy
`run0` path; the constrained one needs `pkexec` and greeter ≥ 1.5, neither of
which applies here. No AccountsService, so avatars are generic.

> [!WARNING]
> The greeter uses `[keyboard]` in `greeter.toml` (default US), not the system
> layout. Set `layout` before rebooting on a non-US keyboard.

## Building

Fork it, follow [BlueBuild's setup](https://blue-build.org/how-to/setup/),
replace `cosign.pub` with your own key and add the private half as the
`SIGNING_SECRET` secret. CI validates the niri config with the pinned release's
own niri and parses the TOML files before every build. Install
[Renovate](https://github.com/apps/renovate) on the fork; it bumps the base
image and Terra release together and the Actions versions separately.

`image-version` in the recipe and the release in `files/dnf/terra.repo` must
move together. An offline ISO can be built with
[BlueBuild's ISO guide](https://blue-build.org/how-to/generate-iso/).
`starship` is not in Fedora; `brew install starship` through the base's
Homebrew.

## Credits

[secureblue](https://github.com/secureblue/secureblue) ·
[niri](https://github.com/YaLTeR/niri) ·
[Noctalia](https://github.com/noctalia-dev/noctalia) ·
[BlueBuild](https://github.com/blue-build) ·
[Terra](https://github.com/terrapkg/packages)

## License

[Apache-2.0](LICENSE). This repository is a build recipe; the packages it
installs carry their own licenses.
