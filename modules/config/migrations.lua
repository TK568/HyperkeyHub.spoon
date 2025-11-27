-- Schema migration module
-- Handles automatic migration of configuration files between schema versions

---@class Migrator
local Migrator = {}

-- Current schema version
Migrator.CURRENT_SCHEMA_VERSION = 1

-- Migration functions table
-- migrations[N] performs migration from version N to N+1
-- Example:
-- migrations[1] = function(config)
--     -- Migrate from v1 to v2
--     if config.old_field then
--         config.new_field = config.old_field
--         config.old_field = nil
--     end
--     return config
-- end
local migrations = {
    -- Future migrations will be added here
}

--- Check if migration is needed
--- @param config table Configuration object
--- @return boolean needsMigration True if migration is needed
function Migrator.needsMigration(config)
    if not config then
        return false
    end

    local currentVersion = config.schema_version or 1
    return currentVersion < Migrator.CURRENT_SCHEMA_VERSION
end

--- Perform migration from one version to another
--- @param config table Configuration to migrate
--- @param fromVersion number Starting schema version
--- @param toVersion number Target schema version
--- @param backupManager table BackupManager instance for creating backups
--- @param logger table Logger instance for logging
--- @param configPath string|nil Configuration file path (uses default if nil)
--- @return table migratedConfig Migrated configuration
function Migrator.migrate(config, fromVersion, toVersion, backupManager, logger, configPath)
    if not config then
        logger:error("Cannot migrate nil config")
        return config
    end

    if fromVersion >= toVersion then
        logger:debug("No migration needed: current=%d, target=%d", fromVersion, toVersion)
        return config
    end

    -- Create backup before migration
    configPath = configPath or (hs.configdir .. "/HyperkeyHub/config.json")
    local backupReason = string.format("before_migration_v%d_to_v%d", fromVersion, toVersion)
    local success, backupPath = pcall(backupManager.createBackup, configPath, backupReason)

    if success and backupPath then
        logger:info("Created migration backup: %s", backupPath)
    else
        logger:warn("Failed to create migration backup: %s", tostring(backupPath))
    end

    -- Perform migrations step by step
    local migratedConfig = config
    for version = fromVersion, toVersion - 1 do
        if migrations[version] then
            logger:info("Applying migration: v%d -> v%d", version, version + 1)

            local success, result = pcall(migrations[version], migratedConfig)
            if not success then
                logger:error("Migration failed at version %d: %s", version, tostring(result))
                logger:alert(string.format("❌ Migration failed at v%d. Backup saved.", version))
                return config  -- Return original config on failure
            end

            migratedConfig = result
            migratedConfig.schema_version = version + 1
        else
            -- No migration function for this version, just update version number
            logger:debug("No migration function for v%d -> v%d, updating version only", version, version + 1)
            migratedConfig.schema_version = version + 1
        end
    end

    logger:info("Migration completed: v%d -> v%d", fromVersion, toVersion)
    logger:alert(string.format("✅ Config migrated to schema v%d", toVersion), 2)

    return migratedConfig
end

--- Get current schema version from config
--- @param config table Configuration object
--- @return number version Current schema version (defaults to 1)
function Migrator.getSchemaVersion(config)
    if not config then
        return 1
    end
    return config.schema_version or 1
end

return Migrator
