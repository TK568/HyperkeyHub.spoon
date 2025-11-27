# Configuration Guide

HyperkeyHub offers three configuration methods with different levels of flexibility.

## Configuration Methods Overview

| Method | Best For | Flexibility | Ease of Use |
|--------|----------|-------------|-------------|
| **GUI Settings** | Most users | ★★☆ | ★★★ |
| **JSON File** | Power users | ★★☆ | ★★☆ |
| **Code-based** | Developers | ★★★ | ★☆☆ |

**Configuration Priority:**
1. Default configuration (built-in)
2. JSON configuration file (if exists)
3. Code-based configuration via `:configure()` (highest priority)

## Method 1: GUI Settings (Recommended)

The easiest way to configure HyperkeyHub.

### Opening Settings

1. Click the ✧ icon in the menu bar
2. Select "⚙️ Settings..."

### Available Settings

#### General Tab

**✧ (Hyper) Key:**
- Choose from presets: F15, F16, F17, F18, F19 (default)
- Or click "Detect Key" and press any key you want to use

#### Shortcuts Tab

**Applications:**
- Click "+" to add new app
- Select from running applications (Bundle ID auto-detected)
- Or manually enter Bundle ID
- Add modifier keys: ⇧ Shift, ⌘ Command, ⌥ Option, ⌃ Control

**Window Management:**
- Customize arrow key layouts
- Add modifier combinations for advanced layouts

**System Actions:**
- Configure system shortcuts (reload, console, debug mode, etc.)

#### Backup Tab

- Create backups of your configuration
- Restore from previous backups
- Export/import settings

### Features

- ✅ Visual key detection (no need to look up key codes)
- ✅ Auto-fill app info from running applications
- ✅ Modifier key support (✧ + ⇧ + A, ✧ + ⌘ + C, etc.)
- ✅ Duplicate key combination validation
- ✅ Settings save (requires configPath setup)

## Method 2: JSON Configuration File

For users who prefer manual editing or need to version control their config.

### Location

**Default (read-only)**: Template file in Spoon
- Can only view settings
- To save settings, you need to set configPath as shown below

**Custom location (writable)**: Set in `init.lua`
```lua
spoon.HyperkeyHub.configPath = os.getenv("HOME") .. "/.hammerspoon/HyperkeyHub/config.json"
```

Or:
```lua
-- Using Dropbox
spoon.HyperkeyHub.configPath = os.getenv("HOME") .. "/Dropbox/HyperkeyHub/config.json"

-- Using iCloud Drive
spoon.HyperkeyHub.configPath = os.getenv("HOME") .. "/Library/Mobile Documents/com~apple~CloudDocs/HyperkeyHub/config.json"
```

### JSON Structure

```json
{
  "schema_version": 1,
  "hyperKeyCode": 80,
  "hyperKeyName": "F19",
  "applications": {
    "safari": {
      "key": "s",
      "bundle": "com.apple.Safari",
      "name": "Safari",
      "modifiers": []
    },
    "terminal": {
      "key": "t",
      "bundle": "com.apple.Terminal",
      "name": "Terminal",
      "modifiers": ["shift"]
    }
  },
  "window_management": {
    "left": {
      "key": "left",
      "modifiers": []
    },
    "right": {
      "key": "right",
      "modifiers": []
    }
  },
  "system_shortcuts": {
    "reload": {
      "key": "r",
      "modifiers": ["shift"]
    }
  },
  "script_shortcuts": {
    "my_script": {
      "name": "My Script",
      "key": "1",
      "modifiers": [],
      "type": "shell",
      "script_path": "~/scripts/my_script.sh"
    },
    "notification": {
      "name": "Notification",
      "key": "2",
      "modifiers": [],
      "type": "applescript",
      "script_inline": "display notification \"Hello\" with title \"Test\""
    }
  },
  "window_animation_duration": 0.2
}
```

### Finding Bundle IDs

**From command line:**
```bash
osascript -e 'tell application "System Events" to get bundle identifier of application process "AppName"'
```

**Example:**
```bash
osascript -e 'tell application "System Events" to get bundle identifier of application process "Safari"'
# Output: com.apple.Safari
```

**Common applications:**
- Safari: `com.apple.Safari`
- Finder: `com.apple.finder`
- Terminal: `com.apple.Terminal`
- VSCode: `com.microsoft.VSCode`
- Chrome: `com.google.Chrome`

### Common Hyper Key Codes

| Key | Code |
|-----|------|
| F15 | 76 |
| F16 | 77 |
| F17 | 78 |
| F18 | 79 |
| F19 | 80 (default) |

### Modifier Keys

Supported values in the `modifiers` array:
- `"shift"` - ⇧ Shift
- `"cmd"` - ⌘ Command
- `"alt"` - ⌥ Option (Alt)
- `"ctrl"` - ⌃ Control

