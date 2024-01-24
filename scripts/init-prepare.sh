#!/bin/bash
#
# @author: Ryan Tsien <i@bitbili.net>
#

set -e
source "$(dirname "$0")/init-common.sh"

_do mkdir -p "$BUILD_DIR"
_do pushd "$BUILD_DIR"

GIT_VER=2.43.0

trap '
_do rm -rf "${BUILD_DIR}"
_do rm -rf _x_configures
' EXIT

##
# prepare external resources
_do wget -O zsh-autosuggestions.tar.gz \
	https://github.com/zsh-users/zsh-autosuggestions/archive/refs/tags/v0.7.0.tar.gz
_do wget -O vim-plug.vim \
	https://github.com/junegunn/vim-plug/raw/034e8445908e828351da6e428022d8487c57ce99/plug.vim
_do wget -O modified_molokai.vim \
	https://gist.github.com/bekcpear/6752d661a3fbac5c8344d465c4089a6c/raw/4da3187a94046ed3981fd7adb7a7591e2ced2748/modified_molokai.vim
_do wget -O coc.vim \
	https://github.com/bekcpear/dotfiles_of_gentoo_linux/raw/ecf22a8110a2e674f2013d526f7cdca223b0e167/ryan-misc/dot-config/nvim/coc.vim
_do wget -O git-${GIT_VER}.tar.gz https://github.com/git/git/archive/refs/tags/v${GIT_VER}.tar.gz
_do cp "${ROOT_DIR}/_x_configures/checksum.txt" ./checksum.txt
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
_do gpg --import "${ROOT_DIR}/_x_configures/0x1E100000FA95E6B5.pub"

##
# prepare repos
get_repos() {
	local name="$1" url="$2"
	_do cp "${ROOT_DIR}/_x_configures/${name}.conf" /etc/portage/repos.conf/
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
ACCEPT_KEYWORDS="$(_do portageq envvar ACCEPT_KEYWORDS)"
if [[ ! $ACCEPT_KEYWORDS =~ ^~ ]]; then
	append_portage_env "ACCEPT_KEYWORDS=\"~$ACCEPT_KEYWORDS\"" \
		make.conf 0999-gentoo-env.conf
fi
append_portage_env "net-libs/nodejs corepack" package.use nodejs
append_portage_env "dev-lang/go::gentoo" package.mask golang

##
# prepare neovim
_do mkdir -p ~/.cache/nvim/backup
_do mkdir -p ~/.config/nvim/colors/
_do mkdir -p ~/.config/nvim/lua/
_do mkdir -p ~/.local/share/nvim/site/autoload/
_do cp "${ROOT_DIR}/_x_configures/init.vim" ~/.config/nvim/
_do cp coc.vim ~/.config/nvim/
_do cp "${ROOT_DIR}/_x_configures/coc-settings.json" ~/.config/nvim/
_do cp "${ROOT_DIR}/_x_configures/init.lua" ~/.config/nvim/lua/
# install vim-plug for neovim
_do cp vim-plug.vim ~/.local/share/nvim/site/autoload/plug.vim
# color theme
_do cp modified_molokai.vim ~/.config/nvim/colors/modified_molokai.vim

##
# prepare tmux
_do cp "${ROOT_DIR}/_x_configures/tmux.conf" /etc/tmux.conf

##
# prepare zsh
_do cp "${ROOT_DIR}/_x_configures/dot-zshrc" ~/.zshrc
# ::gentoo repo has no zsh-autosuggestions yet
_do mkdir -p ~/.local/share
_do tar xf zsh-autosuggestions.tar.gz --directory ~/.local/share/
_do mv ~/.local/share/zsh-autosuggestions-* ~/.local/share/zsh-autosuggestions

_do popd
