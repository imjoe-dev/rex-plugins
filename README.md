# rex-plugins

Plugins for [Rex](https://www.superlogical.com/rex), the terminal multiplexer,
written in Lua.

| Plugin | What it does |
| --- | --- |
| [projects](#projects) | Jump to any folder and open it with a terminal or a coding agent. |

## Install

Rex loads Lua modules that sit beside its config file, so installing a plugin
is a link and one line of config.

```sh
git clone https://github.com/imjoe-dev/rex-plugins.git
cd rex-plugins

mkdir -p ~/.config/rex
ln -s "$PWD/projects" ~/.config/rex/projects
echo 'require("projects").setup{}' >> ~/.config/rex/init.lua

rex config reload
```

To update, run `git pull` and `rex config reload`.

## projects

A folder picker for the command palette. Run **Projects: Open Project…**,
choose a folder, choose what to start in it, and choose where it goes.

**1. Choose a folder.** The picker starts in the folder your terminal is in.

| Row | What it does |
| --- | --- |
| `.` | Opens the folder you are looking at. |
| `..` | Goes up one folder. |
| A folder | Goes into that folder. |
| New Folder… | Creates a folder here and opens it. |

**2. Choose what to start.** A terminal, Claude Code, Codex, or Pi.

**3. Choose where.** A new pane, a new tab, or a new session.

A folder that is already open is marked `open`. Choosing it takes you to its
terminal instead of opening it twice.

### Key binding

Add a key to `~/.config/rex/init.lua`:

```lua
rex.bind("cmd+shift+o", "projects_open")
```

### Launchers

Pass your own list to change what can be started. A launcher without a
`command` opens a shell.

```lua
require("projects").setup{
  launchers = {
    { id = "terminal", title = "Terminal", icon = "terminal" },
    { id = "claude", title = "Claude Code", icon = "code", command = { "claude" } },
    { id = "nvim", title = "Neovim", icon = "document", command = { "nvim", "." } },
  },
}
```

### From the command line

Each question has a matching argument, so the action can run without asking:

```sh
rex do projects_open dir=~/code/app launcher=claude place=tab
```

`place` is `pane`, `tab`, or `session`. Leave an argument out to be asked for
it.

### Good to know

- A folder counts as open when a terminal was created for it, or when a
  terminal is working in exactly that folder. The pane you start from doesn't
  count, so `.` opens a second terminal in the folder you are in.
- The plugin remembers which folder each terminal was created for in
  `~/.config/rex/projects.json`.
- Folders that are symbolic links and hidden folders aren't listed.
- From the command line, the Rex app only switches to another session when
  Remote Control is on in its settings.

## Development

`dev.lua` loads the plugins straight from this folder, so you can try a change
without reloading your config:

```sh
rex do ./dev.lua --action projects_open dir=~/code/app launcher=terminal place=tab
```

Each plugin is a folder with an `init.lua` that exports `setup`.
