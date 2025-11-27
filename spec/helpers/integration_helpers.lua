--- Integration test helper functions
--- Provides utilities for testing module interactions and full initialization flows

local M = {}

--- Creates a minimal Spoon object for integration testing
--- @return table Spoon object with EventBus initialized
function M.createSpoonObject()
    local obj = {}
    obj.__index = obj
    obj.name = "HyperkeyHub"
    obj.version = "1.0"
    obj.author = "Test"
    obj.license = "MIT"

    -- Initialize EventBus
    local EventBus = require("event_bus")
    obj.EventBus = EventBus.new()

    -- Add executeCustomAction method (from init.lua:87-91)
    function obj:executeCustomAction(action)
        return function()
            action()
        end
    end

    return obj
end

--- Creates a requireModule function that loads modules from the modules directory
--- @param projectRoot string The project root directory
--- @return function requireModule function
function M.createRequireModule(projectRoot)
    return function(moduleName)
        local modulePath = projectRoot .. "modules/" .. moduleName
        return require(modulePath)
    end
end

--- Sets up a temporary config directory for testing
--- @param basePath string Base path for temp directory
--- @return string Config directory path
function M.setupTempConfigDirectory(basePath)
    basePath = basePath or "/tmp/test_hammerspoon"
    local configDir = basePath .. "/HyperkeyHub"

    -- Create directory structure
    os.execute("mkdir -p " .. configDir)

    return configDir
end

--- Creates a test configuration file
--- @param filepath string Path to write the config file
--- @param configData table Configuration data to write
--- @return boolean success
function M.createTestConfigFile(filepath, configData)
    local file = io.open(filepath, "w")
    if not file then
        return false
    end

    local json = require("dkjson")
    local jsonStr = json.encode(configData, { indent = true })
    file:write(jsonStr)
    file:close()

    return true
end

--- Captures events emitted by EventBus
--- @param eventBus table EventBus instance
--- @return table eventCapture object with .emissions and .clear()
function M.captureEvents(eventBus)
    local eventCapture = {
        emissions = {}
    }

    -- Store original emit function
    local originalEmit = eventBus.emit

    -- Override emit to capture events
    function eventBus:emit(eventName, eventData)
        table.insert(eventCapture.emissions, {
            event = eventName,
            data = eventData,
            timestamp = os.time()
        })
        return originalEmit(self, eventName, eventData)
    end

    -- Provide a way to clear emissions
    function eventCapture:clear()
        for i = #self.emissions, 1, -1 do
            self.emissions[i] = nil
        end
    end

    -- Provide a way to restore original emit
    function eventCapture:restore()
        eventBus.emit = originalEmit
    end

    return eventCapture
end

--- Sets up mock for application launching
--- @param appConfig table Config with app names and their mock behaviors
function M.setupAppMocks(appConfig)
    appConfig = appConfig or {}

    _G.hs.application = _G.hs.application or {}

    _G.hs.application.launchOrFocus = function(bundleID)
        local config = appConfig[bundleID] or { success = true }

        if config.success then
            return true
        else
            return false
        end
    end

    _G.hs.application.find = function(bundleID)
        local config = appConfig[bundleID] or { running = false }

        if config.running then
            return {
                bundleID = function() return bundleID end,
                name = function() return config.name or "MockApp" end
            }
        else
            return nil
        end
    end

    _G.hs.application.get = function(name)
        for bundleID, config in pairs(appConfig) do
            if config.name == name and config.running then
                return {
                    bundleID = function() return bundleID end,
                    name = function() return name end
                }
            end
        end
        return nil
    end
end

