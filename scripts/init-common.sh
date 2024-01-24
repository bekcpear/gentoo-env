#!/bin/bash
#
# @author: Ryan Tsien <i@bitbili.net>
#

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

append_portage_env() {
	local line="$1" file="/etc/portage/${2}" new_file_name="$3"
	if [[ ! -f "$file" ]]; then
		_do mkdir -p "$file"
		file="${file%/}/${new_file_name##*/}"
	fi
	_do echo "${line}" >>"$file"
}
