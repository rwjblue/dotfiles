---@alias CodeCompanion.Role "user"|"system"|"llm"
---@alias CodeCompanion.Strategy "inline"|"workflow"|"chat"
---@alias CodeCompanion.Mode "v"|"n"|"i"

---@class CodeCompanion.PromptOpts
---@field visible? boolean
---@field tag? string
---@field auto_submit? boolean
---@field contains_code? boolean

---@class CodeCompanion.EntryOpts
---@field index number
---@field is_default? boolean
---@field is_slash_cmd? boolean
---@field user_prompt? boolean
---@field short_name? string
---@field modes? CodeCompanion.Mode[]
---@field auto_submit? boolean
---@field stop_context_insertion? boolean

---@class CodeCompanion.Context
---@field filetype string
---@field bufnr number
---@field start_line number
---@field end_line number
---@field cursor_pos number[]
---@field is_visual boolean

---@class CodeCompanion.Prompt
---@field role CodeCompanion.Role
---@field content string|fun(context: CodeCompanion.Context):string
---@field opts? CodeCompanion.PromptOpts
---@field condition? fun(context: CodeCompanion.Context):boolean

---@class CodeCompanion.PromptEntry
---@field strategy CodeCompanion.Strategy
---@field description string
---@field opts CodeCompanion.EntryOpts
---@field prompts (CodeCompanion.Prompt|CodeCompanion.Prompt[])[]

---@class CodeCompanion.PromptLibrary
---@field [string] CodeCompanion.PromptEntry