**Example combinations:**
```json
{
  "myapp": {
    "key": "a",
    "modifiers": ["shift"],        // Hyper + Shift + A
    "bundle": "com.example.MyApp",
    "name": "My App"
  },
  "otherapp": {
    "key": "b",
    "modifiers": ["cmd", "shift"], // Hyper + Cmd + Shift + B
    "bundle": "com.example.OtherApp",
    "name": "Other App"
  }
}
```

## Method 3: Code-based Configuration

For advanced users who need custom functions or dynamic configuration.

### Basic Setup

In `~/.hammerspoon/init.lua`:

```lua
hs.loadSpoon("HyperkeyHub")

spoon.HyperkeyHub:configure({
    hyperKeyCode = 79,  -- F18
    applications = {
        safari = {
            key = "s",
            bundle = "com.apple.Safari",
            name = "Safari"
        }
    }
})

spoon.HyperkeyHub:start()
```

### Adding Custom Actions

```lua
hs.loadSpoon("HyperkeyHub")

spoon.HyperkeyHub:configure({
    system = {
        screenshot = {
            key = "s",
            action = function()
                hs.eventtap.keyStroke({"cmd", "shift"}, "4")
            end,
            name = "Screenshot"
        },
        toggleWifi = {
            key = "w",
            action = function()
                hs.wifi.setPower(not hs.wifi.interfaceDetails().power)
            end,
            name = "Toggle WiFi"
        }
    }
})

spoon.HyperkeyHub:start()
```

### Dynamic Configuration

```lua
local config = {
    hyperKeyCode = 80,
    applications = {}
}

-- Add apps dynamically
local apps = {"Safari", "Chrome", "Terminal"}
local keys = {"s", "c", "t"}

for i, appName in ipairs(apps) do
    config.applications[appName:lower()] = {
        key = keys[i],
        bundle = "com.apple." .. appName,
        name = appName
    }
end

spoon.HyperkeyHub:configure(config)
spoon.HyperkeyHub:start()
```

### Runtime Configuration Changes

```lua
-- Add a new action after startup
spoon.HyperkeyHub.config.system.newAction = {
    key = "n",
    action = function()
        hs.alert.show("New Action")
    end,
    name = "New Action"
}
```

## Script Shortcuts Configuration

Execute arbitrary shell scripts or AppleScripts from keyboard shortcuts.

### Basic Structure

```json
{
  "script_shortcuts": {
    "shortcut_id": {
      "name": "Display Name",
      "key": "key",
      "modifiers": ["modifier array"],
      "type": "shell or applescript",
      "script_path": "path to script file (optional)",
      "script_inline": "inline script code (optional)"
    }
  }
}
```

### Field Descriptions

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| `name` | Yes | Name used in logs and error displays | `"My Script"` |
| `key` | Yes | Trigger key | `"1"`, `"a"`, `"space"` |
| `modifiers` | No | Array of modifier keys | `[]`, `["shift"]`, `["cmd", "alt"]` |
| `type` | No | Script type (default: `"shell"`) | `"shell"`, `"applescript"` |
| `script_path` | Conditional | Path to script file | `"~/scripts/test.sh"` |
| `script_inline` | Conditional | Inline script code | `"echo 'Hello'"` |

**Note:** Either `script_path` or `script_inline` is required.

### Shell Script Examples

#### Execute from File

```json
{
  "script_shortcuts": {
    "backup": {
      "name": "Run Backup",
      "key": "b",
      "modifiers": ["shift"],
      "type": "shell",
      "script_path": "~/scripts/backup.sh"
    }
  }
}
```

Executed command: `/bin/bash ~/scripts/backup.sh`

#### Inline Script

```json
{
  "script_shortcuts": {
    "hello": {
      "name": "Hello World",
      "key": "h",
      "modifiers": [],
      "type": "shell",
      "script_inline": "echo 'Hello World' && osascript -e 'display notification \"Hello\" with title \"Test\"'"
    }
  }
}
```

### AppleScript Examples

#### Execute from File

```json
{
  "script_shortcuts": {
    "notify": {
      "name": "Custom Notification",
      "key": "n",
      "modifiers": [],
      "type": "applescript",
      "script_path": "~/scripts/notify.scpt"
    }
  }
}
```

Executed command: `osascript ~/scripts/notify.scpt`

#### Inline Script

```json
{
  "script_shortcuts": {
    "alert": {
      "name": "Show Alert",
      "key": "a",
      "modifiers": ["alt"],
      "type": "applescript",
      "script_inline": "display notification \"Task completed\" with title \"HyperkeyHub\""
    }
  }
}
```

### Advanced Examples

#### System Information Notification

