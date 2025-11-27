# Installation Guide

This guide covers all installation methods for HyperkeyHub.spoon.

## Prerequisites

- macOS
- [Hammerspoon](https://www.hammerspoon.org/) 0.9.97 or later

If you don't have Hammerspoon installed:

```bash
brew install --cask hammerspoon
```

Then launch it from Applications.

## Installation Methods

### Method 1: Manual Installation (Recommended for Users)

1. [Download the latest release](https://github.com/TK568/HyperkeyHub.spoon/releases)
2. Extract `HyperkeyHub.spoon.zip`
3. Double-click `HyperkeyHub.spoon`
4. Hammerspoon will install it automatically

### Method 2: Git Clone (Recommended for Developers)

```bash
cd ~/.hammerspoon/Spoons
git clone https://github.com/TK568/HyperkeyHub.spoon.git
```

This method makes it easier to:
- Track updates with `git pull`
- Contribute changes back to the project
- Test development versions

## Basic Setup

HyperkeyHub can be used immediately without any configuration file setup.

### 1. Add to init.lua

Add these 2 lines to `~/.hammerspoon/init.lua`:

```lua
hs.loadSpoon("HyperkeyHub")
spoon.HyperkeyHub:start()
```

That's it! The spoon will start with default settings.

## Configuration File Setup (Optional)

If you want to customize and save your settings, set up a configuration file.

### 1. Create Configuration File

For the standard location (`~/.hammerspoon/HyperkeyHub/config.json`):

```bash
mkdir -p ~/.hammerspoon/HyperkeyHub
cp ~/.hammerspoon/Spoons/HyperkeyHub.spoon/resources/config_templates/default_config.json \
   ~/.hammerspoon/HyperkeyHub/config.json
```

### 2. Specify Path in init.lua

Set the `configPath` property before calling `:start()`:

```lua
hs.loadSpoon("HyperkeyHub")

-- Using standard location
spoon.HyperkeyHub.configPath = os.getenv("HOME") .. "/.hammerspoon/HyperkeyHub/config.json"

-- Using Dropbox:
-- spoon.HyperkeyHub.configPath = os.getenv("HOME") .. "/Dropbox/HyperkeyHub/config.json"

-- Using iCloud Drive:
-- spoon.HyperkeyHub.configPath = os.getenv("HOME") .. "/Library/Mobile Documents/com~apple~CloudDocs/HyperkeyHub/config.json"

spoon.HyperkeyHub:start()
```

**Key Points:**
- Without setting `configPath`, the spoon will use default settings (read-only)
- You only need to set `configPath` if you want to save customized settings
- If using a custom path, copy the configuration file to that location

## Verifying Installation

After installation:

1. Add to `~/.hammerspoon/init.lua`:
   ```lua
   hs.loadSpoon("HyperkeyHub")
   spoon.HyperkeyHub:start()
   ```

2. Reload Hammerspoon: Click menu bar icon → "Reload Config"

3. Check the menu bar for the ✧ icon

4. Press `F19 + F` to verify Finder launches/focuses

If you see the ✧ icon and key bindings work, installation was successful!

## Uninstalling

To remove HyperkeyHub:

1. Remove the loading lines from `~/.hammerspoon/init.lua`
2. Delete the Spoon directory:
   ```bash
   rm -rf ~/.hammerspoon/Spoons/HyperkeyHub.spoon
   ```
3. (Optional) Remove configuration:
   ```bash
   rm -r ~/.hammerspoon/HyperkeyHub
   ```
4. Reload Hammerspoon

## Next Steps

- [Basic Usage](usage.md) - Learn how to use HyperkeyHub
- [Configuration](configuration.md) - Customize your setup
- [Troubleshooting](troubleshooting.md) - Fix common issues
