-- Remembers the folder each terminal was created for, in a JSON file beside
-- init.lua. A function that writes returns true, or nil and a message.

local paths = require("projects.paths")

local M = {}

local function config_dir()
  local base = os.getenv("XDG_CONFIG_HOME")
  if base == nil or base == "" then
    base = paths.join(paths.home, ".config")
  end
  return paths.join(base, "rex")
end

local function file_path()
  return paths.join(config_dir(), "projects.json")
end

-- A missing or unreadable file means nothing is remembered.
local function read()
  local file = io.open(file_path(), "r")
  if file == nil then return {} end
  local text = file:read("*a")
  file:close()
  return (rex.json.decode(text) or {}).blocks or {}
end

local function write(blocks)
  local made, err = paths.mkdir(config_dir())
  if not made then return nil, err end

  local file, open_err = io.open(file_path(), "w")
  if file == nil then return nil, open_err end
  file:write(rex.json.encode({ blocks = blocks }, { indent = true }), "\n")
  file:close()
  return true
end

-- Returns a table from block ID to folder.
function M.blocks()
  return read()
end

function M.remember(block_id, dir)
  local blocks = read()
  blocks[block_id] = dir
  return write(blocks)
end

-- Forgets every block whose ID isn't a key of `alive`.
function M.keep_only(alive)
  local kept, dropped = {}, false
  for block_id, dir in pairs(read()) do
    if alive[block_id] then
      kept[block_id] = dir
    else
      dropped = true
    end
  end
  if not dropped then return true end
  return write(kept)
end

return M
