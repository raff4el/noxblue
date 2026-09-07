<div align="center">

# noxblue

**A hardened Fedora Atomic desktop: [secureblue](https://secureblue.dev) underneath, [niri](https://github.com/YaLTeR/niri) + [Noctalia](https://noctalia.dev) on top.**

[![build](https://github.com/raff4el/noxblue/actions/workflows/build.yml/badge.svg)](https://github.com/raff4el/noxblue/actions/workflows/build.yml)
[![built with BlueBuild](https://img.shields.io/badge/built%20with-BlueBuild-blue)](https://blue-build.org/)
[![Fedora 44](https://img.shields.io/badge/Fedora-44-51a2da)](https://fedoraproject.org/)

</div>

---

noxblue takes secureblue's hardened Fedora Atomic image and replaces the GNOME
session with a scrollable-tiling one: **niri** as the compositor, **Noctalia** as
the shell, and **greetd** + **noctalia-greeter** as the login screen.

Noctalia v5 is a single native C++/OpenGL ES binary that provides the bar,
launcher, notifications, clipboard history, lock screen, wallpapers, polkit
agent, screenshot tools and settings UI. There is no bar daemon, no separate
launcher and no notification daemon to configure — and, because it comes from
Fedora's own repositories, **no COPRs are used at all**.

## What's inside

| | |
| --- | --- |
| **Base** | secureblue `silverblue-main-hardened`, Fedora 44 |
| **Compositor** | niri 26.04 |
| **Shell** | Noctalia 5 |
| **Login** | greetd + noctalia-greeter |
| **Terminal** | Alacritty, Nushell |
| **Extras** | Homebrew, Flatpak (Flathub system + user), zram tuned for desktop use |
| **Flatpaks** | Flatseal, Warehouse, Mission Center, Clapper, Loupe |

Screencast and file-chooser portals, `gnome-keyring`, `wireplumber`, `ddcutil`
(external-monitor brightness) and `upower` are installed explicitly, because weak
dependencies are turned off for the whole package set.

## Install

> [!WARNING]
> Rebasing to a custom image is [an experimental Fedora feature](https://www.fedoraproject.org/wiki/Changes/OstreeNativeContainerStable).
> Try it at your own discretion, and keep a way back — `rpm-ostree rollback`, or
> a TTY, in case the graphical session does not come up.

### Coming from secureblue

secureblue ships a container policy of **`"default": [{"type": "reject"}]`**, and
its `docker` transport rejects anything not explicitly listed. The usual
BlueBuild "rebase unsigned first, then signed" dance therefore **does not work**
— the unsigned pull is refused before it starts:

```
error: Preparing import: Fetching manifest: failed to invoke method OpenImage:
Running image docker://ghcr.io/raff4el/noxblue:latest is rejected by policy.
```

Trust the image's key up front instead, and go straight to the signed rebase.
This is the same key path, policy entry and registry config the image installs
for itself, so nothing is loosened permanently — and unlike the unsigned route,
you never run an unverified image.

```bash
git clone https://github.com/raff4el/noxblue && cd noxblue

# 1. Trust noxblue's signing key
run0 install -Dm644 cosign.pub /etc/pki/containers/noxblue.pub

# 2. Note that this repository carries cosign sigstore attachments
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

Once you are on noxblue and it works, hand the files you touched back to the
image. ostree keeps anything in `/etc` that differs from the deployment it came
from, so your copies would otherwise shadow the image's forever — which matters
the day the signing key rotates: the old key you pinned by hand would win over
the new one the image ships, and updates would stop verifying.

The image installs the same public key at the same path and its own
`registries.d` entry, so nothing is lost:

```bash
# Replace the edited policy.json and the pinned key with the image's copies.
# Identical content today; the point is that ostree stops treating them as
# local modifications.
run0 cp /usr/etc/containers/policy.json /etc/containers/policy.json
run0 cp /usr/etc/pki/containers/noxblue.pub /etc/pki/containers/noxblue.pub

# The hand-written registries.d file and the backup are redundant now.
run0 rm /etc/containers/registries.d/raff4el-noxblue.yaml \
        /etc/containers/policy.json.bak

run0 ostree admin config-diff | grep -E 'containers|pki'   # expect no output
```

### Coming from stock Fedora Atomic

A permissive default policy allows the conventional two-step rebase:

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/raff4el/noxblue:latest
systemctl reboot
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/raff4el/noxblue:latest
systemctl reboot
```

`latest` follows the newest build, but stays on the Fedora release pinned in
`recipes/recipe.yml`, so it will not carry you across a major version by
surprise.

### Verify the image

Independently of any rebase:

```bash
cosign verify --key cosign.pub ghcr.io/raff4el/noxblue
```

## Keybindings

`Mod` is the Super key. These are the defaults in `/etc/niri/config.kdl`; press
<kbd>Mod</kbd>+<kbd>Shift</kbd>+<kbd>/</kbd> for niri's own overlay.

| Key | Action |
| --- | --- |
| <kbd>Mod</kbd>+<kbd>Space</kbd> / <kbd>Mod</kbd>+<kbd>D</kbd> | Application launcher |
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
| <kbd>Mod</kbd>+<kbd>R</kbd> / <kbd>F</kbd> / <kbd>Shift</kbd>+<kbd>F</kbd> | Cycle column width / maximize / fullscreen |
| <kbd>Print</kbd> | Screenshot (niri) |
| <kbd>Shift</kbd>+<kbd>Print</kbd> | Screenshot region with annotation (Noctalia) |

## Security trade-offs

noxblue departs from stock secureblue in ways worth knowing about before you
rebase:

- **Screencopy is not restricted.** secureblue only ships images for desktops
  that secure privileged Wayland protocols (GNOME, KDE, Sway, COSMIC). Under
  niri, any application speaking `wlr-screencopy` can capture the whole desktop,
  including other applications' windows. This is the main property traded away
  by swapping out GNOME.
- **Homebrew is installed and self-updates daily** — a second package manager
  pulling unsigned prebuilt bottles, outside rpm-ostree and outside this image's
  signing chain. Some brew binaries also misbehave under `hardened_malloc`.
- **One third-party repository is used at build time.** Fedora carries
  `noctalia`, but not `noctalia-greeter`, which exists only in Fyra Labs'
  [Terra](https://terra.fyralabs.com). `files/dnf/terra.repo` restricts Terra to
  that single package with `includepkgs`, keeps `gpgcheck` and `repo_gpgcheck`
  on, and pins it below Fedora by priority. `cleanup: true` then removes it from
  the finished image, so it is not left behind as a trusted source for runtime
  `rpm-ostree install`.
- **Xwayland is not installed.** `xwayland-satellite` is a weak dependency of
  niri and is deliberately excluded, so X11-only applications will not start.
  Add it to `recipes/recipe.yml` if you need them.
- **The login screen always lists local accounts.** noctalia-greeter has no
  "hide the last username" option. Pinning `[user].default` in `greeter.toml`
  opens straight on one account's password prompt, but that hides the picker,
  not the other accounts.

Weak dependencies are disabled for the package set, so niri does not silently
drag in waybar/fuzzel/swaylock (redundant with Noctalia) or Xwayland. Everything
actually needed is listed explicitly in the recipe.

## Configuration

### niri

`/etc/niri/config.kdl` holds the system defaults. Either **add to them** by
putting your bindings in `~/.config/niri/local.kdl`, which the system config
includes at the end, or **replace them** with your own
`~/.config/niri/config.kdl`, which niri prefers outright.

Three things in the system config are there for Noctalia specifically:
`spawn-at-startup "noctalia"`, a `debug` flag
(`honor-xdg-activation-with-invalid-serial`) without which notification actions
and launcher window-focusing silently do nothing, and a `layer-rule` putting
Noctalia's backdrop inside niri's overview.

niri 26.04 also supports blur behind windows and layer surfaces. It is not
enabled here; see [Noctalia's niri page](https://docs.noctalia.dev/noctalia/compositor-settings/niri/)
for blocks to drop into `local.kdl`.

### Noctalia

Noctalia merges every `*.toml` in `~/.config/noctalia/`. Anything changed through
the GUI lands in `~/.local/state/noctalia/settings.toml` and overrides your
files — worth knowing when a hand-written value seems to be ignored.

The image ships one setting via `/etc/skel`: `[shell] polkit_agent = true`.

secureblue removes `sudo`, `su` and `pkexec` to eliminate suid-root binaries, and
uses `run0` instead. polkit itself remains, and `run0` authorizes through it — so
something still has to *display* the authorization prompt, and that something is
a polkit authentication agent. Noctalia has one built in but leaves it off by
default, assuming the desktop already supplies one. Nothing here does: gdm is
disabled and GNOME's agent ships with gnome-shell. Turn it back off only if you
run a different agent.

Without an agent, `run0` still works from a terminal, where it prompts on the
TTY. Anything launched from the shell with no controlling terminal has nowhere
to put the prompt and fails silently.

> [!IMPORTANT]
> `/etc/skel` is only read when an account is created. If you rebased with an
> existing account, copy `/etc/skel/.config/noctalia/config.toml` into
> `~/.config/noctalia/` yourself or the polkit agent stays off.

### Login screen

greetd runs `noctalia-greeter-session`, which starts the greeter's own bundled
wlroots compositor — there is no second compositor config to maintain. Note that
`/etc/greetd/config.toml` uses `user = "greetd"`, the account Fedora's greetd
package actually creates, rather than the `greeter` in upstream Noctalia's
(Arch-oriented) documentation.

The greeter has two config files in `/var/lib/noctalia-greeter/`:

| File | Owner | Purpose |
| --- | --- | --- |
| `greeter.toml` | this image | Declarative settings. Wins wherever both files set the same key. |
| `sync.toml` | the greeter | Last session, last colour scheme, and anything pushed by Noctalia's appearance sync. |

`greeter.toml` is installed from
`files/system/usr/share/noctalia-greeter-theme/greeter.toml` by `tmpfiles.d` with
`C+`, so edits in this repo reach installed systems on the next boot — and hand
edits on a running system get overwritten. Change `C+` to `C` in
`files/system/usr/lib/tmpfiles.d/noctalia-greeter.conf` if you would rather
configure it live. `sync.toml` is never touched either way.

The greeter shows a solid black background and the built-in Noctalia palette by
default. To change that, either set `[appearance.wallpaper] path` in
`greeter.toml`, or set `scheme = "Synced"` and use **Settings → Security →
Noctalia Greeter → Sync Now** to push the running session's wallpaper, palette
and monitor layout to the login screen.

It makes no network requests — there is no weather or location feature to turn
off. User avatars come from AccountsService, which is not installed, so a generic
icon is shown; add `accountsservice` to the recipe if you want them.

> [!NOTE]
> Appearance sync uses the **legacy** privilege path here, which escalates
> through `run0`. Noctalia's newer *constrained* sync — the one that can be made
> passwordless — has to launch `pkexec`, because the helper checks `PKEXEC_UID`,
> and secureblue does not ship `pkexec`. That path needs greeter 1.5.0 or newer
> anyway, and Terra currently packages 1.3.1, so it does not apply. If a future
> greeter bump enables constrained sync, expect Sync Now to break and set
> `[shell.greeter_sync] privilege_command` accordingly.

> [!WARNING]
> The greeter does **not** inherit the system keyboard layout — it uses the
> `[keyboard]` block in `greeter.toml`, which defaults to US. On a non-US layout
> you may be unable to type your password. Set `layout` there before rebooting
> into it.

## Building it yourself

Fork the repository, then see [BlueBuild's documentation](https://blue-build.org/how-to/setup/).
You will need a cosign keypair and a `SIGNING_SECRET` repository secret; the
public half in `cosign.pub` must be replaced with your own.

An offline ISO can be generated on a Fedora Atomic host — see
[BlueBuild's ISO guide](https://blue-build.org/how-to/generate-iso/). ISOs are
too large to distribute through GitHub releases.

### Bumping the Fedora release

`image-version` in `recipes/recipe.yml` and the hardcoded release in
`files/dnf/terra.repo` must move together. Terra's own `.repo` file uses
`$releasever`, which is not reliable on top of the secureblue base, so the
release is pinned by hand.

### No starship

`starship` is not in Fedora's repositories, and this image uses no COPRs.
Homebrew is installed, so `brew install starship` if you want the prompt.

## Credits

[secureblue](https://github.com/secureblue/secureblue) ·
[niri](https://github.com/YaLTeR/niri) ·
[Noctalia](https://github.com/noctalia-dev/noctalia) ·
[BlueBuild](https://github.com/blue-build) ·
[Terra](https://github.com/terrapkg/packages)

## License

[Apache-2.0](LICENSE). This repository is a build recipe; the packages it
installs carry their own licenses.
