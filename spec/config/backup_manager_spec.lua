describe("BackupManager", function()
    local BackupManager
    local testDir
    local testConfigPath

    before_each(function()
        reset_mocks()
        package.loaded["config.backup_manager"] = nil

        testDir = "/tmp/hyperkeyhub_test_" .. os.time() .. "/"
        testConfigPath = testDir .. "config.json"

        os.execute("mkdir -p " .. testDir)

        local testConfig = '{"hyperKeyCode":79}'
        local f = io.open(testConfigPath, "w")
        if f then
            f:write(testConfig)
            f:close()
        end

        _G.hs.configdir = testDir

        BackupManager = require("config.backup_manager")
    end)

    after_each(function()
        os.execute("rm -rf " .. testDir)
    end)

    describe("listBackups", function()
        it("returns empty table when no backups exist", function()
            local backups = BackupManager.listBackups(testConfigPath)
            assert.equals(0, #backups)
        end)

        it("lists all backup files sorted by modification time", function()
            local backup1 = testConfigPath .. ".backup.20240101_120000"
            local backup2 = testConfigPath .. ".backup.20240101_130000"
            local backup3 = testConfigPath .. ".backup.20240101_140000"

            local f1 = io.open(backup1, "w")
            f1:write("backup1")
            f1:close()
            os.execute("touch -t 202401011200 " .. backup1)

            local f2 = io.open(backup2, "w")
            f2:write("backup2")
            f2:close()
            os.execute("touch -t 202401011300 " .. backup2)

            local f3 = io.open(backup3, "w")
            f3:write("backup3")
            f3:close()
            os.execute("touch -t 202401011400 " .. backup3)

            local backups = BackupManager.listBackups(testConfigPath)

            assert.equals(3, #backups)
            assert.equals("config.json.backup.20240101_140000", backups[1].name)
            assert.equals("config.json.backup.20240101_130000", backups[2].name)
            assert.equals("config.json.backup.20240101_120000", backups[3].name)
        end)

        it("includes backup metadata (name, path, time, size)", function()
            local backup1 = testConfigPath .. ".backup.20240101_120000"
            local f1 = io.open(backup1, "w")
            f1:write("test backup content")
            f1:close()

            local backups = BackupManager.listBackups(testConfigPath)

            assert.equals(1, #backups)
            assert.equals("config.json.backup.20240101_120000", backups[1].name)
            assert.is_not_nil(backups[1].path)
            assert.is_not_nil(backups[1].time)
            assert.is_not_nil(backups[1].size)
            assert.is_true(backups[1].size > 0)
        end)

        it("throws error when configPath is nil", function()
            assert.has_error(function()
                BackupManager.listBackups(nil)
            end, "Configuration file path is required")
        end)
    end)

    describe("createBackup", function()
        it("creates a backup file with timestamp", function()
            local success = BackupManager.createBackup(testConfigPath)

            assert.is_true(success)

            local backups = BackupManager.listBackups(testConfigPath)
            assert.equals(1, #backups)
            assert.matches("config.json.backup.%d+_%d+", backups[1].name)
        end)

        it("preserves original file content in backup", function()
            local originalContent = '{"hyperKeyCode":79,"test":"value"}'
            local f = io.open(testConfigPath, "w")
            f:write(originalContent)
            f:close()

            BackupManager.createBackup(testConfigPath)

            local backups = BackupManager.listBackups(testConfigPath)
            local backupFile = io.open(backups[1].path, "r")
            local backupContent = backupFile:read("*a")
            backupFile:close()

            assert.equals(originalContent, backupContent)
        end)

        it("returns false when source file does not exist", function()
            local nonExistentPath = testDir .. "nonexistent.json"
            local success = BackupManager.createBackup(nonExistentPath)

            assert.is_false(success)
        end)

        it("keeps only 5 most recent backups", function()
            for i = 1, 7 do
                BackupManager.createBackup(testConfigPath)
                os.execute("sleep 1")
            end

            local backups = BackupManager.listBackups(testConfigPath)
            assert.equals(5, #backups)
        end)
    end)

    describe("cleanupOldBackups", function()
        it("removes old backups beyond keepCount", function()
            for i = 1, 5 do
                local backup = testConfigPath .. ".backup.2024010" .. i .. "_120000"
                local f = io.open(backup, "w")
                f:write("backup" .. i)
                f:close()
                os.execute("sleep 0.05")
            end

            BackupManager.cleanupOldBackups(testConfigPath, 3)

            local backups = BackupManager.listBackups(testConfigPath)
            assert.equals(3, #backups)
        end)

        it("keeps the most recent backups", function()
            local backup1 = testConfigPath .. ".backup.20240101_120000"
            local backup2 = testConfigPath .. ".backup.20240102_120000"
            local backup3 = testConfigPath .. ".backup.20240103_120000"

            local f1 = io.open(backup1, "w")
            f1:write("old")
            f1:close()
            os.execute("touch -t 202401011200 " .. backup1)

            local f2 = io.open(backup2, "w")
            f2:write("middle")
            f2:close()
            os.execute("touch -t 202401021200 " .. backup2)

            local f3 = io.open(backup3, "w")
            f3:write("newest")
            f3:close()
            os.execute("touch -t 202401031200 " .. backup3)

            BackupManager.cleanupOldBackups(testConfigPath, 2)

            local backups = BackupManager.listBackups(testConfigPath)
            assert.equals(2, #backups)
            assert.equals("config.json.backup.20240103_120000", backups[1].name)
            assert.equals("config.json.backup.20240102_120000", backups[2].name)
        end)

        it("does nothing when backup count is below keepCount", function()
            local backup1 = testConfigPath .. ".backup.20240101_120000"
            local f1 = io.open(backup1, "w")
            f1:write("backup")
            f1:close()

            BackupManager.cleanupOldBackups(testConfigPath, 5)

            local backups = BackupManager.listBackups(testConfigPath)
            assert.equals(1, #backups)
        end)
    end)

    describe("restoreFromBackup", function()
        it("restores from the latest backup when backupName is nil", function()
            local originalContent = '{"hyperKeyCode":79}'
            local f = io.open(testConfigPath, "w")
            f:write(originalContent)
            f:close()

            BackupManager.createBackup(testConfigPath)

            local modifiedContent = '{"hyperKeyCode":80}'
            local f2 = io.open(testConfigPath, "w")
            f2:write(modifiedContent)
            f2:close()

            local success = BackupManager.restoreFromBackup(nil, testConfigPath)
            assert.is_true(success)

            local restored = io.open(testConfigPath, "r")
            local restoredContent = restored:read("*a")
            restored:close()

            assert.equals(originalContent, restoredContent)
        end)

        it("restores from specified backup", function()
            local content1 = '{"version":1}'
            local f1 = io.open(testConfigPath, "w")
            f1:write(content1)
            f1:close()

            BackupManager.createBackup(testConfigPath)
            os.execute("sleep 1")

            local content2 = '{"version":2}'
            local f2 = io.open(testConfigPath, "w")
            f2:write(content2)
            f2:close()

            BackupManager.createBackup(testConfigPath)
            os.execute("sleep 1")

            local allBackups = BackupManager.listBackups(testConfigPath)
            local firstBackupName = allBackups[#allBackups].name

            local f3 = io.open(testConfigPath, "w")
            f3:write('{"version":3}')
            f3:close()

            local success = BackupManager.restoreFromBackup(firstBackupName, testConfigPath)
            assert.is_true(success)

            local restored = io.open(testConfigPath, "r")
            local restoredContent = restored:read("*a")
            restored:close()

            assert.equals(content1, restoredContent)
        end)

        it("returns false when no backups exist", function()
            local success = BackupManager.restoreFromBackup(nil, testConfigPath)
            assert.is_false(success)
        end)

        it("returns false when specified backup does not exist", function()
            BackupManager.createBackup(testConfigPath)

            local success = BackupManager.restoreFromBackup("nonexistent.backup", testConfigPath)
            assert.is_false(success)
        end)
    end)
end)
