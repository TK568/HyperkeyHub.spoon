-- HyperKey management module
local HyperKey = {}

local moduleDir = debug.getinfo(1, "S").source:match("@(.*/)")
local function requireModule(name)
    local fullPath = moduleDir .. name .. ".lua"
    return dofile(fullPath)
end
local Logger = requireModule("logger")
local log = Logger.new("HyperKey")

--- Build list of registered keys from configuration
--- @param appConfig table Application configuration
--- @param systemConfig table System configuration
--- @param scriptConfig table Script shortcuts configuration
--- @return table registeredKeys Table of registered keys (without modifiers)
--- @return table registeredModifierKeys Table of registered modifier+key combinations
function HyperKey.buildRegisteredKeys(appConfig, systemConfig, scriptConfig)
    local registeredKeys = {}
    local registeredModifierKeys = {}

    for _, config in pairs(appConfig.applications) do
        local modifiers = config.modifiers or {}
        if #modifiers > 0 then
            local modKey = table.concat(modifiers, "+") .. "+" .. config.key
            registeredModifierKeys[modKey] = true
        end
        registeredKeys[config.key] = true
    end

    for _, config in pairs(systemConfig.functions) do
        local modifiers = config.modifiers or {}
        if #modifiers > 0 then
            local modKey = table.concat(modifiers, "+") .. "+" .. config.key
            registeredModifierKeys[modKey] = true
        end
        registeredKeys[config.key] = true
    end

    for _, config in pairs(scriptConfig.scriptShortcuts) do
        local modifiers = config.modifiers or {}
        if #modifiers > 0 then
            local modKey = table.concat(modifiers, "+") .. "+" .. config.key
            registeredModifierKeys[modKey] = true
        end
        registeredKeys[config.key] = true
    end

    for _, binding in ipairs(systemConfig.customBindings) do
        if binding.mods and #binding.mods > 0 then
            local modKey = table.concat(binding.mods, "+") .. "+" .. binding.key
            registeredModifierKeys[modKey] = true
        end
        registeredKeys[binding.key] = true
    end

    return registeredKeys, registeredModifierKeys
end

--- Check if a key should be suppressed (pure function for testing)
--- @param charKey string|nil Character key representation
--- @param activeModifiers table List of active modifiers (e.g., {"shift", "cmd"})
--- @param registeredKeys table Table of registered keys
--- @param registeredModifierKeys table Table of registered modifier+key combinations
--- @return boolean shouldSuppress True if key should be suppressed
function HyperKey.shouldSuppressKey(charKey, activeModifiers, registeredKeys, registeredModifierKeys)
    if not charKey then
        return true
    end

    if #activeModifiers > 0 then
        local modKey = table.concat(activeModifiers, "+") .. "+" .. charKey
        return not registeredModifierKeys[modKey]
    else
        return not registeredKeys[charKey]
    end
end

--- Setup EventTap for hyper key detection and handling
--- @param hyperConfig table Hyper key configuration (keyCode, keyCodeToChar)
--- @param hyperKeyState table State object for tracking hyper key press (isPressed)
--- @param hyper table Hammerspoon modal hotkey object
--- @param registeredKeys table Table of registered keys
--- @param registeredModifierKeys table Table of registered modifier+key combinations
--- @param eventBus table EventBus instance for emitting window events
--- @return table hyperTap EventTap instance
function HyperKey.setupEventTap(hyperConfig, hyperKeyState, hyper, registeredKeys, registeredModifierKeys, eventBus)
    local success, hyperTap = pcall(function()
        return hs.eventtap.new({
            hs.eventtap.event.types.keyDown,
            hs.eventtap.event.types.keyUp
        }, function(event)
            local keyCode = event:getKeyCode()
            local eventType = event:getType()
            local isKeyDown = (eventType == hs.eventtap.event.types.keyDown)

            log:debug("KeyEvent: code=%d, type=%s, hyperPressed=%s",
                     keyCode, eventType == hs.eventtap.event.types.keyDown and "keyDown" or "keyUp",
                     tostring(hyperKeyState.isPressed))

            if keyCode == hyperConfig.keyCode then
                if isKeyDown and not hyperKeyState.isPressed then
                    hyperKeyState.isPressed = true
                    hyper:enter()
                    log:debug("Hyper key pressed")
                elseif not isKeyDown and hyperKeyState.isPressed then
                    hyperKeyState.isPressed = false
                    hyper:exit()
                    log:debug("Hyper key released")
                end
                return true
            end

            if not hyperKeyState.isPressed then
                return false
            end

            if not isKeyDown then
                return false
            end

            local charKey = hyperConfig.keyCodeToChar[keyCode]
            local flags = event:getFlags()

            local hasShift = flags.shift
            local hasCmd = flags.cmd
            local hasAlt = flags.alt
            local hasCtrl = flags.ctrl

            local activeModifiers = {}
            if hasShift then table.insert(activeModifiers, "shift") end
            if hasCmd then table.insert(activeModifiers, "cmd") end
            if hasAlt then table.insert(activeModifiers, "alt") end
            if hasCtrl then table.insert(activeModifiers, "ctrl") end

            local shouldSuppress = HyperKey.shouldSuppressKey(charKey, activeModifiers, registeredKeys, registeredModifierKeys)

            if shouldSuppress then
                if #activeModifiers > 0 then
                    local modKey = table.concat(activeModifiers, "+") .. "+" .. (charKey or "unknown")
                    log:debug("Unregistered modifier key suppressed: %s", modKey)
                else
                    log:debug("Unregistered key suppressed: %s (code=%d)", charKey or "unknown", keyCode)
                end
                return true
            else
                if #activeModifiers > 0 then
                    local modKey = table.concat(activeModifiers, "+") .. "+" .. charKey
                    log:debug("Registered modifier key: %s", modKey)
                else
                    log:debug("Registered key processed: %s", charKey)
                end
                return false
            end
        end)
    end)

    if not success then
        log:error("Failed to create EventTap: %s", tostring(hyperTap))
        error("Failed to create EventTap: " .. tostring(hyperTap))
    end

    local startSuccess = hyperTap:start()
    if not startSuccess then
        log:error("Failed to start EventTap")
        error("Failed to start EventTap")
    end

    log:info("EventTap started successfully")
    return hyperTap
end

return HyperKey
