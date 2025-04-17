local function get_file_list(path)
  local handle = io.popen('find "' .. path .. '" -type f | sort')
  local result = handle:read("*a")
  handle:close()

  local files = {}
  for file in result:gmatch("[^\n]+") do
    table.insert(files, file)
  end
  return files
end

local SERVER_FILES = {
  server = {
    "server/server.go",
    "server/hooks.go",
    "server/sse.go",
  },
}

local function get_repo_path()
  return os.getenv("HOME") .. "/github/mark3labs/mcp-go"
end

local function read_file(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end
  local content = file:read("*a")
  file:close()
  return content
end

return {
  name = "mcp-go",
  displayName = "MCP Go Repository",
  capabilities = {
    tools = {
      {
        name = "list_files",
        description = "List all files in the mcp-go repository",
        handler = function(req, res)
          local repo_path = get_repo_path()
          local files = get_file_list(repo_path)
          return res:text(table.concat(files, "\n")):send()
        end,
      },
      {
        name = "read_repo_file",
        description = "Read contents of a file from the mcp-go repository",
        inputSchema = {
          type = "object",
          properties = {
            file_path = {
              type = "string",
              description = "Relative path to the file in the repository",
            },
          },
          required = { "file_path" },
        },
        handler = function(req, res)
          local repo_path = get_repo_path()
          local full_path = repo_path .. "/" .. req.params.file_path

          local content = read_file(full_path)
          if not content then
            return res:error("Could not read file: " .. full_path)
          end

          return res:text(content):send()
        end,
      },
    },
    resources = {
      {
        name = "repo_info",
        uri = "mcp-go://info",
        description = "Information about the mcp-go repository",
        handler = function(req, res)
          local repo_path = get_repo_path()
          local info = "MCP Go Repository\n"
          info = info .. "Path: " .. repo_path .. "\n"

          -- Get file count
          local files = get_file_list(repo_path)
          info = info .. "Total files: " .. #files .. "\n"

          return res:text(info):send()
        end,
      },
      {

        name = "server_files",
        uri = "mcp-go://server",
        description = "All server files in the mcp-go repository",
        handler = function(req, res)
          local output = ""
          local repo_path = get_repo_path()

          for _, file_path in ipairs(SERVER_FILES.server) do
            local full_path = repo_path .. "/" .. file_path
            local content = read_file(full_path)
            if not content then
              return res:error("Could not read file: " .. file_path)
            end

            output = output .. "--- " .. file_path .. " ---\n\n"
            output = output .. content .. "\n\n"
          end

          return res:text(output, "text/x-go"):send()
        end,
      },
    },
    resourceTemplates = {
      {
        name = "file_content",
        uriTemplate = "mcp-go://file/{file_path}",
        description = "Get content of a specific file in the repository",
        handler = function(req, res)
          local repo_path = os.getenv("HOME") .. "/github/mark3labs/mcp-go"
          local file_path = req.params.file_path
          local full_path = repo_path .. "/" .. file_path

          local file = io.open(full_path, "r")
          if not file then
            return res:error("File not found: " .. file_path)
          end

          local content = file:read("*a")
          file:close()

          -- Determine mime type based on file extension
          local mime_type = "text/plain"
          if file_path:match("%.go$") then
            mime_type = "text/x-go"
          elseif file_path:match("%.md$") then
            mime_type = "text/markdown"
          elseif file_path:match("%.json$") then
            mime_type = "application/json"
          elseif file_path:match("%.ya?ml$") then
            mime_type = "application/yaml"
          end

          return res:text(content, mime_type):send()
        end,
      },
    },
  },
}
