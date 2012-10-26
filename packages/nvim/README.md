Basic Info
==========

This is my personal Vim setup.  It has and will continue to grow over time.
I have tried to keep the number of external bundles down (there are still quite
a few). I am using pathogen and git submodules to manage all of the external
dependencies which works fairly well for me.

Installation
============

This is pretty easy to install.  All you should need is a recent Vim and git
and the following commands:

    # rm -rf ~/.vim ~/.vimrc ~/.gvimrc # (only if you want to override current setup)
    git clone git://github.com/rjackson/dotvim.git ~/.vim
    git submodule update --init
    ln -s ~/.vim/vimrc ~/.vimrc
    ln -s ~/.vim/gvimrc ~/.gvimrc

Upgrading
=========

Upgrading is very similar to installation, and is mostly handled by git itself:

  git pull origin master
  git submodule update --init
  git submodule foreach 'git clean -xfd -- . && git pull origin master'
