-- Configuration loader module
-- Main entry point for configuration management

---@class ConfigLoader
---@field defaults table Default configuration
---@field _customConfigPath string|nil Custom configuration file path
local ConfigLoader = {}

--- Custom configuration file path (nil = use default)
ConfigLoader._customConfigPath = nil

local moduleDir = debug.getinfo(1, "S").source:match("@(.*/)")
local function requireModule(name)
    local fullPath = moduleDir .. name .. ".lua"
    return dofile(fullPath)
end

local function requireConfigModule(name)
    local fullPath = moduleDir .. "config/" .. name .. ".lua"
    return dofile(fullPath)
end

local Logger = requireModule("logger")
local TableUtils = requireModule("utils/table_utils")
local FileUtils = requireModule("utils/file_utils")
local log = Logger.new("ConfigLoader")

local defaults = requireConfigModule("defaults")
local Validator = requireConfigModule("validator")
local BackupManager = requireConfigModule("backup_manager")
local Migrator = requireConfigModule("migrations")

ConfigLoader.defaults = defaults

--- Get configuration file path
--- Returns custom path if set, otherwise returns template file path (read-only)
--- @return string path Configuration file path
function ConfigLoader.getConfigPath()
    if ConfigLoader._customConfigPath then
        return ConfigLoader._customConfigPath
    end
    -- Default to template file (read-only)
    return hs.spoons.resourcePath("resources/config_templates/default_config.json")
end

-- Public API

--- Load configuration with defaults
--- Returns a new config table with defaults applied
--- @return table|nil config Configuration table, or nil on error
--- @return string|nil error Error message if load failed
function ConfigLoader.loadWithDefaults()
    local config = TableUtils.deepCopy(defaults)
    return ConfigLoader.loadConfigFile(config)
end

--- Load config file and merge with provided config
--- @param config table Base configuration (usually defaults)
--- @return table|nil config Merged configuration, or nil on error
--- @return string|nil error Error message if load failed
function ConfigLoader.loadConfigFile(config)
    local configPath = ConfigLoader.getConfigPath()

    -- File must exist (created by bootstrap.setupConfigDirectory())
    local content, err = FileUtils.readFile(configPath)
    if not content then
        local errorMsg = string.format("Failed to read config file (%s): %s", configPath, err or "unknown error")
        log:error(errorMsg)
        return nil, errorMsg
    end

    -- Try to parse JSON
    local success, savedConfig, decodeErr = pcall(hs.json.decode, content)
    if not success then
        local errorMsg = string.format("Failed to parse config file (invalid JSON): %s", tostring(savedConfig))
        log:error(errorMsg)
        return nil, errorMsg
    end
    -- dkjson returns nil, err on failure without throwing error
    if not savedConfig then
        local errorMsg = string.format("Failed to parse config file (invalid JSON): %s", tostring(decodeErr) or "unknown error")
        log:error(errorMsg)
        return nil, errorMsg
    end

    -- Check and perform migration if needed
    if Migrator.needsMigration(savedConfig) then
        local oldVersion = Migrator.getSchemaVersion(savedConfig)
        log:info("Migrating config from schema v%d to v%d", oldVersion, Migrator.CURRENT_SCHEMA_VERSION)

        savedConfig = Migrator.migrate(
            savedConfig,
            oldVersion,
            Migrator.CURRENT_SCHEMA_VERSION,
            BackupManager,
            log,
            configPath
        )

        -- Save migrated config
        local migratedJson = hs.json.encode(savedConfig)
        local configPath = ConfigLoader.getConfigPath()
        local file = io.open(configPath, "w")
        if file then
            file:write(migratedJson)
            file:close()
            log:info("Migrated config saved to: %s", configPath)
        else
            log:warn("Failed to save migrated config to: %s", configPath)
        end
    end

    -- Load JSON config
    if savedConfig.hyperKeyCode then
        config.hyperConfig.keyCode = savedConfig.hyperKeyCode
    end

    if savedConfig.applications then
        config.appConfig.applications = savedConfig.applications
    end

    if savedConfig.system_shortcuts then
        config.systemConfig.systemShortcuts = savedConfig.system_shortcuts
    end

    if savedConfig.script_shortcuts then
        config.scriptConfig.scriptShortcuts = savedConfig.script_shortcuts
    end

    if savedConfig.showAlerts ~= nil then
        -- Backward compatibility: convert boolean to string
        if savedConfig.showAlerts == true then
            config.showAlerts = "all"
        elseif savedConfig.showAlerts == false then
            config.showAlerts = "none"
        else
            config.showAlerts = savedConfig.showAlerts
        end
    end

    local scriptShortcutCount = 0
    for _ in pairs(config.scriptConfig.scriptShortcuts) do
        scriptShortcutCount = scriptShortcutCount + 1
    end

    local systemShortcutCount = 0
    for _ in pairs(config.systemConfig.systemShortcuts) do
        systemShortcutCount = systemShortcutCount + 1
    end

    log:debug("Loaded config: hyperKeyCode=%s, %d apps, %d system shortcuts, %d script shortcuts",
        tostring(config.hyperConfig.keyCode),
        type(savedConfig.applications) == "table" and #savedConfig.applications or 0,
        systemShortcutCount,
        scriptShortcutCount
    )

    return config, nil