--- Sets up mock for window management
--- @param windowConfig table Config for window operations
function M.setupWindowMocks(windowConfig)
    windowConfig = windowConfig or {}

    _G.hs.window = _G.hs.window or {}
    _G.hs.window.animationDuration = 0.2

    local mockWindow = {
        frame = function(self)
            return windowConfig.currentFrame or { x = 0, y = 0, w = 800, h = 600 }
        end,

        setFrame = function(self, frame, duration)
            windowConfig.lastSetFrame = frame
            windowConfig.lastDuration = duration
        end,

        screen = function(self)
            return {
                frame = function()
                    return windowConfig.screenFrame or { x = 0, y = 0, w = 1920, h = 1080 }
                end
            }
        end
    }

    _G.hs.window.focusedWindow = function()
        if windowConfig.hasFocusedWindow == false then
            return nil
        end
        return mockWindow
    end
end

--- Sets up mock for hotkey management
--- @return table Mock hotkey data
function M.setupHotkeyMocks()
    local hotkeyData = {
        bindings = {},
        modalBindings = {},
        eventTaps = {}
    }

    _G.hs.hotkey = _G.hs.hotkey or {}

    _G.hs.hotkey.bind = function(mods, key, fn)
        table.insert(hotkeyData.bindings, {
            mods = mods,
            key = key,
            fn = fn
        })
    end

    -- Mock modal hotkey
    _G.hs.hotkey.modal = _G.hs.hotkey.modal or {}
    _G.hs.hotkey.modal.new = function(mods, key, message)
        local modal = {
            bindings = {},
            entered = false,
            exited = false
        }

        function modal:bind(mods, key, fn)
            table.insert(self.bindings, {
                mods = mods,
                key = key,
                fn = fn
            })
            table.insert(hotkeyData.modalBindings, {
                mods = mods,
                key = key,
                fn = fn
            })
        end

        function modal:enter()
            self.entered = true
        end

        function modal:exit()
            self.exited = true
        end

        return modal
    end

    return hotkeyData
end

--- Sets up mock for event tap
--- @return table Event tap data
function M.setupEventTapMocks()
    local eventTapData = {
        taps = {},
        events = {}
    }

    _G.hs.eventtap = _G.hs.eventtap or {}

    _G.hs.eventtap.new = function(events, callback)
        local tap = {
            events = events,
            callback = callback,
            started = false
        }

        function tap:start()
            self.started = true
            table.insert(eventTapData.taps, self)
            return true
        end

        function tap:stop()
            self.started = false
            return true
        end

        return tap
    end

    _G.hs.eventtap.event = _G.hs.eventtap.event or {}
    _G.hs.eventtap.event.types = {
        keyDown = 10,
        keyUp = 11,
        flagsChanged = 12
    }

    return eventTapData
end

--- Sets up mock for menubar
--- @return table Menubar data
function M.setupMenubarMocks()
    local menubarData = {
        items = {},
        title = nil
    }

    _G.hs.menubar = _G.hs.menubar or {}

    _G.hs.menubar.new = function()
        local menubar = {
            title = nil,
            menu = nil
        }

        function menubar:setTitle(title)
            self.title = title
            menubarData.title = title
        end

        function menubar:setMenu(menu)
            self.menu = menu
            menubarData.items = menu
        end

        function menubar:delete()
            self.title = nil
            self.menu = nil
        end

        return menubar
    end

    return menubarData
end

--- Cleans up all test files and directories
--- @param basePath string Base path to clean
function M.cleanup(basePath)
    basePath = basePath or "/tmp/test_hammerspoon"
    os.execute("rm -rf " .. basePath)
end

--- Simulates a full bootstrap process
--- @param obj table Spoon object
--- @param requireModule function Module loader
--- @param configFile string|nil Optional config file path
--- @return table modules Loaded modules
function M.simulateBootstrap(obj, requireModule, configFile)
    local Bootstrap = requireModule("bootstrap")

    -- Load modules
    local modules = Bootstrap.loadModules(requireModule)
    modules.EventBus = obj.EventBus

    -- Load configuration
    local config, err = Bootstrap.loadConfiguration(obj, modules, configFile)
    if not config then
        return nil, err or "Configuration loading failed"
    end

    -- Initialize modules
    Bootstrap.initializeModules(modules, obj.EventBus)

    return modules
end

return M
