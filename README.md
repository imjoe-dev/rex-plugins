# rex-plugins

Lua modules for [Rex](https://www.superlogical.com/rex). Rex has no plugin
system: it reads `~/.config/rex/init.lua`, and that file can `require` modules
that sit beside it. Each folder here is one such module.

## Install

Link a plugin into the config folder and load it from `init.lua`:

```sh
ln -s "$PWD/projects" ~/.config/rex/projects
echo 'require("projects").setup{}' >> ~/.config/rex/init.lua
rex config reload
```

Rex doesn't watch the files. Run `rex config reload` after every change.

## projects

Opens a project folder in a pane, a tab, or a session, with a terminal or an
agent.

| Action | Name |
| --- | --- |
| Projects: Open Project… | `projects_open` |

**Open Project** starts in the folder the focused terminal is working in, or
your home folder when there is none, and lets you walk the folders:

- **.** opens the folder you are in.
- **..** goes up one folder.
- A folder's row goes into that folder.
- **New Folder…** creates a folder here and opens it.

A folder marked `open` is shown instead of opened again. It counts as open
when a terminal was created for it, or when a terminal is working in exactly
that folder. The pane you run the action from doesn't count, so `.` opens the
folder you are in again. Otherwise you choose what to start (a terminal or an agent) and
where: a new pane beside the focused one, a new tab in this session, or a new
session named after the folder.

The folder each terminal was created for is saved in
`~/.config/rex/projects.json`.

Bind a key in `init.lua`:

```lua
rex.bind("cmd+shift+o", "projects_open")
```

Change what can be started:

```lua
require("projects").setup{
  launchers = {
    { id = "terminal", title = "Terminal", icon = "terminal" },
    { id = "claude", title = "Claude Code", icon = "code", command = { "claude" } },
    { id = "nvim", title = "Neovim", icon = "document", command = { "nvim", "." } },
  },
}
```

The action takes its answers as arguments, so it also runs unattended:

```sh
rex do projects_open dir=~/code/app launcher=claude place=tab
```

`place` is `pane`, `tab`, or `session`. From the CLI the folder is opened or
focused, but the app only switches to another session when Remote Control is
on in its settings.

## Develop

`dev.lua` loads the plugins from this folder, so an action can be tried
without reloading the configuration:

```sh
rex do ./dev.lua --action projects_open dir=~/code/app launcher=terminal place=tab
```
