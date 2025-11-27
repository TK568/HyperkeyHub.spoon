# Troubleshooting Guide

Solutions to common issues with HyperkeyHub.

## Installation Issues

### Hammerspoon Won't Start

**Symptoms:**
- No Hammerspoon icon in menu bar
- Config reload does nothing

**Solutions:**

1. **Check if Hammerspoon is running:**
   ```bash
   ps aux | grep Hammerspoon
   ```

2. **Launch Hammerspoon manually:**
   - Open Applications folder
   - Double-click Hammerspoon.app

3. **Check Console for errors:**
   - Click Hammerspoon icon → Console
   - Look for error messages

4. **Verify installation:**
   ```bash
   ls -la ~/.hammerspoon/Spoons/HyperkeyHub.spoon
   ```

### HyperkeyHub Not Loading

**Symptoms:**
- No ✧ icon in menu bar
- Hyper key doesn't work

**Solutions:**

1. **Check init.lua syntax:**
   ```bash
   # In Hammerspoon Console
   hs.reload()
   # Check for syntax errors
   ```

2. **Verify Spoon path:**
   ```lua
   -- In Hammerspoon Console
   hs.spoons.list()
   -- Should show "HyperkeyHub"
   ```

3. **Check loading code:**
   ```lua
   -- Ensure these lines are in ~/.hammerspoon/init.lua
   hs.loadSpoon("HyperkeyHub")
   spoon.HyperkeyHub:start()
   ```

4. **Check for typos:**
   - Ensure correct capitalization: `HyperkeyHub` (not `hyperkeycommander`)
   - Ensure correct method: `:start()` (not `.start()`)

## Hyper Key Issues

### Hyper Key Not Responding

**Symptoms:**
- Pressing F19 (or configured key) does nothing
- No response from any Hyper key shortcuts

**Solutions:**

1. **Verify key code in Settings:**
   - Press `Hyper + ,` (if it works) or open Settings manually
   - Check if the correct key is configured
   - Try "Detect Key" and press your intended Hyper key

2. **Check for key conflicts:**
   ```bash
   # List all keyboard shortcuts
   defaults read com.apple.symbolichotkeys
   ```
   - Another app may be capturing the same key
   - Try a different key (F18, F17, etc.)

3. **Test with different key:**
   - Open Settings
   - Change to F18 or F17
   - Save and reload

4. **Restart Hammerspoon:**
   ```bash
   # Kill and restart
   killall Hammerspoon
   open -a Hammerspoon
   ```

5. **Check Karabiner-Elements:**
   - If using Karabiner-Elements for key remapping
   - Verify the remap is active
   - Check Karabiner-Elements EventViewer to see if key presses are detected

### Hyper Key Works Partially

**Symptoms:**
- Some shortcuts work, others don't
- Inconsistent behavior

**Solutions:**

1. **Check for duplicate bindings:**
   - Open Settings → Shortcuts tab
   - Look for duplicate key combinations
   - Remove or reassign conflicts

2. **Verify modifier keys:**
   - Ensure modifiers (Shift, Cmd, Alt, Ctrl) are correctly configured
   - Test without modifiers first

3. **Enable debug mode:**
   ```lua
   -- Press Hyper + Shift + D to toggle debug mode
   -- Check console for errors
   ```

## Application Launcher Issues

### App Won't Launch

**Symptoms:**
- Pressing app shortcut does nothing
- App doesn't appear

**Solutions:**

1. **Verify Bundle ID:**
   ```bash
   osascript -e 'tell application "System Events" to get bundle identifier of application process "AppName"'
   ```
   - Compare with configured Bundle ID
   - Update in Settings if different

2. **Check if app is installed:**
   ```bash
   mdfind "kMDItemKind == 'Application'" | grep -i "AppName"
   ```

3. **Try launching manually:**
   ```lua
   -- In Hammerspoon Console
   hs.application.open("com.apple.Safari")
   ```

4. **Check accessibility permissions:**
   - System Preferences → Security & Privacy → Privacy
   - Select "Accessibility" in left sidebar
   - Ensure Hammerspoon is checked

### App Won't Hide

**Symptoms:**
- App launches but won't hide when pressing shortcut again
- Toggle behavior not working

**Solutions:**

1. **Grant accessibility permissions:**
   - System Preferences → Security & Privacy → Privacy → Accessibility
   - Verify Hammerspoon is checked and enabled
   - If already checked, try:
     - Uncheck → recheck
     - Or remove → re-add Hammerspoon

