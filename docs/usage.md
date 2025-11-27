# Usage Guide

Complete guide to using HyperkeyHub features.

## Basic Setup

Add to `~/.hammerspoon/init.lua`:

```lua
hs.loadSpoon("HyperkeyHub")
spoon.HyperkeyHub:start()
```

Reload Hammerspoon to activate.

## The Hyper Key

The Hyper key is your command key for all HyperkeyHub features.

**Default:** F19

**Customization:** Open Settings (Hyper + ,) to change the Hyper key.

**Don't have F19?** Use [Karabiner-Elements](https://karabiner-elements.pqrs.org/) to remap Caps Lock → F19 for easy access.

## Default Key Bindings

All shortcuts use the Hyper key (default: F19) as the base.

### Application Launcher

| Shortcut | Action |
|----------|--------|
| `Hyper + F` | Launch/Focus Finder |
| `Hyper + S` | Launch/Focus Safari |
| `Hyper + T` | Launch/Focus Terminal |

**How it works:**
- If app is not running → Launches it
- If app is running but hidden → Shows it
- If app is running and visible → Hides it
- If app is visible but not focused → Focuses it

**Add your apps:** Press `Hyper + ,` to open Settings and configure your favorite applications.

### Window Management

#### Basic Layouts

| Shortcut | Action | Visual |
|----------|--------|--------|
| `Hyper + ←` | Left half | `[██    ]` |
| `Hyper + →` | Right half | `[    ██]` |
| `Hyper + ↑` | Top half | `[██████]` (top) |
| `Hyper + ↓` | Bottom half | `[██████]` (bottom) |
| `Hyper + M` | Maximize | `[██████]` |

#### Thirds Layouts (with Shift)

| Shortcut | Action | Visual |
|----------|--------|--------|
| `Hyper + Shift + ←` | Left third | `[██      ]` |
| `Hyper + Shift + →` | Right third | `[      ██]` |
| `Hyper + Shift + C` | Center third | `[  ████  ]` |

#### Two-Thirds Layouts (with Shift)

| Shortcut | Action | Visual |
|----------|--------|--------|
| `Hyper + Shift + ↑` | Left two-thirds | `[████    ]` |
| `Hyper + Shift + ↓` | Right two-thirds | `[    ████]` |

#### Quarter Layouts (with Cmd)

| Shortcut | Action |
|----------|--------|
| `Hyper + Cmd + U` | Top-left quarter |
| `Hyper + Cmd + I` | Top-right quarter |
| `Hyper + Cmd + J` | Bottom-left quarter |
| `Hyper + Cmd + K` | Bottom-right quarter |

### System Actions

| Shortcut | Action |
|----------|--------|
| `Hyper + ,` | Open Settings window |
| `Hyper + Shift + H` | Open Hammerspoon console |
| `Hyper + Shift + R` | Reload Hammerspoon config |
| `Hyper + Shift + D` | Toggle debug mode (INFO ⇄ DEBUG) |
| `Hyper + Alt + Q` | Start screensaver |

### Window Position Memory

Save and restore window positions across sessions.

| Shortcut | Action |
|----------|--------|
| `Hyper + Alt + S` | Save current window position |
| `Hyper + Alt + R` | Restore saved window position |

**Use case:** Remember your perfect window layout and restore it after disconnecting external monitors.

## Features

### Application Launcher

**Toggle Behavior:**
The app launcher intelligently handles app visibility:

1. **App not running** → Launches app
2. **App hidden** → Shows app
3. **App visible but not focused** → Focuses app
4. **App focused** → Hides app

This toggle behavior makes it easy to quickly show/hide apps with a single keystroke.

### Electron App Support

Some Electron-based apps don't respond to standard `hide()` commands. HyperkeyHub automatically detects and handles these apps using alternative methods.

**Supported apps include:**
- Visual Studio Code
- Slack
- Discord
- And other Electron-based applications

### Window Management

**Smooth animations:** Window movements include smooth transitions (default: 0.2s).

**Multi-monitor support:** Layouts work across multiple displays, using the screen where the window currently resides.

**Smart positioning:** Windows maintain their position relative to the screen bounds, even when switching between monitors.

