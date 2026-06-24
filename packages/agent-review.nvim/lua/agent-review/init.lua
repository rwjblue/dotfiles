local M = {}

M.config = {
  keymap_prefix = "<leader>r",
}

local function setup_commands()
  local ui = require("agent-review.ui")
  local render = require("agent-review.render")
  local store = require("agent-review.store")

  vim.api.nvim_create_user_command("AgentReviewAdd", function(o)
    if o.range > 0 then ui.add_visual() else ui.add() end
  end, { range = true, desc = "Add a review comment" })
  vim.api.nvim_create_user_command("AgentReviewEdit", ui.edit, { desc = "Edit comment under cursor" })
  vim.api.nvim_create_user_command("AgentReviewDelete", ui.delete, { desc = "Delete comment under cursor" })
  vim.api.nvim_create_user_command("AgentReviewList", ui.list, { desc = "List review comments" })
  vim.api.nvim_create_user_command("AgentReviewReload", function() render.buffer(0) end, { desc = "Re-render comments" })
  vim.api.nvim_create_user_command("AgentReviewClear", function()
    local root = store.repo_root()
    if root then store.clear(root); render.buffer(0) end
  end, { desc = "Clear the active review batch" })
end

local function setup_keymaps()
  local p = M.config.keymap_prefix
  local ui = require("agent-review.ui")
  vim.keymap.set("n", p .. "c", ui.add, { desc = "Review: add comment" })
  vim.keymap.set("x", p .. "c", ui.add_visual, { desc = "Review: add comment (range)" })
  vim.keymap.set("n", p .. "e", ui.edit, { desc = "Review: edit comment" })
  vim.keymap.set("n", p .. "d", ui.delete, { desc = "Review: delete comment" })
  vim.keymap.set("n", p .. "l", ui.list, { desc = "Review: list comments" })
  vim.keymap.set("n", p .. "r", function() require("agent-review.render").buffer(0) end, { desc = "Review: reload" })
  vim.keymap.set("n", "]r", ui.next, { desc = "Review: next comment" })
  vim.keymap.set("n", "[r", ui.prev, { desc = "Review: prev comment" })
end

local function setup_autocmds()
  local group = vim.api.nvim_create_augroup("agent_review_render", { clear = true })
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
    group = group,
    callback = function(ev) require("agent-review.render").buffer(ev.buf) end,
  })
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  setup_commands()
  setup_keymaps()
  setup_autocmds()
end

return M
