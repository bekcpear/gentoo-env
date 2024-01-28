#!/bin/bash
#
# @author: Ryan Tsien <i@bitbili.net>
#

set -e
source "$(dirname "$0")/init-common.sh"

_do pushd "$BUILD_DIR"

if [[ $BUILD_BINPKGS == 1 ]] && [[ $BINPKGS_SIGNATURE == 1 ]]; then
	OSSCI_GPG_KEY_FILE="${ROOT_DIR}/_x_gpg_key"
	if [[ ! -f "$OSSCI_GPG_KEY_FILE" ]]; then
		echo "GPG key file does not exists" >&2
		exit 1
	fi
	OSSCI_GPG_PASSPHRASE="$(cat "${ROOT_DIR}/_x_gpg_key_pp")"
fi
if [[ $BUILD_BINPKGS == 1 ]]; then
	R2_KEY_ID="$(cat "${ROOT_DIR}/_x_r2_key_id")"
	R2_ACCESS_KEY="$(cat "${ROOT_DIR}/_x_r2_access_key")"
	R2_ENDPOINT="$(cat "${ROOT_DIR}/_x_r2_endpoint")"
fi

trap '
_do rm -rf "${BUILD_DIR}"
_do rm -rf _x_configures
' EXIT

##
# prepare env
STABLE_ACCEPT_KEYWORD=""
declare -a ACCEPT_KEYWORDS_A
read -r -a ACCEPT_KEYWORDS_A < <(_do portageq envvar ACCEPT_KEYWORDS)
for ACCEPT_KEYWORD in "${ACCEPT_KEYWORDS_A[@]}"; do
	if [[ $ACCEPT_KEYWORD =~ ^~ ]]; then
		TESTING_ACCEPT_KEYWORDS="${ACCEPT_KEYWORD}"
	fi
	STABLE_ACCEPT_KEYWORD="${ACCEPT_KEYWORD#'~'}"
done
if [[ -z $TESTING_ACCEPT_KEYWORDS ]]; then
	append_portage_env "ACCEPT_KEYWORDS=\"${ACCEPT_KEYWORDS_A[*]} ~$STABLE_ACCEPT_KEYWORD\"" \
		make.conf 0999-gentoo-env.conf
fi
append_portage_env "net-libs/nodejs corepack" package.use nodejs
append_portage_env "dev-lang/go::gentoo" package.mask golang
append_portage_env "MAKEOPTS=\"-j${NPROC}\"" \
	make.conf 0999-gentoo-env.conf

##
# prepare binpkgs releated
if [[ $BUILD_BINPKGS == 1 ]]; then
	append_portage_env "${ROOT_DIR}/_x_configures/binpkgs.make.conf.dir/common.conf" \
		make.conf 0899-gentoo-env-binpkgs.conf
	if [[ $BINPKGS_SIGNATURE == 1 ]]; then
		append_portage_env "${ROOT_DIR}/_x_configures/binpkgs.make.conf.dir/signature.conf" \
			make.conf 0899-gentoo-env-binpkgs.conf
	fi
	append_portage_env "${ROOT_DIR}/_x_configures/binpkgs.make.conf.dir/${STABLE_ACCEPT_KEYWORD}.conf" \
		make.conf 0899-gentoo-env-binpkgs.conf
	_do zstd -d "${BUILD_DIR}/rclone-riscv64.zst"
	_do mv "${BUILD_DIR}/rclone-riscv64" /rclone
	_do mkdir -p ~/.config/rclone/
	_do cp "${ROOT_DIR}/_x_configures/rclone.conf" ~/.config/rclone/rclone.conf

	# force set +x here to prevent leaking sensitive info
	_OLD_XTRACE="$(set +o | grep xtrace)"
	set +x
	sed -i "s#@@R2_KEY_ID@@#${R2_KEY_ID}#" ~/.config/rclone/rclone.conf
	sed -i "s#@@R2_ACCESS_KEY@@#${R2_ACCESS_KEY}#" ~/.config/rclone/rclone.conf
	sed -i "s#@@R2_ENDPOINT@@#${R2_ENDPOINT}#" ~/.config/rclone/rclone.conf
	if [[ $BINPKGS_SIGNATURE == 1 ]]; then
		# prepare gpg signature
		gpg --batch --import <"$OSSCI_GPG_KEY_FILE"
		HEXPP=$(echo -n "$OSSCI_GPG_PASSPHRASE" | od -An -w100 -t x1 | sed 's/\s//g')
		gpg-connect-agent "PRESET_PASSPHRASE 0322FA1F33708FD3922A5C3655380A38A7533AF9 -1 $HEXPP" '/bye'
	fi
	eval "$_OLD_XTRACE"
fi
if [[ $USE_BINPKG == 1 ]]; then
	if [[ $BINPKGS_SIGNATURE == 1 ]]; then
		append_portage_env "FEATURES=\"\${FEATURES} binpkg-request-signature\"" \
			make.conf 0999-gentoo-env.conf
	fi
	_do sed -Ei '/sync-uri = /s@https?://[^/]+/@https://distfiles.gentoo.org/@' \
		/etc/portage/binrepos.conf/*.conf
	_do rm -rf /etc/portage/gnupg
	_do getuto
	if [[ $BUILD_BINPKGS == 1 ]]; then
		# if no binpkgs prepared for this docker imaged,
		# use the customized binhost is meaningless
		_do sed -i "s#@@PLATFORM@@#${PLATFORM}#" "${ROOT_DIR}/_x_configures/ryansbinhost.conf"
		append_portage_env "${ROOT_DIR}/_x_configures/ryansbinhost.conf" \
			binrepos.conf ryansbinhost.conf
		if [[ $BINPKGS_SIGNATURE == 1 ]]; then
			_do gpg --homedir /etc/portage/gnupg --import "$OSSCI_GPG_PUB_FILE"
		fi
	fi
fi

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
