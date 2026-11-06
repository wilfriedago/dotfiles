-- Migrated from Ghostty (~/.config/ghostty/config.ghostty)

-- config.ghostty:39 keybind = super+r=reload_config
rex.bind("cmd+r", "client.config.reload")

-- cmd+k clears the terminal (user choice); session picker moves to shift+cmd+k
rex.bind("cmd+k", "com.superlogical.terminal.clear")
rex.bind("shift+cmd+k", "session.switch")