### Menu Bar Integration

The ✧ icon appears in your menu bar when HyperkeyHub is active.

**Menu options:**
- ⚙️ Settings... - Open configuration GUI
- About HyperkeyHub - Version information

## Workflow Examples

### Developer Setup

```lua
-- Configure for development workflow
Applications:
- Hyper + C → VSCode
- Hyper + B → Browser
- Hyper + T → Terminal
- Hyper + D → Database client

Window Layout:
- Hyper + ← → VSCode (left half)
- Hyper + → → Browser (right half)
- Hyper + Cmd + ↓ → Terminal (bottom half)
```

### Writing/Research Setup

```lua
Applications:
- Hyper + W → Word processor
- Hyper + B → Browser (research)
- Hyper + N → Notes app

Window Layout:
- Hyper + Shift + ← → Notes (left third)
- Hyper + Shift + ↓ → Browser (right two-thirds)
- Hyper + M → Word processor (maximize)
```

### Multi-Monitor Setup

```lua
# Save perfect layout with all monitors connected
Hyper + Alt + S

# Disconnect laptop, use local layout
...work on the go...

# Return home, reconnect monitors
Hyper + Alt + R  # Restore saved positions
```

## Customization

### Adding Applications

**Via GUI (Recommended):**
1. Press `Hyper + ,`
2. Go to "Shortcuts" tab
3. Click "+" under Applications
4. Select running app or enter Bundle ID manually
5. Choose key and modifiers
6. Click "Save"

**Via JSON:**
Edit `~/.hammerspoon/HyperkeyHub/config.json`:
```json
{
  "applications": {
    "myapp": {
      "key": "m",
      "bundle": "com.example.MyApp",
      "name": "My App",
      "modifiers": []
    }
  }
}
```

See [Configuration Guide](configuration.md) for details.

### Custom Window Layouts

See [Configuration Guide - Custom Window Layout](configuration.md#custom-window-layout) for creating custom window positions.

### Custom System Actions

See [Configuration Guide - Adding Custom Actions](configuration.md#adding-custom-actions) for creating custom functions.

## Tips & Tricks

### Quick App Switching

Use consistent keys across apps for muscle memory:
- `Hyper + B` → Browser (any browser you use)
- `Hyper + E` → Email client
- `Hyper + M` → Music app

### Modifier Combinations

Use modifiers to expand your available shortcuts without conflicts:
- `Hyper + A` → App 1
- `Hyper + Shift + A` → App 2
- `Hyper + Cmd + A` → App 3

### Window Snapshots

Before making major layout changes:
1. `Hyper + Alt + S` → Save current layout
2. Try new arrangement
3. `Hyper + Alt + R` → Restore if needed

### Debug Mode

Enable debug logging to troubleshoot:
1. `Hyper + Shift + D` → Toggle debug mode
2. `Hyper + Shift + H` → Open console to view logs
3. Reproduce issue
4. `Hyper + Shift + D` → Disable debug mode

## Keyboard Shortcuts Reference

Quick reference table for all default bindings:

| Category | Shortcut | Action |
|----------|----------|--------|
| **Apps** | `Hyper + F/S/T` | Finder/Safari/Terminal |
| **Window** | `Hyper + ←/→/↑/↓` | Half layouts |
| **Window** | `Hyper + M` | Maximize |
| **Window** | `Hyper + Shift + ←/→` | Left/Right thirds |
| **Window** | `Hyper + Shift + ↑/↓` | Two-thirds |
| **Window** | `Hyper + Shift + C` | Center third |
| **Window** | `Hyper + Cmd + U/I/J/K` | Quarters |
| **System** | `Hyper + ,` | Settings |
| **System** | `Hyper + Shift + H` | Console |
| **System** | `Hyper + Shift + R` | Reload |
| **System** | `Hyper + Shift + D` | Debug toggle |
| **System** | `Hyper + Alt + Q` | Screensaver |
| **Memory** | `Hyper + Alt + S/R` | Save/Restore position |

## Next Steps

- [Configuration Guide](configuration.md) - Customize your setup
- [Troubleshooting](troubleshooting.md) - Fix common issues
- [Development Guide](development.md) - Contribute to the project
