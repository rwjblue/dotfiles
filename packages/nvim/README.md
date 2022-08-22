Basic Info
==========

This is my personal Vim setup.  It has and will continue to grow over time.
I have tried to keep the number of external bundles down (there are still quite
a few). I am using Plug to manage all of the external dependencies which works
well for me.

This configuration assumes that you are using neovim.

Installation
============

This is pretty easy to install.  All you should need is a recent NeoVim, git,
and the following commands:

    # rm -rf ~/.config/nvim # (only if you want to override current setup)
    mkdir -p ~/.config/
    git clone git://github.com/rwjblue/dotvim.git ~/.config/nvim
    nvim --headless -u NONE -c 'lua require("rwjblue.plugins").bootstrap()'

Upgrading
=========

Upgrading is also very simple.

To update the configuration itself you just need to pull the latest commits:

    cd ~/.config/nvim
    git pull origin master

To update the version of the underlying plugins run the following commands:

    cd ~/.config/nvim
    nvim -c 'lua require("rwjblue.plugins").update()'

Rollback
========

If, after an update, you determine that you would like to rollback to a prior
checkout of plugins you would do the following:

    cd ~/.config/nvim
    nvim --headless -c 'lua require("rwjblue.plugins").rollback()'

New Plugins
===========

When you want to add a new plugin (leaving the rest of the plugins at their
existing versions), add it to the `packer.startup` section of
`lua/rwjblue/plugins.lua` then run:

    cd ~/.config/nvim
    nvim --headless -c 'lua require("rwjblue.plugins").install()'
