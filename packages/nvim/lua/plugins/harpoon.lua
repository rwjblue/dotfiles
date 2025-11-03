-- Harpoon 2: Quick file navigation
-- https://github.com/ThePrimeagen/harpoon/tree/harpoon2
return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "folke/snacks.nvim",
  },
  opts = {
    settings = {
      save_on_toggle = true,
      sync_on_ui_close = true,
      save_on_change = true,
      key = function()
        -- Use git remote URL to share marks across worktrees
        local git_remote = vim.fn.systemlist("git config --get remote.origin.url")[1]
        
        if git_remote and vim.v.shell_error == 0 then
          return git_remote
        end
        
        -- Fall back to cwd if not in a git repo
        return vim.uv.cwd()
      end,
    },
  },
  keys = {
    {
      -- Add current file to harpoon
      "<leader>ha",
      function()
        require("harpoon"):list():add()
        vim.notify("Added to Harpoon", vim.log.levels.INFO)
      end,
      desc = "Harpoon: Add file",
    },
    {
      -- Open snacks picker with harpoon files
      "<leader>hh",
      function()
        local harpoon = require("harpoon")
        local harpoon_files = harpoon:list()
        local items = {}

        for idx, item in ipairs(harpoon_files.items) do
          table.insert(items, {
            text = item.value,
            file = item.value,
            idx = idx,
          })
        end

        Snacks.picker.pick({
          items = items,
          format = "file",
          title = "Harpoon Files",
          preview = "file",
          show_empty = true,
        })
      end,
      desc = "Harpoon: Search files",
    },
    {
      -- Remove current file from harpoon
      "<leader>hr",
      function()
        require("harpoon"):list():remove()
        vim.notify("Removed from Harpoon", vim.log.levels.INFO)
      end,
      desc = "Harpoon: Remove file",
    },
  },
}
