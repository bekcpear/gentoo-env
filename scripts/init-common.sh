#!/bin/bash
#
# @author: Ryan Tsien <i@bitbili.net>
#

if [[ $PLATFORM == unknown ]]; then
	echo "unknown platform!" >&2
	exit 1
fi

ROOT_DIR="$(realpath "$(dirname "$0")/../")"
ROOT_DIR="${ROOT_DIR%/}"
BUILD_DIR="$(realpath "$1")"
BUILD_DIR="${BUILD_DIR%/}/_x_build"

NPROC="$(nproc)"
NLOAD=$(( NPROC - 1 ))
if (( NPROC < 2 )); then
	NLOAD=2
fi

USE_BINPKG="${USE_BINPKG:-0}"
if [[ ! $USE_BINPKG =~ ^0|[fF][aA][lL][sS][eE]$ ]]; then
	USE_BINPKG=1
fi
BUILD_BINPKGS="${BUILD_BINPKGS:-0}"
if [[ ! $BUILD_BINPKGS =~ ^0|[fF][aA][lL][sS][eE]$ ]]; then
	BUILD_BINPKGS=1
fi
##
# TODO: #1
# portage error:
#   [Errno 25] Inappropriate ioctl for device
#   >>> Unlocking GPG...
#   gpg: signing failed: Inappropriate ioctl for device
#   gpg: signing failed: Inappropriate ioctl for device
#   !!! GPG unlock failed
# seems docker does not has a tty when building image.
# so, for now, don't make signature for built binpkgs,
# but always check the signature for official binpkgs.
BINPKGS_SIGNATURE=0
if [[ $BUILD_BINPKGS != 1 ]]; then
	BINPKGS_SIGNATURE=1
fi

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
	if [[ "$line" =~ ^/ ]]; then
		if [[ -f "$line" ]]; then
			_do echo $'\n'"# ${line}" >>"$file"
			_do cat "${line}" >>"$file"
		else
			echo "Error: missing file '$line'." >&2
			return 1
		fi
	else
		_do echo "${line}" >>"$file"
	fi
}
