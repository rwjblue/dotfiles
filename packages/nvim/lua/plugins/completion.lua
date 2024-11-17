local use_blink = false;

return {
  {
    "saghen/blink.cmp",
    enabled = use_blink,
    opts = {
      -- experimental signature help support
      trigger = {
        signature_help = { enabled = true }
      }
    }
  },
  -- the following is merged with the default nvim-cmp config from:
  --   https://github.com/LazyVim/LazyVim/blob/v10.9.1/lua/lazyvim/plugins/coding.lua#L33-L105
  {
    "hrsh7th/nvim-cmp",
    enabled = not use_blink,
    dependencies = {
      "hrsh7th/cmp-emoji",
      "hrsh7th/cmp-nvim-lsp-signature-help",
    },
    opts = function(_, opts)
      vim.list_extend(opts.sources, {
        { name = "emoji" },
        { name = "nvim_lsp_signature_help" },
      })
    end,
  },
}
