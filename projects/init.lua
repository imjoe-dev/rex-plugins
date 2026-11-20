-- Projects: browse the folders from where you are, then open one in a pane,
-- a tab, or a session, with a terminal or an agent. A folder that is already
-- open is shown instead.
--
--   require("projects").setup{}
--
-- Every question has a matching argument, so the action also runs unattended:
--
--   rex do projects_open dir=~/code/app launcher=claude place=tab

local must = require("projects.must")
local paths = require("projects.paths")
local places = require("projects.places")

-- Row IDs that aren't folders. A folder's ID is its absolute path.
local OPEN_HERE = "."
local NEW_FOLDER = "+new"

local M = {}

-- Asks a question with rex.ui.input or rex.ui.pick. Returns nil when there is
-- no answer, and logs why unless the person simply closed the prompt.
local function ask(prompt, spec)
  local answer, why, detail = prompt(spec)
  if answer == nil and why ~= "cancelled" then
    rex.log("warn", ("projects: %q got no answer: %s %s"):format(spec.title, why, detail or ""))
  end
  return answer
end

local function create_folder(parent)
  local name = ask(rex.ui.input, {
    title = "New folder in " .. paths.display(parent),
    placeholder = "Folder name",
    confirm = "Create folder",
  })
  if name == nil then return nil end

  name = paths.trim(name)
  if name == "" or name:find("/") or name:sub(1, 1) == "." then
    error("Not a valid folder name: " .. name, 0)
  end

  local dir = paths.join(parent, name)
  must(paths.mkdir(dir))
  return dir
end

-- The rows for one folder, in order: open it, go up, go into one of its
-- folders, or create a folder. Every row that moves has the folder it leads
-- to as its ID.
local function folder_items(dir, opened)
  local function status(folder)
    return opened[folder] and "open" or nil
  end

  local items = {
    { id = OPEN_HERE, title = ".", subtitle = "Open " .. paths.display(dir), detail = status(dir) },
  }
  local parent = paths.parent(dir)
  if parent then
    items[#items + 1] = { id = parent, title = "..", subtitle = paths.display(parent) }
  end
  for _, name in ipairs(must(paths.folders(dir))) do
    local folder = paths.join(dir, name)
    items[#items + 1] = { id = folder, title = name, icon = "folder", detail = status(folder) }
  end
  items[#items + 1] = { id = NEW_FOLDER, title = "New Folder…", icon = "plus" }
  return items
end

-- Lets the person walk the folders, starting at `dir`, until they open one.
local function browse(dir, opened)
  while true do
    local choice = ask(rex.ui.pick, {
      title = "Open project",
      placeholder = "Filter folders in " .. paths.display(dir),
      items = folder_items(dir, opened),
    })
    if choice == nil then return nil end
    if choice == OPEN_HERE then return dir end

    if choice == NEW_FOLDER then
      local created = create_folder(dir)
      if created then return created end
    else
      dir = choice
    end
  end
end

-- Returns the option with the ID that was given, or that the person picks.
local function choose(options, given, title)
  -- Options carry fields a prompt can't take, such as functions.
  local rows = {}
  for i, option in ipairs(options) do
    rows[i] = { id = option.id, title = option.title, subtitle = option.subtitle, icon = option.icon }
  end

  local id = given or ask(rex.ui.pick, { title = title, items = rows })
  if id == nil then return nil end

  for _, option in ipairs(options) do
    if option.id == id then return option end
  end
  error(("%s: no option named %s"):format(title, id), 0)
end

local function open_project(launchers, ctx, args)
  local opened = places.opened(ctx.block_id)

  local dir
  if args.dir then
    dir = must(paths.resolve(args.dir))
  else
    dir = browse(places.working_dir(ctx.session_id, ctx.block_id) or paths.home, opened)
  end
  if dir == nil then return end

  -- A terminal that closed while the person was choosing can't be focused,
  -- so the folder is opened again.
  local existing = opened[dir] and places.focus(opened[dir])
  if existing then return existing end

  local launcher = choose(launchers, args.launcher, "Open with")
  if launcher == nil then return end
  local kind = choose(places.kinds, args.place, "Open in")
  if kind == nil then return end
  return places.create(kind, ctx, dir, launcher)
end

-- Registers the action. Options:
--   launchers  the list offered after choosing a folder (see launchers.lua)
function M.setup(options)
  options = options or {}
  local launchers = options.launchers or require("projects.launchers")

  rex.action{
    name = "projects_open",
    title = "Projects: Open Project…",
    description = "Browse from the folder you are in and open one, or go to it if it is already open.",
    category = "Projects",
    keywords = "project folder workspace agent claude codex pi terminal",
    args = { dir = "string?", launcher = "string?", place = "string?" },
    run = function(ctx, args)
      return open_project(launchers, ctx, args)
    end,
  }
end

return M
