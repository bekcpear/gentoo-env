#!/bin/bash
#

WD="$(realpath "$(dirname "$0")")"

container_name="gentoo-env-x"

_do() {
	set -- "$@"
	echo -e "\x1b[1;32m>>>\x1b[0m" "$@" >&2 || true
	"$@"
}

if podman container exists $container_name; then
	_do podman start -a $container_name
else
	_do podman run -it --tz local \
		-v "$WD"/init.sh:/root/__x_init.sh \
		-v "$WD"/.histfile:/root/.histfile \
		--name gentoo-env-x \
		"$@" \
		ghcr.io/bekcpear/gentoo-env:latest
fi
