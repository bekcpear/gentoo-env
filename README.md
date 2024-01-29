# A friendly Gentoo Linux docker environment

- based on the [gentoo/stage3:latest](https://hub.docker.com/r/gentoo/stage3) image
- images are built weekly for platforms:
  - linux/amd64
  - linux/arm64
  - linux/riscv64
- additional packages:
  - app-editors/neovim
  - app-misc/tmux
  - app-portage/eix
  - app-portage/gentoolkit
  - app-portage/nattka
  - app-portage/tatt
  - app-shells/zsh
  - app-shells/zsh-completions
  - app-shells/zsh-syntax-highlighting
  - app-shells/gentoo-zsh-completions
  - app-text/tree
  - dev-build/cmake
  - dev-build/meson
  - dev-build/ninja
  - dev-java/openjdk-bin (not available on riscv64)
  - dev-lang/go
  - dev-lang/rust-bin
  - dev-util/checkbashisms
  - dev-util/pkgdev
  - dev-util/pkgcheck
  - dev-vcs/git
  - net-libs/nodejs (temporarily disabled for riscv64)
  - net-misc/curl
  - sys-devel/clang
  - sys-app/fd (not available on riscv64)
  - sys-app/ripgrep
  - dev-util/shellcheck-bin (not available on riscv64)
  - *and all bdeps of above packages*
- default shell is **zsh**
  - with Vi editing mode
    (comment out line 10 and 11 of file `~/.zshrc` to back to Emacs editing mode)
  - alias `vim` to `nvim`
  - alias `ls` to `ls --color=auto`
- if you are using it in an interactive scenario, you can install the nvim plugin by executing the following command:
  ```bash
  nvim --headless +PlugInstall +qa
  ```
- something others
