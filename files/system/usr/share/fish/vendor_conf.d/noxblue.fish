# noxblue: fish defaults for every user. Vendor conf.d runs before
# ~/.config/fish/config.fish, so anything here can be overridden there.

status is-interactive; or return

# The login banner. bash shows it through /etc/profile.d/user-motd.sh, which
# fish does not read; same opt-out file, so `ujust toggle-user-motd` still
# hides it. Replaces fish's own greeting unless you have set one.
if test -x /usr/libexec/noxblue-motd
    and not test -e "$(set -q XDG_CONFIG_HOME; and echo $XDG_CONFIG_HOME; or echo $HOME/.config)/no-show-user-motd"
    /usr/libexec/noxblue-motd
end
set -q fish_greeting; or set -g fish_greeting ''

# Starship, with the image's config unless you have your own. STARSHIP_CONFIG
# is only set when ~/.config/starship.toml is missing, so creating that file
# (`cp /usr/share/noxblue/starship.toml ~/.config/`) takes over entirely.
# Starship looks there regardless of XDG_CONFIG_HOME.
if command -q starship
    if not set -q STARSHIP_CONFIG
        and not test -e ~/.config/starship.toml
        set -gx STARSHIP_CONFIG /usr/share/noxblue/starship.toml
    end
    starship init fish | source
end
