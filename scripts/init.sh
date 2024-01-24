#!/bin/bash
#
# @author: Ryan Tsien <i@bitbili.net>
#

set -e

ROOT_DIR="$(realpath "$(dirname "$0")/../")"
ROOT_DIR="${ROOT_DIR%/}"
BUILD_DIR="$(realpath "$1")"
BUILD_DIR="${BUILD_DIR%/}/_x_build"

USE_BINPKG="${2:-0}"

exec {ANOTHER_STDERR}>&2
_do() {
	set -- "$@"
	echo -e "\x1b[1;32m>>>\x1b[0m" "$@" >&$ANOTHER_STDERR || true
	"$@"
}

trap '
_do rm -rf /tmp/*
_do rm -rf "$BUILD_DIR"
_do rm -rf /var/log/emerge*
_do rm -rf /var/tmp/portage/*
_do rm -rf /var/cache/distfiles/*
_do rm -rf /var/db/repos/gentoo
' EXIT

_do mkdir -p "$BUILD_DIR"
_do pushd "$BUILD_DIR"

##
# prepare external resources
GIT_VER=2.43.0
_do wget -O zsh-autosuggestions.tar.gz \
	https://github.com/zsh-users/zsh-autosuggestions/archive/refs/tags/v0.7.0.tar.gz
_do wget -O vim-plug.vim \
	https://github.com/junegunn/vim-plug/raw/034e8445908e828351da6e428022d8487c57ce99/plug.vim
_do wget -O modified_molokai.vim \
	https://gist.github.com/bekcpear/6752d661a3fbac5c8344d465c4089a6c/raw/4da3187a94046ed3981fd7adb7a7591e2ced2748/modified_molokai.vim
_do wget -O coc.vim \
	https://github.com/bekcpear/dotfiles_of_gentoo_linux/raw/ecf22a8110a2e674f2013d526f7cdca223b0e167/ryan-misc/dot-config/nvim/coc.vim
_do wget -O git-${GIT_VER}.tar.gz https://github.com/git/git/archive/refs/tags/v${GIT_VER}.tar.gz
_do cp "${ROOT_DIR}/configures/checksum.txt" ./checksum.txt
_do sha256sum -c ./checksum.txt || \
	{ echo "Error: sha256sum does not match!" >&2; exit 1; }

##
# prepare git
_do tar -xf git-${GIT_VER}.tar.gz
_do pushd git-${GIT_VER}
_do make prefix="${BUILD_DIR}/_git" -j$(nproc)
_do make prefix="${BUILD_DIR}/_git" install
_do popd
_GIT="$(realpath _git/bin/git)"

## prepare pub keys
_do gpg --keyserver hkps://keys.gentoo.org \
	--recv-keys EF9538C9E8E64311A52CDEDFA13D0EF1914E7A72
_do gpg --import "${ROOT_DIR}/configures/0x1E100000FA95E6B5.pub"

##
# prepare repos
get_repos() {
	local name="$1" url="$2"
	_do cp "${ROOT_DIR}/configures/${name}.conf" /etc/portage/repos.conf/
	_do "$_GIT" clone --depth 1 "$url" "/var/db/repos/${name}"
	_do pushd "/var/db/repos/${name}"
	REPO_HEAD_COMMIT="$(_do "$_GIT" rev-list -n1 HEAD)"
	if ! _do "$_GIT" verify-commit --raw "$REPO_HEAD_COMMIT"; then
		_do "$_GIT" --no-pager log -1 --pretty=fuller "$REPO_HEAD_COMMIT" >&2
		echo "Error: verify ::${name} repo failed!" >&2
		exit 1
	fi
	_do popd
}
_do mkdir -p /etc/portage/repos.conf
get_repos gentoo "https://github.com/gentoo-mirror/gentoo"
get_repos ryans "https://github.com/bekcpear/ryans-repos"

##
# prepare env
append_portage_env() {
	local line="$1" file="/etc/portage/${2}" new_file_name="$3"
	if [[ ! -f "$file" ]]; then
		_do mkdir -p "$file"
		file="${file%/}/${new_file_name##*/}"
	fi
	_do echo "${line}" >>"$file"
}
ACCEPT_KEYWORDS="$(_do portageq envvar ACCEPT_KEYWORDS)"
if [[ ! $ACCEPT_KEYWORDS =~ ^~ ]]; then
	append_portage_env "ACCEPT_KEYWORDS=\"~$ACCEPT_KEYWORDS\"" \
		make.conf 0999-gentoo-env.conf
fi
append_portage_env "net-libs/nodejs corepack" package.use nodejs
append_portage_env "dev-lang/go::gentoo" package.mask golang

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
# install some tools
if [[ ${ACCEPT_KEYWORDS} =~ (amd64|arm64)([[:space:]]|$) ]]; then
	SHELLCHECK_PKG="dev-util/shellcheck-bin"
else
	SHELLCHECK_PKG="dev-util/shellcheck"
fi
_do emerge -ntvj $BINPKG_OPTS \
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
	sys-devel/clang \
	${SHELLCHECK_PKG}
_do emerge -c
_do eix-update
# ::gentoo repo has no zsh-autosuggestions yet
_do mkdir -p ~/.local/share
_do tar xf zsh-autosuggestions.tar.gz --directory ~/.local/share/
_do mv ~/.local/share/zsh-autosuggestions-* ~/.local/share/zsh-autosuggestions

##
# prepare neovim
_do mkdir -p ~/.cache/nvim/backup
_do mkdir -p ~/.config/nvim/colors/
_do mkdir -p ~/.config/nvim/lua/
_do mkdir -p ~/.local/share/nvim/site/autoload/
_do cp "${ROOT_DIR}/configures/init.vim" ~/.config/nvim/
_do cp coc.vim ~/.config/nvim/
_do cp "${ROOT_DIR}/configures/coc-settings.json" ~/.config/nvim/
_do cp "${ROOT_DIR}/configures/init.lua" ~/.config/nvim/lua/
# install vim-plug for neovim
_do cp vim-plug.vim ~/.local/share/nvim/site/autoload/plug.vim
# color theme
_do cp modified_molokai.vim ~/.config/nvim/colors/modified_molokai.vim
# install other plugins
# comment out for security reasons
#_do timeout 10m nvim --headless +PlugInstall +qa || \
#	echo "Error when installing the nvim plugins!" >&2
# bash-language-server is not included in the ::gentoo repo
#_do npm i -g bash-language-server

##
# prepare tmux
_do cp "${ROOT_DIR}/configures/tmux.conf" /etc/tmux.conf

##
# prepare zsh
_do cp "${ROOT_DIR}/configures/dot-zshrc" ~/.zshrc
_do usermod -s /bin/zsh root