2. **Electron apps:**
   - HyperkeyHub has built-in Electron app support
   - Some apps may require special handling
   - Check console for warnings

3. **Try alternative hide method:**
   ```lua
   -- In Hammerspoon Console
   local app = hs.application.find("com.apple.Safari")
   app:hide()
   ```

4. **Restart the app:**
   - Quit the problematic app completely
   - Try launching with HyperkeyHub again

### Wrong App Opens

**Symptoms:**
- Different app opens than expected
- Bundle ID mismatch

**Solutions:**

1. **Verify correct Bundle ID:**
   ```bash
   # Get Bundle ID from running app
   osascript -e 'tell application "System Events" to get bundle identifier of application process "Safari"'
   ```

2. **Update configuration:**
   - Open Settings
   - Edit the app entry
   - Update Bundle ID
   - Save and reload

3. **Check for multiple versions:**
   ```bash
   # Find all versions of an app
   mdfind "kMDItemKind == 'Application' && kMDItemDisplayName == 'Safari'"
   ```
   - You may have multiple versions installed
   - Specify the exact Bundle ID for the version you want

## Window Management Issues

### Window Management Not Working

**Symptoms:**
- Arrow key shortcuts don't move windows
- Windows don't resize

**Solutions:**

1. **Check for shortcut conflicts:**
   - System Preferences → Keyboard → Shortcuts
   - Look for conflicts with Mission Control, App Shortcuts
   - Disable conflicting shortcuts

2. **Test with focused window:**
   - Ensure a window is focused before using shortcuts
   - Click on a window to focus it
   - Try the shortcut again

3. **Verify app is not full screen:**
   - Window management doesn't work in macOS full screen mode
   - Exit full screen (ESC or green window button)

4. **Test with different app:**
   - Some apps have restricted window management
   - Try with Safari or Finder first

### Window Animations Laggy

**Symptoms:**
- Slow or choppy window movements
- Delayed response

**Solutions:**

1. **Reduce animation duration:**
   ```lua
   -- In init.lua or Settings
   spoon.HyperkeyHub:configure({
       window_animation_duration = 0.1  -- Default is 0.2
   })
   ```

2. **Disable animations:**
   ```lua
   spoon.HyperkeyHub:configure({
       window_animation_duration = 0
   })
   ```

3. **Check system performance:**
   - Close resource-intensive apps
   - Check Activity Monitor for high CPU/memory usage

### Windows Don't Position Correctly

**Symptoms:**
- Window ends up in wrong position
- Size is incorrect

**Solutions:**

1. **Check multiple monitors:**
   - Window may be moving to different screen
   - Ensure focused window is on the intended screen

2. **Verify screen resolution:**
   - Some layouts may behave unexpectedly with certain resolutions
   - Try basic layouts first (left, right, maximize)

3. **Reset window position:**
   - Manually move window to approximate position
   - Try layout shortcuts again

## Configuration Issues

### Settings Won't Save

**Symptoms:**
- Changes in Settings GUI don't persist
- Config reverts after reload

**Solutions:**

1. **Check file permissions:**
   ```bash
   ls -la ~/.hammerspoon/HyperkeyHub/config.json
   chmod 644 ~/.hammerspoon/HyperkeyHub/config.json
   ```

2. **Verify config path:**
   ```lua
   -- In Hammerspoon Console
   print(spoon.HyperkeyHub.configPath)
   ```

3. **Check for JSON syntax errors:**
   ```bash
   # Validate JSON
   cat ~/.hammerspoon/HyperkeyHub/config.json | python -m json.tool
   ```

4. **Backup and recreate:**
   ```bash
   mv ~/.hammerspoon/HyperkeyHub/config.json ~/.hammerspoon/HyperkeyHub/config.json.backup
   # Open Settings and reconfigure
   ```

### Configuration Conflicts

**Symptoms:**
- Settings don't match JSON file
- Code-based config ignored

**Solutions:**

1. **Understand priority:**
   - Default < JSON < Code-based (`:configure()`)
   - Code-based config overrides JSON

2. **Check for multiple configs:**
   - Search for multiple `:configure()` calls in init.lua
   - Remove or consolidate configurations

3. **Clear and start fresh:**
   ```bash
   # Backup current config
   cp ~/.hammerspoon/HyperkeyHub/config.json ~/Desktop/backup.json

   # Remove config
   rm -r ~/.hammerspoon/HyperkeyHub

   # Remove code-based config from init.lua
   # Reload and reconfigure via GUI
   ```

### Cannot Save Settings (Using Default Config)

