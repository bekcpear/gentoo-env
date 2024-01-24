FROM gentoo/stage3:latest

ARG USE_BINPKG=true

ADD scripts/ _x_scripts/
ADD configures/ _x_configures/

RUN _x_scripts/init-prepare.sh "$(pwd)"
RUN _x_scripts/init-install.sh "$(pwd)" ${USE_BINPKG}
RUN _x_scripts/init-post.sh "$(pwd)"

ENV TERM="xterm-256color"
WORKDIR /root
CMD ["/bin/zsh", "-l"]
