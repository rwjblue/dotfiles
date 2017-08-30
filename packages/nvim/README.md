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

    # rm -rf ~/.config/nvim # (only if you want to override current setup)
    mkdir -p ~/.config/
    git clone git://github.com/rjackson/dotvim.git ~/.config/nvim
    git submodule update --init

Upgrading
=========

Upgrading is very similar to installation, and is mostly handled by git itself:

    git pull origin master
    git submodule update --init
    git submodule foreach 'git clean -xfd -- . && git pull origin master'
