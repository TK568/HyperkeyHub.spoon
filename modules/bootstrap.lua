local Bootstrap = {}

local OLD_CONFIG_DIR_NAME = "HyperkeyCommander"
local NEW_CONFIG_DIR_NAME = "HyperkeyHub"

--- Check and migrate from old config directory (HyperkeyCommander -> HyperkeyHub)
--- @param log table Logger instance
--- @return boolean migrated True if migration was performed
function Bootstrap.checkAndMigrateConfigDirectory(log)
    local oldDir = hs.configdir .. "/" .. OLD_CONFIG_DIR_NAME
    local newDir = hs.configdir .. "/" .. NEW_CONFIG_DIR_NAME
    local oldConfigPath = oldDir .. "/config.json"
    local newConfigPath = newDir .. "/config.json"

    -- Check if old directory exists
    if not hs.fs.attributes(oldDir) then
        return false
    end

    -- Check if old config file exists
    if not hs.fs.attributes(oldConfigPath) then
        return false
    end

    -- Check if new directory already exists with config
    if hs.fs.attributes(newConfigPath) then
        log:info("New config already exists at %s, skipping migration", newConfigPath)
        return false
    end

    log:info("Found old config directory: %s", oldDir)
    log:info("Migrating to new directory: %s", newDir)

    -- Create new directory if it doesn't exist
    if not hs.fs.attributes(newDir) then
        local ok, err = hs.fs.mkdir(newDir)
        if not ok then
            log:error("Failed to create new config directory: %s", tostring(err))
            log:alert("❌ Failed to migrate config directory", 5)
            return false
        end
    end

    -- Copy config file
    local srcFile = io.open(oldConfigPath, "rb")
    if not srcFile then
        log:error("Failed to open old config file for reading")
        return false
    end
    local content = srcFile:read("*a")
    srcFile:close()

    local destFile = io.open(newConfigPath, "wb")
    if not destFile then
        log:error("Failed to open new config file for writing")
        return false
    end
    destFile:write(content)
    destFile:close()

    -- Copy backup files
    for file in hs.fs.dir(oldDir) do
        if file:match("^config%.json%.backup%.") then
            local oldBackupPath = oldDir .. "/" .. file
            local newBackupPath = newDir .. "/" .. file
            local backupSrc = io.open(oldBackupPath, "rb")
            if backupSrc then
                local backupContent = backupSrc:read("*a")
                backupSrc:close()
                local backupDest = io.open(newBackupPath, "wb")
                if backupDest then
                    backupDest:write(backupContent)
                    backupDest:close()
                end
            end
        end
    end

    log:info("Config migration completed: %s -> %s", oldDir, newDir)
    log:alert("✅ Config migrated from HyperkeyCommander to HyperkeyHub\n\nOld directory preserved at:\n" .. oldDir, 8)

    return true
end

function Bootstrap.loadModules(requireModuleFn)
    return {
        Logger = requireModuleFn("logger"),
        EventBus = requireModuleFn("event_bus"),
        WindowManager = requireModuleFn("window_manager"),
        AppLauncher = requireModuleFn("app_launcher"),
        ConfigLoader = requireModuleFn("config_loader"),
        HyperKey = requireModuleFn("hyper_key"),
        SettingsUI = requireModuleFn("settings_ui"),
        SystemActions = requireModuleFn("system_actions"),
        ScriptRunner = requireModuleFn("script_runner")
    }
end

function Bootstrap.loadConfiguration(obj, modules, configPath)
    if not obj.configPath then
        obj.configPath = configPath
    end
    modules.ConfigLoader._customConfigPath = obj.configPath

    local config, err = modules.ConfigLoader.loadWithDefaults()
    if not config then
        return nil, err
    end

    config.systemConfig.functions = modules.SystemActions.createActions(
        obj,
        modules.Logger.new("HyperkeyHub"),
        modules.ConfigLoader,
        modules.SettingsUI,
        config.systemConfig
    )

    return config, nil
end

function Bootstrap.initializeModules(modules, eventBus)
    modules.WindowManager:init(eventBus)
    modules.AppLauncher:init(eventBus)
    modules.ScriptRunner:init(eventBus)
end

function Bootstrap.setupHyperKeyBindings(obj, modules, config, log)
    obj.hyper = hs.hotkey.modal.new({}, nil)
    function obj.hyper:entered() end
    function obj.hyper:exited() end

    obj.registeredKeys, obj.registeredModifierKeys = modules.HyperKey.buildRegisteredKeys(
        config.appConfig,
        config.systemConfig,
        config.scriptConfig
    )

    for _, appConfig in pairs(config.appConfig.applications) do
        if appConfig.bundle then
            local modifiers = appConfig.modifiers or {}
            obj.hyper:bind(modifiers, appConfig.key, nil, function()
                obj.EventBus:emit("app:toggle", {
                    bundleID = appConfig.bundle,
                    appName = appConfig.name
                })
            end)
        end
    end

    for _, systemConfig in pairs(config.systemConfig.functions) do
        local modifiers = systemConfig.modifiers or {}
        obj.hyper:bind(modifiers, systemConfig.key, nil, obj:executeCustomAction(systemConfig.action))
    end

    for _, binding in ipairs(config.systemConfig.customBindings) do
        obj.hyper:bind(binding.mods, binding.key, nil, obj:executeCustomAction(binding.action))
    end

    if config.scriptConfig and config.scriptConfig.scriptShortcuts then
        for scriptId, scriptDef in pairs(config.scriptConfig.scriptShortcuts) do
            local modifiers = scriptDef.modifiers or {}
            log:debug("Registering script shortcut: %s (key=%s, modifiers=%s)",
                scriptDef.name, scriptDef.key, table.concat(modifiers, ","))
            obj.hyper:bind(modifiers, scriptDef.key, nil, function()
                log:debug("Script shortcut triggered: %s", scriptDef.name)
                obj.EventBus:emit("script:execute", {
                    type = scriptDef.type or "shell",
                    script_path = scriptDef.script_path,
                    script_inline = scriptDef.script_inline,
                    args = scriptDef.args,
                    name = scriptDef.name
                })
            end)
        end
    end

    obj.hyperTap = modules.HyperKey.setupEventTap(
        config.hyperConfig,
        obj.hyperKeyState,
        obj.hyper,
        obj.registeredKeys,
        obj.registeredModifierKeys,
        obj.EventBus
    )
end

function Bootstrap.createMenuBar(obj, modules, log)
    if not obj.menuBar then
        obj.menuBar = hs.menubar.new()
        if obj.menuBar then
            obj.menuBar:setTitle("✧")
            obj.menuBar:setTooltip("HyperkeyHub - ✧ (Hyper) Key-based App Launcher")
            obj.menuBar:setMenu(function()
                return {
                    {
                        title = "⚙️ Settings...",
                        tooltip = "Shortcut: ✧+,",
                        fn = function()
                            modules.SettingsUI.showSettings(
                                obj,
                                function(config) return modules.ConfigLoader.saveSettings(config) end,
                                function(obj)
                                    log:alert("✅ Settings saved. Reloading Hammerspoon...")
                                    if obj.settingsWindow then
                                        obj.settingsWindow:delete()
                                        obj.settingsWindow = nil
                                    end
                                    hs.timer.doAfter(1, function() hs.reload() end)
                                end
                            )
                        end
                    },
                    {
                        title = "-"
                    },
                    {
                        title = "About HyperkeyHub",
                        fn = function()
                            log:alert("HyperkeyHub v" .. obj.version .. "\nby " .. obj.author, 3)
                        end
                    }
                }
            end)
        end
    end
end

return Bootstrap
