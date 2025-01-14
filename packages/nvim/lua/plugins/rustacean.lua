return {
  {
    "mrcjkb/rustaceanvim",
    -- These opts get merged into vim.g.rustaceanvim
    -- in ~/.local/share/nvim/lazy/LazyVim/lua/lazyvim/plugins/extras/lang/rust.lua
    opts = {
      ---@type rustaceanvim.lsp.ClientOpts
      server = {
        default_settings = {
          ['rust-analyzer'] = {
            diagnostics = {
              -- see <https://rust-analyzer.github.io/manual.html#diagnostics>
              disabled = { "proc-macro-disabled" }
            }
          }
        }
      }
    }
  },
}
