-- this is meant to be the userland config for the avante
--
-- This will remain even after that PR lands
return {
  {
    "yetone/avante.nvim",
    optional = true,
    opts = {
      provider = "claude",
      openai = {
        -- api_key_name = { "op", "item", "get", "OpenAI - nvim Token", "--vault", "Rob (Work)", "--fields", "label=credential", "--reveal" },
      },
      claude = {
        -- NOTE: this would be better, but it's a bit annoying at the moment
        -- since Avante.nvim is eagerly ran the 1password prompt happens on
        -- every launch of neovim
        --
        -- api_key_name = { "op", "item", "get", "Claude - nvim Token", "--vault", "Rob (Work)", "--fields", "label=credential", "--reveal" },
        api_key_name = "AI_CLAUDE_API_KEY",
      }
    }
  }
}
