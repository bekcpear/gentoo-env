echo -e '
\x1b[1;33mThe following message only shows once!\x1b[0m

1. neovim is already configured with some plugins (see ~/.config/nvim/init.vim
   for details), you can install them through the following commands (these two
   commands download contents from the internet, so make sure your computer is
   in a secure network environment):
       nvim --headless +PlugInstall +qa
       npm i -g bash-language-server
2. `vim` is an alias of `nvim`
3. `ls` is an alias of `ls --color=auto`

'

sed -i '/first-time-hint-8c7904da376d/d' ~/.zshrc
rm -f ~/first-time-hint-8c7904da376d.sh
