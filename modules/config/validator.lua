-- Configuration validator module
-- Validates configuration structure and values

---@class Validator
--- Validator for HyperkeyHub configuration files
--- Ensures configuration meets required structure and value constraints
local Validator = {}

--- Valid keyboard modifiers
--- @type table<string, boolean>
local VALID_MODIFIERS = {cmd = true, alt = true, shift = true, ctrl = true}

--- Validate complete configuration
--- Validates all aspects of the configuration:
--- - hyperKeyCode (0-255)
--- - applications (name, key, bundle, optional modifiers)
--- - window_management (valid actions and bindings)
--- - system_shortcuts (valid system actions)
--- - customBindings (key, action function, optional mods)
--- @param config table Configuration to validate
--- @return boolean success True if valid
--- @return string|nil error Error message if invalid
function Validator.validateConfig(config)
    if not config then
        return false, "Configuration is nil"
    end

    -- Validate hyperKeyCode
    if config.hyperKeyCode then
        if type(config.hyperKeyCode) ~= "number" then
            return false, "hyperKeyCode must be a number"
        end
        if config.hyperKeyCode < 0 or config.hyperKeyCode > 255 then
            return false, "hyperKeyCode must be between 0 and 255"
        end
    end

    -- Validate showAlerts
    if config.showAlerts ~= nil then
        local validValues = {all = true, errors = true, none = true}
        -- Allow boolean for backward compatibility
        if type(config.showAlerts) == "boolean" then
            -- Valid (will be converted by config_loader)
        elseif type(config.showAlerts) ~= "string" or not validValues[config.showAlerts] then
            return false, "showAlerts must be 'all', 'errors', or 'none'"
        end
    end

    -- Validate applications
    if config.applications then
        if type(config.applications) ~= "table" then
            return false, "applications must be a table"
        end
        for i, app in ipairs(config.applications) do
            if type(app) ~= "table" then
                return false, string.format("Application at index %d must be a table", i)
            end
            if not app.name or type(app.name) ~= "string" then
                return false, string.format("Application at index %d is missing valid 'name' (string)", i)
            end
            if not app.key or type(app.key) ~= "string" then
                return false, string.format("Application '%s' is missing valid 'key' (string)", app.name)
            end
            if not app.bundle or type(app.bundle) ~= "string" then
                return false, string.format("Application '%s' is missing valid 'bundle' (string)", app.name)
            end
            -- Validate optional modifiers
            if app.modifiers then
                if type(app.modifiers) ~= "table" then
                    return false, string.format("Application '%s' has invalid 'modifiers' (must be table)", app.name)
                end
                for _, mod in ipairs(app.modifiers) do
                    if not VALID_MODIFIERS[mod] then
                        return false, string.format(
                            "Application '%s' has invalid modifier '%s' (must be cmd, alt, shift, or ctrl)",
                            app.name, mod
                        )
                    end
                end
            end
        end
    end

    -- Validate window_management
    if config.window_management then
        if type(config.window_management) ~= "table" then
            return false, "window_management must be a table"
        end
        local validActions = {
            left = true, right = true, maximize = true, center = true,
            leftThird = true, centerThird = true, rightThird = true,
            leftTwoThirds = true, rightTwoThirds = true,
            topHalf = true, bottomHalf = true,
            topLeftQuarter = true, topRightQuarter = true,
            bottomLeftQuarter = true, bottomRightQuarter = true
        }
        for actionId, binding in pairs(config.window_management) do
            if not validActions[actionId] then
                return false, string.format("Invalid window management action: '%s'", actionId)
            end
            if type(binding) ~= "table" then
                return false, string.format("Window management '%s' binding must be a table", actionId)
            end
            if not binding.key or type(binding.key) ~= "string" then
                return false, string.format("Window management '%s' is missing valid 'key' (string)", actionId)
            end
            if binding.modifiers then
                if type(binding.modifiers) ~= "table" then
                    return false, string.format("Window management '%s' has invalid 'modifiers' (must be table)", actionId)
                end
                for _, mod in ipairs(binding.modifiers) do
                    if not VALID_MODIFIERS[mod] then
                        return false, string.format(
                            "Window management '%s' has invalid modifier '%s'",
                            actionId, tostring(mod)
                        )
                    end
                end
            end
        end
    end

    local systemShortcuts = config.system_shortcuts or config.systemShortcuts
    if systemShortcuts then
        if type(systemShortcuts) ~= "table" then
            return false, "system_shortcuts must be a table"
        end
        local validSystemActions = {
            hammerspoon = true,
            reload = true,
            debug = true,
            settings = true,
            quit = true,
            saveWindowPosition = true,
            restoreWindowPosition = true
        }
        for actionId, binding in pairs(systemShortcuts) do
            if not validSystemActions[actionId] then
                return false, string.format("Invalid system shortcut action: '%s'", actionId)
            end
            if type(binding) ~= "table" then
                return false, string.format("System shortcut '%s' binding must be a table", actionId)
            end
            if not binding.key or type(binding.key) ~= "string" then
                return false, string.format("System shortcut '%s' is missing valid 'key' (string)", actionId)
            end
            if binding.modifiers then
                if type(binding.modifiers) ~= "table" then
                    return false, string.format("System shortcut '%s' has invalid 'modifiers' (must be table)", actionId)
                end
                for _, mod in ipairs(binding.modifiers) do
                    if not VALID_MODIFIERS[mod] then
                        return false, string.format(
                            "System shortcut '%s' has invalid modifier '%s'",
                            actionId, tostring(mod)
                        )
                    end
                end
            end
        end
    end

    -- Validate customBindings
    if config.customBindings then
        if type(config.customBindings) ~= "table" then
            return false, "customBindings must be a table"
        end
        for i, binding in ipairs(config.customBindings) do
            if type(binding) ~= "table" then
                return false, string.format("Custom binding at index %d must be a table", i)
            end
            if not binding.key or type(binding.key) ~= "string" then
                return false, string.format("Custom binding at index %d is missing valid 'key' (string)", i)
            end
            if not binding.action or type(binding.action) ~= "function" then
                return false, string.format("Custom binding at index %d is missing valid 'action' (function)", i)
            end
            if binding.mods then
                if type(binding.mods) ~= "table" then
                    return false, string.format("Custom binding at index %d has invalid 'mods' (must be table)", i)
                end
            end
        end
    end

    return true
end

return Validator
