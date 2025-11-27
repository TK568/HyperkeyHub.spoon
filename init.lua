--- === HyperkeyHub ===
---
--- Hyperkey-based app launcher and window management hub
---
--- Features:
--- - Use F19 key (remapped Caps Lock) as Hyper key
--- - Launch/focus/hide applications with toggle
--- - Window management (left/right half, maximize, center, thirds)
--- - Support for Electron apps (Arc, VSCode, etc.) hiding
---
--- Download: https://github.com/TK568/HyperkeyHub.spoon

local obj = {}
obj.__index = obj

obj.name = "HyperkeyHub"
obj.version = "1.0.0"
obj.author = "TK568 <TK568@users.noreply.github.com>"
obj.homepage = "https://github.com/TK568/HyperkeyHub.spoon"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local function requireModule(name)
    local fullPath = hs.spoons.resourcePath("modules/" .. name .. ".lua")

    if not hs.fs.attributes(fullPath) then
        local err = string.format("Module not found: %s (expected path: %s)", name, fullPath)
        hs.printf("[HyperkeyHub:ERROR] %s", err)
        hs.alert.show("❌ Module load error: " .. name, 5)
        error(err)
    end

    local success, result = pcall(dofile, fullPath)
    if not success then
        local err = string.format("Failed to load module: %s\nError: %s", name, result)
        hs.printf("[HyperkeyHub:ERROR] %s", err)
        hs.alert.show("❌ Module load error: " .. name, 5)
        error(err)
    end

    return result
end

local Bootstrap = requireModule("bootstrap")
local Logger = requireModule("logger")
local EventBus = requireModule("event_bus")
local ConfigLoader = requireModule("config_loader")

local log = Logger.new("HyperkeyHub")

obj.configPath = nil
obj.hyper = nil
obj.hyperTap = nil
obj.hyperKeyState = { isPressed = false }
obj.registeredKeys = {}
obj.registeredModifierKeys = {}
obj.modifierHotkeys = {}
obj.settingsWindow = nil
obj.menuBar = nil
obj.keyDetectionTap = nil

obj.EventBus = EventBus.new()

--- HyperkeyHub:configure(configuration)
--- Method
--- Override configuration (for advanced customization)
---
--- Parameters:
---  * configuration - Table of configuration to override
---
--- Returns:
---  * The HyperkeyHub object
---
--- Notes:
---  * For basic configuration, use JSON config file (~/.hammerspoon/HyperkeyHub/config.json)
---  * Use this method when you need settings that cannot be expressed in JSON (e.g., custom functions)
---  * This configuration takes priority as it is loaded after JSON config
function obj:configure(configuration)
    ConfigLoader.applyConfigOverride({
        hyperConfig = self.hyperConfig,
        appConfig = self.appConfig,
        systemConfig = self.systemConfig,
        scriptConfig = self.scriptConfig
    }, configuration)
    return self
end

function obj:executeCustomAction(action)
    return function()
        action()
    end
end

--- HyperkeyHub:init()
--- Method
--- Spoon initialization (prepare resources only, do not start)
function obj:init()
    self.hyperKeyState.isPressed = false
    return self
end

--- HyperkeyHub:start()
--- Method
--- Start HyperkeyHub
---
--- Returns:
---  * The HyperkeyHub object
function obj:start()
    -- Check and migrate from old config directory if needed
    Bootstrap.checkAndMigrateConfigDirectory(log)

    local modules = Bootstrap.loadModules(requireModule)

    local config, err = Bootstrap.loadConfiguration(self, modules, self.configPath)
    if not config then
        log:alert(string.format("❌ Configuration Load Error\n\n%s\n\nPlease check file permissions or restore from backup.", err), 10)
        log:error("Failed to start: %s", err)
        return self
    end

    self.hyperConfig = config.hyperConfig
    self.appConfig = config.appConfig
    self.systemConfig = config.systemConfig
    self.scriptConfig = config.scriptConfig

    local accessibilityEnabled = hs.accessibilityState()
    if not accessibilityEnabled then
        log:alert("❌ Accessibility permission required", 5)
        hs.urlevent.openURL("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        return self
    end

    if self.hyper then
        self.hyper:exit()
        self.hyper = nil
    end
    if self.hyperTap then
        self.hyperTap:stop()
        self.hyperTap = nil
    end

    for _, hotkey in ipairs(self.modifierHotkeys) do
        hotkey:delete()
    end
    self.modifierHotkeys = {}

    Bootstrap.initializeModules(modules, self.EventBus)

    -- Apply showAlerts setting ("all" | "errors" | "none")
    local showAlerts = config.showAlerts or "all"
    self.showAlerts = showAlerts
    Logger.showAlerts = showAlerts
    modules.WindowManager:configure({ showAlerts = showAlerts })

    Bootstrap.setupHyperKeyBindings(self, modules, config, log)

    Bootstrap.createMenuBar(self, modules, log)

    log:alert("🚀 HyperkeyHub started!", 2)

    return self
end

--- HyperkeyHub:stop()
--- Method
--- Stop HyperkeyHub
---
--- Returns:
---  * The HyperkeyHub object
function obj:stop()
    if self.EventBus then
        self.EventBus:clear()
    end

    local modules = Bootstrap.loadModules(requireModule)
    if modules.AppLauncher then
        modules.AppLauncher:cleanup()
    end
    if modules.WindowManager then
        modules.WindowManager:cleanup()
    end
    if modules.ScriptRunner then
        modules.ScriptRunner:cleanup()
    end

    if self.hyper then
        self.hyper:exit()
        self.hyper = nil
    end
    if self.hyperTap then
        self.hyperTap:stop()
        self.hyperTap = nil
    end
    if self.keyDetectionTap then
        self.keyDetectionTap:stop()
        self.keyDetectionTap = nil
    end
    if self.settingsWindow then
        self.settingsWindow:delete()
        self.settingsWindow = nil
    end
    if self.menuBar then
        self.menuBar:delete()
        self.menuBar = nil
    end

    return self
end

return obj
