-- Loads the plugins from this folder so an action can be tried without
-- reloading the configuration. Run it from this folder:
--
--   rex do ./dev.lua --action projects_open

package.path = "./?/init.lua;" .. package.path

require("projects").setup{}
