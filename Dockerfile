FROM gentoo/stage3:latest

ARG USE_BINPKG=true

ADD scripts/ scripts/
ADD configures/ configures/
RUN scripts/init.sh "$(pwd)" ${USE_BINPKG}

ENV TERM="xterm-256color"
WORKDIR /root
CMD ["/bin/zsh", "-l"]
