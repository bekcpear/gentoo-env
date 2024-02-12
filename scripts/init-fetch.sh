#!/bin/bash
#
# @author: Ryan Tsien <i@bitbili.net>
#

set -e
source "$(dirname "$0")/init-common.sh"

_do mkdir -p "$BUILD_DIR"
_do pushd "$BUILD_DIR"

TMP_GIT_VER=2.43.0

fetch() {
	local url="$2" file="$1" ret=1 tries=3
	while (( ret != 0 && tries > 0 )); do
		set +e
		_do wget --tries=5 --timeout=20 -O "$file" "$url"
		ret=$?
		set -e
		tries=$((tries - 1))
	done
	return $ret
}
##
# prepare external resources
fetch zsh-autosuggestions.tar.gz \
	https://github.com/zsh-users/zsh-autosuggestions/archive/refs/tags/v0.7.0.tar.gz
fetch vim-plug.vim \
	https://github.com/junegunn/vim-plug/raw/034e8445908e828351da6e428022d8487c57ce99/plug.vim
fetch modified_molokai.vim \
	https://gist.github.com/bekcpear/6752d661a3fbac5c8344d465c4089a6c/raw/4da3187a94046ed3981fd7adb7a7591e2ced2748/modified_molokai.vim
fetch coc.vim \
	https://github.com/bekcpear/dotfiles_of_gentoo_linux/raw/ecf22a8110a2e674f2013d526f7cdca223b0e167/ryan-misc/dot-config/nvim/coc.vim
fetch gpg.conf \
	https://gist.github.com/bekcpear/ea30609b36c416b5c0900b73b1525d80/raw/69fb89178ed5f92473301a9cb304aa0cbd1ae14b/gpg.conf
if [[ $PLATFORM == linux/riscv64 ]]; then
	fetch rclone-riscv64.zst https://binaries.gentoo.storage.oss.ac/rclone-riscv64.zst
	fetch git-v${TMP_GIT_VER}-usr-bin-rv64-lp64d.tar.zst https://binaries.gentoo.storage.oss.ac/git-v${TMP_GIT_VER}-usr-bin-rv64-lp64d.tar.zst
	_do sed -i "/git-${TMP_GIT_VER}.tar.gz/d" "${ROOT_DIR}/_x_configures/checksum.txt"
else
	fetch git-${TMP_GIT_VER}.tar.gz https://github.com/git/git/archive/refs/tags/v${TMP_GIT_VER}.tar.gz
	_do sed -i "/git-v${TMP_GIT_VER}-usr-bin-rv64-lp64d.tar.zst/d" "${ROOT_DIR}/_x_configures/checksum.txt"
	_do sed -i "/rclone-riscv64.zst/d" "${ROOT_DIR}/_x_configures/checksum.txt"
fi
_do cp "${ROOT_DIR}/_x_configures/checksum.txt" ./checksum.txt
_do sha256sum -c ./checksum.txt || \
	{ echo "Error: sha256sum does not match!" >&2; exit 1; }

##
# prepare git
if [[ $PLATFORM == linux/riscv64 ]]; then
	_do tar -xf git-v${TMP_GIT_VER}-usr-bin-rv64-lp64d.tar.zst
	_do mv git-${TMP_GIT_VER}-usr /tmp/usr
	_GIT="/tmp/usr/bin/git"
else
	_do tar -xf git-${TMP_GIT_VER}.tar.gz
	_do pushd git-${TMP_GIT_VER}
	_do make prefix="${BUILD_DIR}/_git" -j$NPROC
	_do make prefix="${BUILD_DIR}/_git" install
	_do popd
	_GIT="$(realpath _git/bin/git)"
fi

##
# prepare gpg
_do mkdir -m 700 -p ~/.gnupg
_do cp gpg.conf ~/.gnupg/gpg.conf
_do echo allow-preset-passphrase >~/.gnupg/gpg-agent.conf
_do gpg-connect-agent 'RELOADAGENT' '/bye'
_do gpg --version
_do gpg-agent --version

##
# prepare pub keys
_do gpg --keyserver hkps://keys.gentoo.org \
	--recv-keys EF9538C9E8E64311A52CDEDFA13D0EF1914E7A72
_do gpg --import "${ROOT_DIR}/_x_configures/0x1E100000FA95E6B5.pub"
if [[ $BUILD_BINPKGS == 1 ]] && [[ $BINPKGS_SIGNATURE == 1 ]]; then
	OSSCI_GPG_PUB_FILE="${ROOT_DIR}/_x_configures/0x5F8BF875DABC5698.pub"
	_do gpg --import "$OSSCI_GPG_PUB_FILE"
fi

##
# prepare repos
get_repos() {
	local name="$1" url="$2"
	_do cp "${ROOT_DIR}/_x_configures/${name}.conf" /etc/portage/repos.conf/
	_do "$_GIT" clone --depth 1 "$url" "/var/db/repos/${name}" || \
		{
			_do rm -rf "/var/db/repos/${name}"
			_do "$_GIT" clone --depth 1 "$url" "/var/db/repos/${name}"
		}
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

_do popd
