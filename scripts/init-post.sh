#!/bin/bash
#
# @author: Ryan Tsien <i@bitbili.net>
#

set -e
source "$(dirname "$0")/init-common.sh"

trap '
_do rm -rf /tmp/*
_do rm -rf _x_scripts
' EXIT

# set /bin/zsh as default shell
_do usermod -s /bin/zsh root
