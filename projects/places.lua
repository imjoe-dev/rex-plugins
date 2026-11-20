-- Finds the terminals that already have a folder open, and creates new ones
-- in a pane, a tab, or a session. A place is where a terminal is, as
-- { session_id, window_id, block_id }.

local must = require("projects.must")
local paths = require("projects.paths")
local store = require("projects.store")

local TERMINAL = "com.superlogical.terminal"
local SHELL = TERMINAL .. ".shell"

local M = {}

local function place(session_id, window_id, block_id)
  return { session_id = session_id, window_id = window_id, block_id = block_id }
end

-- The directory a terminal is working in, or nil when it can't be told. It is
-- read from the terminal's processes, because the terminal's own `pwd` is
-- only set by shells that report it.
function M.working_dir(session_id, block_id)
  local info = rex.block.call(TERMINAL, "process", {
    session_id = session_id,
    block_id = block_id,
  })
  if info == nil then return nil end
  if info.foreground and info.foreground.cwd then return info.foreground.cwd end
  for _, process in ipairs(info.ancestors or {}) do
    if process.cwd then return process.cwd end
  end
  return nil
end

-- Returns the place of each terminal that is in a window of the session.
local function terminals(session_id)
  -- A session's blocks can only be read while attached to it.
  local attached, attach_err = rex.call("session.attach", { session_id = session_id })
  if attached == nil then return nil, attach_err end
  local listing, list_err = rex.session.list_blocks{ session_id = session_id }
  if listing == nil then return nil, list_err end

  local found = {}
  for _, block in ipairs(listing.blocks or {}) do
    if block.creator_name == TERMINAL and block.window_id then
      found[#found + 1] = place(session_id, block.window_id, block.block_id)
    end
  end
  return found
end

-- Returns a table from folder to the first place it is open. A terminal has
-- open the folder it was created for, or else the folder it is working in.
-- The terminal `except` is left out, so the pane an action runs from doesn't
-- count. Terminals that have closed are forgotten along the way.
function M.opened(except)
  local sessions = must(rex.call("session.list")).sessions or {}
  local remembered = store.blocks()
  local opened, alive, saw_all = {}, {}, true

  for _, session in ipairs(sessions) do
    local found, err = terminals(session.session_id)
    if found == nil then
      saw_all = false
      rex.log("warn", ("projects: couldn't read session %s: %s"):format(session.session_id, err))
    end

    for _, terminal in ipairs(found or {}) do
      alive[terminal.block_id] = true
      local dir = remembered[terminal.block_id]
        or M.working_dir(terminal.session_id, terminal.block_id)
      if dir and opened[dir] == nil and terminal.block_id ~= except then
        opened[dir] = terminal
      end
    end
  end

  -- A terminal in a session that couldn't be read may still be open.
  if saw_all then must(store.keep_only(alive)) end
  return opened
end

-- Focuses a terminal, and shows its session and tab in the app that ran the
-- action. Returns the place, or nil and a message if the terminal is gone.
function M.focus(target)
  local focused, err = rex.session.focus_block{
    session_id = target.session_id,
    block_id = target.block_id,
  }
  if focused == nil then return nil, err end

  -- The app chooses the session it shows, so it has to be asked. There is no
  -- app to ask when the action runs from the CLI, and the focus is enough.
  pcall(rex.client.queue, "session.select", {
    session_id = target.session_id,
    window_id = target.window_id,
  })
  return target
end

local function new_pane(ctx, layout)
  local split, err = rex.session.new_split{
    session_id = ctx.session_id,
    anchor_id = ctx.block_id,
    direction = "horizontal",
    side = "after",
    layout = layout,
  }
  if split == nil then return nil, err end

  local block_id = split.block_ids[1]
  local described = rex.session.describe_block{ session_id = ctx.session_id, block_id = block_id }
  return place(ctx.session_id, described and described.block.window_id, block_id)
end

local function new_tab(ctx, layout, label)
  local window, err = rex.session.new_window{
    session_id = ctx.session_id,
    window_label = label,
    layout = layout,
  }
  if window == nil then return nil, err end
  return place(ctx.session_id, window.window_id, window.block_ids[1])
end

local function new_session(ctx, layout, label)
  local created, err = rex.call("session.create", {
    label = label,
    initial_windows = { { window_label = label, layout = layout } },
  })
  if created == nil then return nil, err end

  local window = created.initial_windows[1]
  return place(created.session_id, window.window_id, window.block_ids[1])
end

-- Where a folder can be opened, in the order they are offered. `create` is
-- called as create(ctx, layout, label) and returns the new terminal's place.
M.kinds = {
  { id = "pane", title = "New Pane", subtitle = "Beside the focused pane", icon = "terminal", create = new_pane },
  { id = "tab", title = "New Tab", subtitle = "In this session", icon = "document", create = new_tab },
  { id = "session", title = "New Session", subtitle = "Named after the folder", icon = "server", create = new_session },
}

-- Starts the launcher in the folder, in a new place of the given kind, and
-- focuses it.
function M.create(kind, ctx, dir, launcher)
  local options = { cwd = dir }
  if launcher.command then
    options.command = launcher.command
    -- Agents are often on a PATH that only ~/.zshrc and its like set.
    options.interactive = true
  end

  local layout = rex.layout.block{ flavor = SHELL, options = options }
  local created = must(kind.create(ctx, layout, paths.basename(dir)))
  must(store.remember(created.block_id, dir))
  M.focus(created)
  return created
end

return M
