return {
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "black",
        "shellcheck",
        "shfmt",
        "flake8",
        "isort",
        "stylua",
        "typescript-language-server",
      },
    },
  },
}
