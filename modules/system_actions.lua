--- System Actions Module
--- Provides system-level action definitions for HyperkeyHub
--- @module SystemActions

local SystemActions = {}

local moduleDir = debug.getinfo(1, "S").source:match("@(.*/)")
local function requireModule(name)
    local fullPath = moduleDir .. name .. ".lua"
    return dofile(fullPath)
end
local Logger = requireModule("logger")

local BUILT_IN_DEFAULTS = {
    hammerspoon = { key = "h", modifiers = {} },
    reload = { key = "r", modifiers = {} },
    debug = { key = "d", modifiers = {} },
    settings = { key = ",", modifiers = {} }
}

local function copyModifiers(modifiers)
    local copy = {}
    if type(modifiers) == "table" then
        for _, modifier in ipairs(modifiers) do
            table.insert(copy, modifier)
        end
    end
    return copy
end

local function buildShortcutMap(systemConfig)
    local shortcuts = {}
    local defaultShortcuts = (systemConfig and systemConfig.defaultSystemShortcuts)
    if not defaultShortcuts or next(defaultShortcuts) == nil then
        defaultShortcuts = BUILT_IN_DEFAULTS
    end

    for actionId, binding in pairs(defaultShortcuts) do
        shortcuts[actionId] = {
            key = binding.key,
            modifiers = copyModifiers(binding.modifiers)
        }
    end

    local overrides = systemConfig and systemConfig.systemShortcuts or {}
    for actionId, binding in pairs(overrides) do
        if type(binding) == "table" and binding.key then
            shortcuts[actionId] = {
                key = binding.key,
                modifiers = copyModifiers(binding.modifiers)
            }
        end
    end

    return shortcuts
end

local function getShortcut(shortcuts, actionId)
    if shortcuts[actionId] then
        shortcuts[actionId].modifiers = shortcuts[actionId].modifiers or {}
        return shortcuts[actionId]
    end

    local fallback = BUILT_IN_DEFAULTS[actionId]
    local resolved = {
        key = fallback and fallback.key or "f19",
        modifiers = copyModifiers(fallback and fallback.modifiers or {})
    }
    shortcuts[actionId] = resolved
    return resolved
end

--- Create system action definitions
--- @param obj table Main HyperkeyHub object
--- @param logger Logger Logger instance
--- @param configLoader ConfigLoader ConfigLoader instance
--- @param settingsUI SettingsUI SettingsUI module
--- @param systemConfig table System configuration table
--- @return table actions Table of system action definitions
function SystemActions.createActions(obj, logger, configLoader, settingsUI, systemConfig)
    local shortcuts = buildShortcutMap(systemConfig)

    local hammerspoonShortcut = getShortcut(shortcuts, "hammerspoon")
    local reloadShortcut = getShortcut(shortcuts, "reload")
    local debugShortcut = getShortcut(shortcuts, "debug")
    local settingsShortcut = getShortcut(shortcuts, "settings")

    return {
        hammerspoon = {
            key = hammerspoonShortcut.key,
            modifiers = hammerspoonShortcut.modifiers,
            action = function()
                hs.toggleConsole()
            end,
            name = "Hammerspoon Console"
        },
        reload = {
            key = reloadShortcut.key,
            modifiers = reloadShortcut.modifiers,
            action = function()
                logger:alert("🔄 Reloading configuration...")
                hs.reload()
            end,
            name = "Reload Config"
        },
        debug = {
            key = debugShortcut.key,
            modifiers = debugShortcut.modifiers,
            action = function()
                if Logger.level == Logger.DEBUG then
                    Logger.setGlobalLevel("info")
                    logger:alert("Debug mode OFF")
                else
                    Logger.setGlobalLevel("debug")
                    logger:alert("Debug mode ON")
                end
            end,
            name = "Toggle Debug Mode"
        },
        settings = {
            key = settingsShortcut.key,
            modifiers = settingsShortcut.modifiers,
            action = function()
                settingsUI.showSettings(
                    obj,
                    function(config)
                        return configLoader.saveSettings(config)
                    end,
                    function(obj)
                        logger:alert("✅ Settings saved. Reloading Hammerspoon...")
                        if obj.settingsWindow then
                            obj.settingsWindow:delete()
                            obj.settingsWindow = nil
                        end
                        hs.timer.doAfter(1, function()
                            hs.reload()
                        end)
                    end
                )
            end,
            name = "Settings"
        }
    }
end

return SystemActions
