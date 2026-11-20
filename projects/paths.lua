-- Filesystem helpers. Rex has no filesystem API, so these run commands.
-- A function that can fail returns nil and a message.

local M = {}

M.home = os.getenv("HOME") or "/"

function M.join(dir, name)
  if dir == "/" then return "/" .. name end
  return dir .. "/" .. name
end

function M.basename(path)
  return path:match("([^/]+)/*$") or path
end

-- Returns the folder that holds `dir`, or nil for the top of the filesystem.
function M.parent(dir)
  local parent = dir:match("^(.*)/[^/]+$")
  if parent == nil then return nil end
  return parent == "" and "/" or parent
end

-- Returns `path` the way a person writes it, with the home folder as `~`.
function M.display(path)
  if path == M.home then return "~" end
  if path:sub(1, #M.home + 1) == M.home .. "/" then return "~" .. path:sub(#M.home + 1) end
  return path
end

function M.trim(text)
  return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function expand_home(path)
  if path == "~" then return M.home end
  if path:sub(1, 2) == "~/" then return M.home .. path:sub(2) end
  return path
end

-- Runs a command and returns what it printed.
local function run(argv, opts)
  local result, err = rex.exec(argv, opts)
  if result == nil then return nil, err end
  if not result.ok then return nil, M.trim(result.stderr) end
  return result.stdout
end

-- Returns the absolute path of an existing folder, with `~` expanded and
-- links followed. A relative path is refused, because it would be relative to
-- wherever the Rex server happens to run.
function M.resolve(path)
  path = expand_home(M.trim(path))
  if path:sub(1, 1) ~= "/" then return nil, "Not an absolute path: " .. path end

  local real = run({ "pwd", "-P" }, { cwd = path })
  if real == nil then return nil, "Not a folder: " .. path end
  return M.trim(real)
end

-- Returns the names of the visible folders in `dir`, sorted.
function M.folders(dir)
  local listing, err = run({ "ls", "-1p", dir })
  if listing == nil then return nil, err end

  local names = {}
  for name in listing:gmatch("([^\n]+)/\n") do
    names[#names + 1] = name
  end
  return names
end

-- Creates `dir` and any missing parents.
function M.mkdir(dir)
  local created, err = run({ "mkdir", "-p", dir })
  if created == nil then return nil, err end
  return true
end

return M
