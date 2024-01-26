FROM gentoo/stage3:latest

ARG USE_BINPKG
ARG BUILD_BINPKGS
ENV USE_BINPKG=${USE_BINPKG:-true}
ENV BUILD_BINPKGS=${BUILD_BINPKGS:-true}

ADD scripts/ _x_scripts/
ADD configures/ _x_configures/

##
# TODO: #1
#RUN --mount=type=secret,id=gpg_key,target=_x_gpg_key \
#	--mount=type=secret,id=gpg_key_pp,target=_x_gpg_key_pp \
#	_x_scripts/init-prepare.sh "$(pwd)"
RUN _x_scripts/init-prepare.sh "$(pwd)"
RUN _x_scripts/init-install.sh "$(pwd)"
RUN _x_scripts/init-post.sh "$(pwd)"

ENV TERM="xterm-256color"
WORKDIR /root
CMD ["/bin/zsh", "-l"]
