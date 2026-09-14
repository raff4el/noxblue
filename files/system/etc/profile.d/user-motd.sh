#!/usr/bin/sh

# SPDX-FileCopyrightText: Copyright 2025 Universal Blue
# SPDX-FileCopyrightText: Copyright 2026 The Secureblue Authors
#
# SPDX-License-Identifier: Apache-2.0

# noxblue: secureblue's file, but running /usr/libexec/noxblue-motd instead of
# /usr/libexec/secureblue-motd (the top of noxblue-motd says why). The
# no-show-user-motd check is untouched, so `ujust toggle-user-motd` still works.

# Prevent doublesourcing
if [ -z "${USERMOTDSOURCED-}" ]; then
    USERMOTDSOURCED='Y'
    if [ -d "${HOME}" ] && ! [ -e "${XDG_CONFIG_HOME:-"${HOME}/.config"}/no-show-user-motd" ] && [ -x '/usr/libexec/noxblue-motd' ]; then
        /usr/libexec/noxblue-motd
    fi
fi
