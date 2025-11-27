# HyperkeyHub.spoon

Hyperkey-based app launcher and window management commander for Hammerspoon

[日本語](README.ja.md)

## Quick Start

Get up and running in 3 minutes:

1. **Install Hammerspoon**: `brew install --cask hammerspoon` (then launch it from Applications)
2. **Install this Spoon**: See [Installation](docs/installation.md) for options
3. **Configure Hammerspoon**: Add these 2 lines to `~/.hammerspoon/init.lua`:
   ```lua
   hs.loadSpoon("HyperkeyHub")
   spoon.HyperkeyHub:start()
   ```
4. **Load the config**: Click Hammerspoon menu bar icon → "Reload Config"
5. **Verify**: Press `F19 + F` to launch/focus Finder

**Customize settings**: Press `F19 + ,` to open Settings and freely customize applications and shortcuts.

**Advanced configuration**: To save your settings, set up a custom configuration file location. See [Configuration Guide](docs/configuration.md) for details.

**New to Hyper keys?** Set up [Karabiner-Elements](https://karabiner-elements.pqrs.org/) to remap Caps Lock → F19.

## Features

- **App Launcher**: Launch/focus/hide apps with Hyper key + key
- **Window Management**: Manage window placement with Hyper key + arrow keys
- **Script Shortcuts**: Execute Shell, AppleScript, or Lua scripts with arguments
- **Electron App Support**: Automatically handles apps where standard `hide()` doesn't work
- **Customizable**: Freely configure applications and key bindings via GUI, JSON, or code
- **Window Position Memory**: Save and restore window layouts
- **Multi-Monitor Support**: Works seamlessly across multiple displays

## Requirements

- macOS
- [Hammerspoon](https://www.hammerspoon.org/) 0.9.97 or later

## Documentation

### User Guides
- [Installation Guide](docs/installation.md) - Install HyperkeyHub
- [Usage Guide](docs/usage.md) - Learn all features and key bindings
- [Configuration Guide](docs/configuration.md) - Customize your setup (GUI/JSON/Code)
- [Troubleshooting](docs/troubleshooting.md) - Fix common issues

### Developer Guides
- [Development Guide](docs/development.md) - Contribute to the project
- [Architecture Overview](docs/development.md#architecture) - Understand the codebase
- [Running Tests](docs/development.md#running-tests) - Test framework guide

## Quick Reference

### Default Key Bindings

**Applications** (configurable):
- `Hyper + F`: Finder
- `Hyper + S`: Safari
- `Hyper + T`: Terminal

**Window Management**:
- `Hyper + ←/→/↑/↓`: Half layouts (left/right/top/bottom)
- `Hyper + M`: Maximize
- `Hyper + Shift + ←/→/↑/↓`: Thirds and two-thirds
- `Hyper + Cmd + U/I/J/K`: Quarters

**System**:
- `Hyper + ,`: Settings
- `Hyper + Shift + R`: Reload config
- `Hyper + Shift + H`: Hammerspoon console

See [Usage Guide](docs/usage.md) for complete list.

## Configuration Methods

Choose the method that fits your needs:

| Method | Best For | Guide |
|--------|----------|-------|
| **GUI Settings** | Most users | [Configuration Guide](docs/configuration.md#method-1-gui-settings-recommended) |
| **JSON File** | Power users | [Configuration Guide](docs/configuration.md#method-2-json-configuration-file) |
| **Code-based** | Developers | [Configuration Guide](docs/configuration.md#method-3-code-based-configuration) |

## Design Notes

### Why no `bindHotkeys()` method?

Unlike traditional Hammerspoon Spoons that use `bindHotkeys()` for hotkey configuration, HyperkeyHub manages all keybindings through its configuration file (`~/.hammerspoon/HyperkeyHub/config.json`) and Settings UI.

**Reasons for this design:**

1. **Hyper Key Architecture**: HyperkeyHub is built around the Hyper key (F19) concept, where all shortcuts are `Hyper + key` combinations. This differs from the standard `{modifiers, key}` format used by `bindHotkeys()`.

2. **GUI-First Approach**: The Settings UI (`Hyper + ,`) allows users to visually configure all shortcuts without editing Lua code.

3. **Unified Configuration**: All settings (applications, window management, scripts) are stored in a single JSON file, making it easy to backup, sync, and version control.

**If you prefer code-based configuration**, use the `:configure()` method:

```lua
hs.loadSpoon("HyperkeyHub")
spoon.HyperkeyHub:configure({
    applications = {
        vscode = { name = "Visual Studio Code", key = "v", bundle = "com.microsoft.VSCode" }
    }
}):start()
```

## Contributing

Contributions are welcome! See [Development Guide](docs/development.md) for:
- Setting up development environment
- Running tests
- Code style guidelines
- Pull request process

## License

MIT License - See [LICENSE](LICENSE) for details

## Credits

- Electron app hide solution: [Hammerspoon Issue #3580](https://github.com/Hammerspoon/hammerspoon/issues/3580)
- Modal key approach: [Evan Travers](https://evantravers.com/articles/2020/06/08/hammerspoon-a-better-better-hyper-key/)

## Support

- [GitHub Issues](https://github.com/TK568/HyperkeyHub.spoon/issues) - Bug reports and feature requests
- [Documentation](docs/) - Comprehensive guides
- [Troubleshooting Guide](docs/troubleshooting.md) - Common issues and solutions
