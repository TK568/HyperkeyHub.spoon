-- Backup manager module
-- Manages configuration backup creation, listing, and restoration

local moduleDir = debug.getinfo(1, "S").source:match("@(.*/)")
local function requireModule(name)
    local fullPath = moduleDir .. "../" .. name .. ".lua"
    return dofile(fullPath)
end
local Logger = requireModule("logger")
local log = Logger.new("BackupManager")

local BackupManager = {}

-- Safe file copy function using Lua's io operations
-- Avoids command injection risks associated with os.execute()
---@param src string Source file path
---@param dest string Destination file path
---@return boolean success True if copy succeeded
---@return string|nil error Error message if failed
local function copyFile(src, dest)
    local srcFile, err = io.open(src, "rb")
    if not srcFile then
        return false, "Cannot open source: " .. tostring(err)
    end

    local content = srcFile:read("*a")
    srcFile:close()

    local destFile, err = io.open(dest, "wb")
    if not destFile then
        return false, "Cannot open destination: " .. tostring(err)
    end

    destFile:write(content)
    destFile:close()
    return true
end

--- List all available backups
--- @param configPath string Configuration file path (required)
--- @return table[] backups Array of backup info tables {name, path, time, size}
function BackupManager.listBackups(configPath)
    if not configPath then
        error("Configuration file path is required")
    end
    local configDir = configPath:match("(.*/)")
    local configName = configPath:match(".*/(.+)$")
    local backupPattern = configName .. ".backup."

    local backups = {}
    for file in hs.fs.dir(configDir) do
        if file:match("^" .. backupPattern) then
            local fullPath = configDir .. file
            local attrs = hs.fs.attributes(fullPath)
            if attrs then
                table.insert(backups, {
                    name = file,
                    path = fullPath,
                    time = attrs.modification,
                    size = attrs.size
                })
            end
        end
    end

    table.sort(backups, function(a, b) return a.time > b.time end)

    return backups
end

--- Clean up old backups, keeping only the latest N
--- @param configPath string Path to the config file
--- @param keepCount number Number of backups to keep
function BackupManager.cleanupOldBackups(configPath, keepCount)
    local configDir = configPath:match("(.*/)")
    local configName = configPath:match(".*/(.+)$")
    local backupPattern = configName .. ".backup."

    local backups = {}
    for file in hs.fs.dir(configDir) do
        if file:match("^" .. backupPattern) then
            local fullPath = configDir .. file
            local attrs = hs.fs.attributes(fullPath)
            if attrs then
                table.insert(backups, {
                    path = fullPath,
                    time = attrs.modification
                })
            end
        end
    end

    table.sort(backups, function(a, b) return a.time > b.time end)

    for i = keepCount + 1, #backups do
        os.remove(backups[i].path)
        log:debug("Removed old backup: %s", backups[i].path)
    end
end

--- Create a backup of the config file
--- @param configPath string Path to the config file
--- @return boolean success True if backup was created
function BackupManager.createBackup(configPath)
    if hs.fs.attributes(configPath) then
        local timestamp = os.date("%Y%m%d_%H%M%S")
        local backupPath = configPath .. ".backup." .. timestamp
        local copySuccess, copyErr = copyFile(configPath, backupPath)

        if copySuccess then
            log:info("Config backup created: %s", backupPath)
            -- Keep only the latest 5 backups
            BackupManager.cleanupOldBackups(configPath, 5)
            return true
        else
            log:warn("Failed to create config backup: %s", copyErr or "unknown error")
            return false
        end
    end
    return false
end

--- Restore configuration from the latest or specified backup
--- @param backupName string|nil Specific backup filename to restore
--- @param configPath string|nil Configuration file path (uses default if nil)
--- @return boolean success True if restore succeeded
function BackupManager.restoreFromBackup(backupName, configPath)
    configPath = configPath or (hs.configdir .. "/HyperkeyHub/config.json")
    local backups = BackupManager.listBackups(configPath)

    if #backups == 0 then
        log:alert("❌ No backup files found")
        return false
    end

    -- Restore from requested backup or fall back to latest
    local targetBackup = backups[1]
    if backupName then
        for _, backup in ipairs(backups) do
            if backup.name == backupName then
                targetBackup = backup
                break
            end
        end

        if not targetBackup or targetBackup.name ~= backupName then
            log:alert(string.format("❌ Backup \"%s\" not found", backupName))
            return false
        end
    end

    local copySuccess, copyErr = copyFile(targetBackup.path, configPath)

    if copySuccess then
        log:alert(string.format("✅ Config restored from backup: %s", targetBackup.name), 3)
        log:info("Config restored from: %s", targetBackup.path)
        return true
    else
        log:alert(string.format("❌ Failed to restore from backup: %s", copyErr or "unknown error"))
        log:error("Restore failed: %s", copyErr or "unknown error")
        return false
    end
end

return BackupManager
