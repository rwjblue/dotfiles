#!/usr/bin/env zsh

echo "installing neovim"
echo "initial nvim version"
nvim --version

mkdir -p $HOME/neovim/
cd $HOME/neovim/

curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
chmod u+x nvim.appimage

# no fuse support, so we have to extract manually
./nvim.appimage --appimage-extract
sudo rm /usr/local/bin/nvim
sudo ln -s $HOME/neovim/squashfs-root/AppRun /usr/local/bin/nvim

echo "installed nvim version"
nvim --version
