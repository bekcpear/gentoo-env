FROM gentoo/stage3:latest

ARG USE_BINPKG
ARG BUILD_BINPKGS
ARG PLATFORM

ENV USE_BINPKG=${USE_BINPKG:-true}
ENV BUILD_BINPKGS=${BUILD_BINPKGS:-false}
ENV PLATFORM=${PLATFORM:-unknown}

ADD configures/ _x_configures/
ADD scripts/init-common.sh _x_scripts/init-common.sh

ADD scripts/init-fetch.sh _x_scripts/init-fetch.sh
RUN _x_scripts/init-fetch.sh "$(pwd)"

ADD scripts/init-prepare.sh _x_scripts/init-prepare.sh
RUN --mount=type=secret,id=gpg_key,target=_x_gpg_key \
	--mount=type=secret,id=gpg_key_pp,target=_x_gpg_key_pp \
	--mount=type=secret,id=r2_key_id,target=_x_r2_key_id \
	--mount=type=secret,id=r2_access_key,target=_x_r2_access_key \
	--mount=type=secret,id=r2_endpoint,target=_x_r2_endpoint \
	_x_scripts/init-prepare.sh "$(pwd)"

ADD scripts/init-install.sh _x_scripts/init-install.sh
RUN _x_scripts/init-install.sh "$(pwd)"

ADD scripts/init-post.sh _x_scripts/init-post.sh
RUN _x_scripts/init-post.sh "$(pwd)"

ENV TERM="xterm-256color"
WORKDIR /root
CMD ["/bin/zsh", "-l"]
