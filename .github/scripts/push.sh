#!/bin/bash
#

set -e

FILE="$(realpath "$0")"
FILE="$(dirname "${FILE}")/../target-platforms.txt"
declare -a TAGS
mapfile -t TAGS <"$FILE"

_do() {
	set -- "$@"
	echo -e "\x1b[1;32m>>>\x1b[0m" "$@" >&2 || true
	"$@"
}

_do docker push --all-tags "$IMAGE_NAME"

# clean unused images every time finished
trap '
_do docker image prune -f
' EXIT

declare -a IMAGES
for tag in "${TAGS[@]}"; do
	tag="${tag%%:*}"
	tag="${tag##*/}"
	IMAGE="${IMAGE_NAME}:${tag}"
	#if _do docker manifest inspect "$IMAGE" >/dev/null; then
	IMAGES+=( "$IMAGE" )
	#fi
done

if (( ${#IMAGES[@]} > 0 )); then
	_do docker manifest rm "${IMAGE_NAME}:latest" || true
	_do docker manifest create "${IMAGE_NAME}:latest" "${IMAGES[@]}"
	_do docker manifest push "${IMAGE_NAME}:latest"
fi
