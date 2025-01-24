local rwjblue = require('rwjblue')

--- Copied from https://github.com/olimorris/codecompanion.nvim/blob/v11.13.1/lua/codecompanion/config.lua#L782-L811 originally and modified to support jujutsu
---
--- @module "rwjblue.codecompanion.types"
--- @type CodeCompanion.PromptEntry
return {
  name = "Generate a Commit Message",
  strategy = "chat",
  description = "Generate a commit message",
  opts = {
    index = 10,
    is_default = true,
    is_slash_cmd = true,
    short_name = "commit",
    auto_submit = true,
  },
  prompts = {
    {
      role = "user",
      content = function()
        return string.format(
          [[You are an expert at following the Conventional Commit specification. Given the git diff listed below, please generate a commit message for me:

```diff
%s
```
]],
          rwjblue.get_diff()
        )
      end,
      opts = {
        contains_code = true,
      },
    },
  },
}