```json
{
  "script_shortcuts": {
    "system_info": {
      "name": "System Info",
      "key": "i",
      "modifiers": ["cmd"],
      "type": "shell",
      "script_inline": "battery=$(pmset -g batt | grep -Eo '\\d+%' | head -1) && osascript -e \"display notification \\\"Battery: $battery\\\" with title \\\"System Info\\\"\""
    }
  }
}
```

#### Volume Control

```json
{
  "script_shortcuts": {
    "mute": {
      "name": "Toggle Mute",
      "key": "m",
      "modifiers": [],
      "type": "applescript",
      "script_inline": "set volume output muted (not (output muted of (get volume settings)))"
    }
  }
}
```

#### Launch Applications (AppleScript File)

```json
{
  "script_shortcuts": {
    "start_day": {
      "name": "Start Day Apps",
      "key": "d",
      "modifiers": ["shift"],
      "type": "applescript",
      "script_path": "~/scripts/start_day.scpt"
    }
  }
}
```

### Path Expansion

Script file paths support the following formats:

#### Absolute Path
Paths starting with `/` are used as-is:
- `/usr/local/bin/myscript.sh`

#### Tilde (`~`)
Expands to the home directory:
- `~/scripts/test.sh` → `/Users/username/scripts/test.sh`

#### Relative Path
Paths not starting with `/` or `~` are treated as relative to the HyperkeyHub Spoon resource directory:
- `resources/examples/test.sh` → `~/.hammerspoon/Spoons/HyperkeyHub.spoon/resources/examples/test.sh`

Useful for referencing example scripts included with the Spoon.

### Error Handling

- If a script file is not found, an error alert will be displayed
- If script execution fails, it will be logged with the exit code
- Errors can be viewed in the Hammerspoon console (✧ + Shift + R)

### Debugging

To check script execution status:

1. Open Hammerspoon console (✧ + Shift + R, or from menu bar)
2. Set log level to debug:
   ```lua
   spoon.HyperkeyHub.logLevel = "debug"
   ```
3. Execute the script and check the logs

## Customizing Window Management

Window management layouts can be customized through any configuration method.

### Available Layouts

**Basic layouts:**
- `left`: Left half
- `right`: Right half
- `up`: Top half
- `down`: Bottom half
- `m`: Maximize

**Thirds layouts (with Shift):**
- `left` + Shift: Left third
- `right` + Shift: Right third
- `c` + Shift: Center third

**Two-thirds layouts (with Shift):**
- `up` + Shift: Left two-thirds
- `down` + Shift: Right two-thirds

**Quarter layouts (with Cmd):**
- `u` + Cmd: Top-left quarter
- `i` + Cmd: Top-right quarter
- `j` + Cmd: Bottom-left quarter
- `k` + Cmd: Bottom-right quarter

### Custom Window Layout

```lua
spoon.HyperkeyHub:configure({
    window_management = {
        custom = {
            key = "c",
            modifiers = {"cmd"},
            action = function()
                local win = hs.window.focusedWindow()
                local frame = win:screen():frame()
                win:setFrame({
                    x = frame.x + frame.w * 0.25,
                    y = frame.y + frame.h * 0.25,
                    w = frame.w * 0.5,
                    h = frame.h * 0.5
                })
            end,
            name = "Center 50%"
        }
    }
})
```

## Configuration File Location

### Default Location

`~/.hammerspoon/HyperkeyHub/config.json`

### Custom Location

Set before calling `:start()`:

```lua
hs.loadSpoon("HyperkeyHub")

-- Dropbox
spoon.HyperkeyHub.configPath = os.getenv("HOME") .. "/Dropbox/HyperkeyHub/config.json"

-- iCloud Drive
-- spoon.HyperkeyHub.configPath = os.getenv("HOME") .. "/Library/Mobile Documents/com~apple~CloudDocs/HyperkeyHub/config.json"

spoon.HyperkeyHub:start()
```

**Note:** Configuration files are not automatically migrated. Copy the file manually to preserve settings.

## Backup and Restore

### Using GUI

1. Open Settings (✧ → Settings)
2. Go to "Backup" tab
3. Click "Create Backup" to save current configuration
4. Use "Restore" to load a previous backup

### Manual Backup

```bash
# Create backup
cp ~/.hammerspoon/HyperkeyHub/config.json ~/.hammerspoon/HyperkeyHub/config.json.backup

# Restore backup
cp ~/.hammerspoon/HyperkeyHub/config.json.backup ~/.hammerspoon/HyperkeyHub/config.json
```

## Next Steps

- [Usage Guide](usage.md) - Learn about key bindings and features
- [Troubleshooting](troubleshooting.md) - Fix configuration issues
- [Development](development.md) - Contribute to HyperkeyHub
