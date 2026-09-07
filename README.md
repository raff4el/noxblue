<div align="center">

# noxblue

**[secureblue](https://secureblue.dev) underneath, [niri](https://github.com/YaLTeR/niri) + [Noctalia](https://noctalia.dev) on top.**

[![build](https://github.com/raff4el/noxblue/actions/workflows/build.yml/badge.svg)](https://github.com/raff4el/noxblue/actions/workflows/build.yml)
[![built with BlueBuild](https://img.shields.io/badge/built%20with-BlueBuild-blue)](https://blue-build.org/)
[![Fedora 44](https://img.shields.io/badge/Fedora-44-51a2da)](https://fedoraproject.org/)

</div>

secureblue's hardened Fedora Sway Atomic image with the Sway session swapped
for **niri** (compositor), **Noctalia** (shell) and **greetd +
noctalia-greeter** (login). Noctalia is a single native binary covering bar,
launcher, notifications, clipboard, lock screen, wallpapers, polkit agent and
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

```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/raff4el/noxblue:latest
```

That works after an unsigned first rebase on stock Fedora Atomic. Coming from
secureblue, its reject-by-default policy needs the key trusted first: see
[INSTALL.md](INSTALL.md). Keybindings and configuration are in
[CONFIGURATION.md](CONFIGURATION.md).

## Trade-offs vs stock secureblue

- **Screencopy is unrestricted.** Under niri any `wlr-screencopy` client can
  capture the whole desktop. This is the main property lost by swapping the
  session; secureblue's own Sway portal blanking does not cover niri.
- **Sway is still on the image**, installed but never started. Removing it is
  an opt-in block in the recipe.
- **Homebrew** comes from the secureblue base through `brew-proxy`. Bottles are
  unsigned binaries outside the image's signing chain.
- **Fonts** (Nerd Fonts, Google Fonts) are downloaded unsigned at build time.
- **Terra** supplies exactly one package at build time, `noctalia-greeter`,
  restricted with `includepkgs`, GPG-checked and removed from the finished
  image. See `files/dnf/terra.repo`.
- **No Xwayland.** Add `xwayland-satellite` to the recipe for X11 apps.
- **The login screen lists local accounts.** noctalia-greeter cannot hide them.

## Building

Fork it, follow [BlueBuild's setup](https://blue-build.org/how-to/setup/),
replace `cosign.pub` with your own key and add the private half as the
`SIGNING_SECRET` secret. CI validates the niri config and TOML files before
every build. Install [Renovate](https://github.com/apps/renovate) on the fork
for base-image, Terra and Actions bumps; `image-version` in the recipe and the
release in `files/dnf/terra.repo` move together.

## Credits

[secureblue](https://github.com/secureblue/secureblue) ·
[niri](https://github.com/YaLTeR/niri) ·
[Noctalia](https://github.com/noctalia-dev/noctalia) ·
[BlueBuild](https://github.com/blue-build) ·
[Terra](https://github.com/terrapkg/packages)

## License

[Apache-2.0](LICENSE). This repository is a build recipe; the packages it
installs carry their own licenses.
