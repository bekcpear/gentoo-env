#!/bin/bash
#
# @author: Ryan Tsien <i@bitbili.net>
#

set -e
source "$(dirname "$0")/init-common.sh"

trap '
if [[ $BUILD_BINPKGS == 1 ]]; then
	echo "uploading binpkgs ..."
	PKGDIR="$(portageq envvar PKGDIR)"
	_do chmod +x /rclone
	_do /rclone sync -P "$PKGDIR" r2:$PLATFORM/ || true
	_do rm -rf /rclone
	_do rm ~/.config/rclone/rclone.conf
	_do rmdir ~/.config/rclone
fi
_do rm -rf /tmp/*
_do rm -rf /var/log/emerge*
_do rm -rf /var/tmp/portage/*
_do rm -rf /var/cache/distfiles/*
_do rm -rf /var/cache/binpkgs
_do rm -rf /var/db/repos/gentoo
' EXIT

##
# binpkg?
BINPKG_OPTS=""
if [[ $USE_BINPKG == 1 ]]; then
	BINPKG_OPTS+=" --getbinpkg"
fi

##
# install packages
ACCEPT_KEYWORDS="$(_do portageq envvar ACCEPT_KEYWORDS)"
if [[ ${ACCEPT_KEYWORDS} =~ (amd64|arm64)([[:space:]]|$) ]]; then
	# The shellcheck-bin pkg only available on amd64 and arm64,
	# to avoid introducing a ghc build, won't install shellcheck
	# on other platforms here.
	ADDITIONAL_PKGS+=" dev-util/shellcheck-bin"
	# The sys-apps/fd is not keyworded on riscv yet
	ADDITIONAL_PKGS+=" sys-apps/fd"
	# dev-java/openjdk-bin is not available on riscv yet
	ADDITIONAL_PKGS+=" dev-java/openjdk-bin"
	# net-libs/nodejs-20.11.0 is not available on riscv64 for now
	# Issue: https://github.com/nodejs/unofficial-builds/issues/106
	# BUG: https://bugs.gentoo.org/922725
	ADDITIONAL_PKGS+=" net-libs/nodejs"
fi
_do mkdir /run/lock
_do emerge -ntvj -l$NLOAD $BINPKG_OPTS \
	--with-bdeps=y \
	--autounmask=y \
	--autounmask-license=y \
	--autounmask-write=y \
	--autounmask-continue=y \
	app-editors/nano \
	app-editors/neovim \
	app-misc/tmux \
	app-portage/eix \
	app-portage/gentoolkit \
	app-portage/nattka \
	app-portage/tatt \
	app-shells/zsh \
	app-shells/zsh-completions \
	app-shells/zsh-syntax-highlighting \
	app-shells/gentoo-zsh-completions \
	app-text/tree \
	dev-build/cmake \
	dev-build/meson \
	dev-build/ninja \
	dev-debug/strace \
	dev-lang/go \
	dev-lang/rust-bin \
	dev-util/checkbashisms \
	dev-util/pkgdev \
	dev-util/pkgcheck \
	dev-vcs/git \
	net-misc/curl \
	sys-apps/ripgrep \
	sys-devel/clang ${ADDITIONAL_PKGS}
_do emerge -c
_do eix-update

##
# prepare neovim
# install other plugins
# comment out for security reasons
#_do timeout 10m nvim --headless +PlugInstall +qa || \
#	echo "Error when installing the nvim plugins!" >&2
# bash-language-server is not included in the ::gentoo repo
#_do npm i -g bash-language-server