**Symptoms:**
- "Configuration Path Not Set" error when trying to save settings
- Using default configuration

**Cause:**
- Default configuration (template file in repository) is read-only
- Custom configPath setup is required to save settings

**Solutions:**

1. **Create configuration file:**
   ```bash
   mkdir -p ~/.hammerspoon/HyperkeyHub
   cp ~/.hammerspoon/Spoons/HyperkeyHub.spoon/resources/config_templates/default_config.json \
      ~/.hammerspoon/HyperkeyHub/config.json
   ```

2. **Add configPath to `init.lua`:**
   ```lua
   hs.loadSpoon("HyperkeyHub")
   spoon.HyperkeyHub.configPath = os.getenv("HOME") .. "/.hammerspoon/HyperkeyHub/config.json"
   spoon.HyperkeyHub:start()
   ```

3. **Reload Hammerspoon**

Settings can now be saved.

### Custom Config Path Not Working

**Symptoms:**
- Config file at custom path not loaded
- Changes don't persist

**Note:** This section is for troubleshooting when you've already set a custom configPath and are experiencing issues. To save settings, see "Cannot Save Settings" above.

**Solutions:**

1. **Verify path is set before `:start()`:**
   ```lua
   hs.loadSpoon("HyperkeyHub")
   spoon.HyperkeyHub.configPath = "/your/custom/path.json"
   spoon.HyperkeyHub:start()  -- Must be AFTER setting path
   ```

2. **Check path exists:**
   ```bash
   ls -la /your/custom/path.json
   ```

3. **Verify write permissions:**
   ```bash
   touch /your/custom/path.json
   ```

4. **Use absolute paths:**
   ```lua
   -- Good
   spoon.HyperkeyHub.configPath = os.getenv("HOME") .. "/Dropbox/config.json"

   -- Bad (relative path)
   spoon.HyperkeyHub.configPath = "~/Dropbox/config.json"
   ```

## Performance Issues

### High CPU Usage

**Symptoms:**
- Hammerspoon using excessive CPU
- System slowdown

**Solutions:**

1. **Disable debug mode:**
   ```lua
   -- Press Hyper + Shift + D to toggle OFF
   ```

2. **Check for infinite loops:**
   - Review custom actions in code-based config
   - Look for event handlers that trigger recursively

3. **Restart Hammerspoon:**
   ```bash
   killall Hammerspoon && open -a Hammerspoon
   ```

### Memory Leaks

**Symptoms:**
- Hammerspoon memory usage grows over time
- System becomes sluggish

**Solutions:**

1. **Restart Hammerspoon:**
   - Quick fix: Reload config (Hyper + Shift + R)
   - Full restart: Quit and relaunch

2. **Check for leaking events:**
   - Review custom code for event listeners that aren't cleaned up
   - Check console for warnings

3. **Update to latest version:**
   - Check for HyperkeyHub updates
   - Update Hammerspoon itself

## Debugging Tips

### Enable Debug Logging

```lua
-- Press Hyper + Shift + D
-- Or in code:
spoon.HyperkeyHub.logger:setLogLevel("debug")
```

### View Console Output

```lua
-- Press Hyper + Shift + H
-- Or click Hammerspoon icon → Console
```

### Test Individual Components

```lua
-- In Hammerspoon Console

-- Test app launching
hs.application.open("com.apple.Safari")

-- Test window management
local win = hs.window.focusedWindow()
local frame = win:frame()
print(hs.inspect(frame))

-- Test key detection
local eventtap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(e)
    print("Key code:", e:getKeyCode())
end)
eventtap:start()
```

### Check Event Bus

```lua
-- In Hammerspoon Console
-- Subscribe to all events
spoon.HyperkeyHub.eventBus:on("*", function(event, ...)
    print("Event:", event, ...)
end)
```

## Getting Help

If you're still experiencing issues:

1. **Check existing issues:**
   - [GitHub Issues](https://github.com/TK568/HyperkeyHub.spoon/issues)

2. **Gather information:**
   - Hammerspoon version: Check About menu
   - macOS version: System Preferences → About
   - HyperkeyHub version: Check spoon metadata
   - Error messages from console

3. **Create an issue:**
   - Include all gathered information
   - Describe steps to reproduce
   - Attach relevant config (redact sensitive data)

4. **Community support:**
   - Hammerspoon Discord/Forums
   - Stack Overflow (tag: hammerspoon)

## Next Steps

- [Usage Guide](usage.md) - Learn all features
- [Configuration Guide](configuration.md) - Advanced customization
- [Development Guide](development.md) - Contribute fixes
