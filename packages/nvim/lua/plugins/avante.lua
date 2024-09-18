-- this is meant to be the userland config for the avante
--
-- This will remain even after that PR lands
return {
  {
    "yetone/avante.nvim",
    optional = true,
    opts = {
      provider = "openai",
      openai = {
        api_key_name = { "op", "item", "get", "OpenAI - nvim Token", "--vault", "Rob (Work)", "--fields", "label=credential", "--reveal" },
      }
    }
  }
}
