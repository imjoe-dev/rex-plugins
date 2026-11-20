-- What can be started in a project. A launcher without `command` opens an
-- interactive shell. Override the list with setup{ launchers = { ... } }.

return {
  { id = "terminal", title = "Terminal", icon = "terminal" },
  { id = "claude", title = "Claude Code", icon = "code", command = { "claude" } },
  { id = "codex", title = "Codex", icon = "code", command = { "codex" } },
  { id = "pi", title = "Pi", icon = "code", command = { "pi" } },
}
