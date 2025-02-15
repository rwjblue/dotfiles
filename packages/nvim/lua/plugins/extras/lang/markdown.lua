return {
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        -- Disable the use of markdownlint-cli2 configured in
        -- ~/.local/share/nvim/lazy/LazyVim/lua/lazyvim/plugins/extras/lang/markdown.lua
        --
        -- leave it as a formatter, but the linting is mostly wrong (i.e. it confuses formatting rules for linting)
        -- it also doesn't support $HOME/.markdownlint.json but requires a configuration per-directory
        markdown = {},
      },
    },
  },
}
