#!/bin/bash
#

set -e

INPUTS="$1"
FILE="$(realpath "$0")"
FILE="$(dirname "${FILE}")/../target-platforms.txt"

declare -a PLATFORMS VALID_PLATFORMS
mapfile -t PLATFORMS <"$FILE"

if [[ "$INPUTS" =~ ^[[:space:]]*$ ]]; then
	VALID_PLATFORMS=( "${PLATFORMS[@]}" )
else
	IFS="," read -r -a _PLATFORMS <<< "$INPUTS"
	for _platform in "${_PLATFORMS[@]}"; do
		_exists=0
		for platform in "${PLATFORMS[@]}"; do
			if [[ $platform == "$_platform" ]]; then
				_exists=1
				break
			fi
		done
		if [[ $_exists == 0 ]]; then
			echo "non existing platform '$_platform', ignore it." >&2
		else
			VALID_PLATFORMS+=( "$_platform" )
		fi
	done
fi

if [[ ${#VALID_PLATFORMS[@]} == 0 ]]; then
	echo "no valid platform!" >&2
	exit 1
fi

VALID_PLATFORMS_JSON="["
for valid_platform in "${VALID_PLATFORMS[@]}"; do
	VALID_PLATFORMS_JSON+="\"${valid_platform}\","
done
VALID_PLATFORMS_JSON="${VALID_PLATFORMS_JSON%,}]"

echo "matrix={\"target\":${VALID_PLATFORMS_JSON}}" >> $GITHUB_OUTPUT
