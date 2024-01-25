#!/bin/bash
#

set -e

INPUTS="$1"
EVENT_NAME="$2"
FILE="$(realpath "$0")"
FILE="$(dirname "${FILE}")/../target-platforms.txt"

declare -a PLATFORMS VALID_PLATFORMS
mapfile -t PLATFORMS <"$FILE"

parse_commit_title() {
	if [[ "${EVENT_NAME}" != "push" ]]; then
		return
	fi

	local title
	title="$(git log -1 --pretty=format:"%s")"
	if [[ ! $title =~ \[target:[[:space:]]([^\]]+)\] ]]; then
		return
	fi
	INPUTS="${BASH_REMATCH[1]}"
}
parse_commit_title

if [[ "$INPUTS" =~ ^[[:space:]]*$ ]]; then
	VALID_PLATFORMS=( "${PLATFORMS[@]}" )
else
	IFS="," read -r -a _PLATFORMS <<< "$INPUTS"
	for _platform in "${_PLATFORMS[@]}"; do
		_exists=0
		for platform in "${PLATFORMS[@]}"; do
			if [[ ${platform%%:*} == "$_platform" ]]; then
				_exists=1
				VALID_PLATFORMS+=( "$platform" )
				break
			fi
		done
		if [[ $_exists == 0 ]]; then
			echo "non existing platform '$_platform', ignore it." >&2
		fi
	done
fi

if [[ ${#VALID_PLATFORMS[@]} == 0 ]]; then
	echo "no valid platform!" >&2
	exit 1
fi

_default_runson="\"ubuntu-latest\""
VALID_PLATFORMS_JSON="["
for valid_platform in "${VALID_PLATFORMS[@]}"; do
	VALID_PLATFORMS_JSON+="{\"target\":"
	VALID_PLATFORMS_JSON+="\"${valid_platform%%:*}\","
	_new_runson="${valid_platform##*:}"
	VALID_PLATFORMS_JSON+="\"runson\":${_new_runson:-${_default_runson}}},"
done
VALID_PLATFORMS_JSON="${VALID_PLATFORMS_JSON%,}]"

echo "matrix={\"include\":${VALID_PLATFORMS_JSON}}" >> $GITHUB_OUTPUT