end

--- Apply configuration override from init.lua config parameter
--- @param config table Current configuration
--- @param configuration table|nil Optional override config from init
--- @return table config Updated configuration
function ConfigLoader.applyConfigOverride(config, configuration)
    if not configuration then
        return config
    end

    if configuration.hyperKeyCode then
        config.hyperConfig.keyCode = configuration.hyperKeyCode
    end

    if configuration.applications then
        config.appConfig.applications = TableUtils.deepMerge(config.appConfig.applications, configuration.applications)
    end

    if configuration.systemConfig then
        if configuration.systemConfig.defaultSystemShortcuts then
            config.systemConfig.defaultSystemShortcuts = TableUtils.deepMerge(
                config.systemConfig.defaultSystemShortcuts,
                configuration.systemConfig.defaultSystemShortcuts
            )
        end
        if configuration.systemConfig.systemShortcuts then
            config.systemConfig.systemShortcuts = TableUtils.deepMerge(
                config.systemConfig.systemShortcuts,
                configuration.systemConfig.systemShortcuts
            )
        end
    end

    if configuration.scriptConfig then
        if configuration.scriptConfig.scriptShortcuts then
            config.scriptConfig.scriptShortcuts = TableUtils.deepMerge(
                config.scriptConfig.scriptShortcuts,
                configuration.scriptConfig.scriptShortcuts
            )
        end
    end

    return config
end

--- Save settings to config file
--- @param configJson string JSON string of configuration
--- @return boolean success True if save succeeded
function ConfigLoader.saveSettings(configJson)
    local success, config = pcall(hs.json.decode, configJson)
    if not success then
        log:alert("❌ Invalid JSON format")
        log:error("Failed to parse settings JSON: %s", tostring(config))
        return false
    end

    -- Validate the configuration
    local valid, err = Validator.validateConfig(config)
    if not valid then
        log:alert(string.format("❌ Invalid configuration: %s", err))
        log:error("Validation failed: %s", err)
        return false
    end

    local configPath = ConfigLoader.getConfigPath()

    -- Check if trying to save to template file (read-only)
    local templatePath = hs.spoons.resourcePath("resources/config_templates/default_config.json")
    if configPath == templatePath then
        local errorMsg = [[❌ Configuration Path Not Set

Cannot save settings to the default template file.

To save your settings, please add the following to ~/.hammerspoon/init.lua:

spoon.HyperkeyHub.configPath = os.getenv("HOME") .. "/.hammerspoon/HyperkeyHub/config.json"

Then run these commands:
mkdir -p ~/.hammerspoon/HyperkeyHub
cp ]] .. templatePath .. [[ \
   ~/.hammerspoon/HyperkeyHub/config.json

After that, reload Hammerspoon to apply the changes.]]
        log:alert(errorMsg, 15)
        log:error("Attempted to save to template file: %s", configPath)
        return false
    end

    BackupManager.createBackup(configPath)

    local file = io.open(configPath, "w")
    if not file then
        log:alert("❌ Failed to open config file for writing")
        log:error("Cannot write to: %s", configPath)
        return false
    end

    file:write(configJson)
    file:close()

    log:info("Config saved to: %s", configPath)
    log:alert("✅ Settings saved successfully", 2)

    return true
end

ConfigLoader.listBackups = BackupManager.listBackups
ConfigLoader.cleanupOldBackups = BackupManager.cleanupOldBackups
ConfigLoader.restoreFromBackup = BackupManager.restoreFromBackup

return ConfigLoader
