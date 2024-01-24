#!/bin/bash
#
# @author: Ryan Tsien <i@bitbili.net>
#

set -e
source "$(dirname "$0")/init-common.sh"

trap '
_do rm -rf /tmp/*
_do rm -rf /var/log/emerge*
_do rm -rf /var/tmp/portage/*
_do rm -rf /var/cache/distfiles/*
_do rm -rf /var/db/repos/gentoo
' EXIT

##
# binpkg?
BINPKG_OPTS=""
if [[ ! $USE_BINPKG =~ ^0|[fF][aA][lL][sS][eE]$ ]]; then
	append_portage_env "FEATURES=\"\${FEATURES} binpkg-request-signature\"" \
		make.conf 0999-gentoo-env.conf
	_do mv /etc/portage/gnupg /etc/portage/gnupg.bak || true
	_do getuto
	_do sed -Ei '/sync-uri = /s@https?://[^/]+/@https://distfiles.gentoo.org/@' \
		/etc/portage/binrepos.conf/*.conf
	BINPKG_OPTS+=" --getbinpkg"
fi

##
# install packages
ACCEPT_KEYWORDS="$(_do portageq envvar ACCEPT_KEYWORDS)"
if [[ ${ACCEPT_KEYWORDS} =~ (amd64|arm64)([[:space:]]|$) ]]; then
	# The shellcheck-bin pkg only available on amd64 and arm64,
	# to avoid introducing a ghc build, won't install shellcheck
	# on other platforms here.
	SHELLCHECK_PKG="dev-util/shellcheck-bin"
fi
_do emerge -ntvj -l$(nproc) $BINPKG_OPTS \
	--autounmask=y \
	--autounmask-license=y \
	--autounmask-write=y \
	--autounmask-continue=y \
	app-editors/nano \
	app-editors/neovim \
	app-misc/tmux \
	app-portage/eix \
	app-portage/gentoolkit \
	app-shells/zsh \
	app-shells/zsh-completions \
	app-shells/zsh-syntax-highlighting \
	app-shells/gentoo-zsh-completions \
	dev-lang/go \
	dev-lang/rust-bin \
	dev-util/checkbashisms \
	dev-util/pkgdev \
	dev-util/pkgcheck \
	dev-vcs/git \
	net-libs/nodejs \
	net-misc/curl \
	sys-devel/clang ${SHELLCHECK_PKG}
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
