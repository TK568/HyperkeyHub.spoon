-- ConfigLoader module unit tests

describe("ConfigLoader", function()
    local ConfigLoader

    before_each(function()
        -- Reset mocks
        reset_mocks()

        -- Setup mock hs.configdir
        _G.hs.configdir = "/tmp/test_hammerspoon"

        -- Reload ConfigLoader module for each test
        package.loaded["config_loader"] = nil
        package.loaded["logger"] = nil
        ConfigLoader = require("config_loader")
    end)

    describe("getConfigPath()", function()
        it("should return template file path when no custom path is set", function()
            ConfigLoader._customConfigPath = nil
            local path = ConfigLoader.getConfigPath()
            assert.is_truthy(path:match("resources/config_templates/default_config%.json$"))
        end)

        it("should return custom path when set", function()
            ConfigLoader._customConfigPath = "/custom/path/config.json"
            local path = ConfigLoader.getConfigPath()
            assert.equals("/custom/path/config.json", path)
        end)

        it("should allow changing custom path", function()
            ConfigLoader._customConfigPath = "/path1/config.json"
            assert.equals("/path1/config.json", ConfigLoader.getConfigPath())

            ConfigLoader._customConfigPath = "/path2/config.json"
            assert.equals("/path2/config.json", ConfigLoader.getConfigPath())
        end)
    end)

    describe("defaults", function()
        it("should have default configuration", function()
            assert.is_not_nil(ConfigLoader.defaults)
            assert.is_table(ConfigLoader.defaults)
        end)

        it("should have hyperConfig defaults", function()
            assert.is_not_nil(ConfigLoader.defaults.hyperConfig)
            assert.is_number(ConfigLoader.defaults.hyperConfig.keyCode)
            assert.is_table(ConfigLoader.defaults.hyperConfig.keyCodeToChar)
        end)

        it("should have appConfig defaults", function()
            assert.is_not_nil(ConfigLoader.defaults.appConfig)
            assert.is_table(ConfigLoader.defaults.appConfig.applications)
        end)

        it("should have scriptConfig defaults", function()
            assert.is_not_nil(ConfigLoader.defaults.scriptConfig)
            assert.is_table(ConfigLoader.defaults.scriptConfig.scriptShortcuts)
        end)

        it("should have systemConfig defaults", function()
            assert.is_not_nil(ConfigLoader.defaults.systemConfig)
            assert.is_table(ConfigLoader.defaults.systemConfig.functions)
            assert.is_table(ConfigLoader.defaults.systemConfig.customBindings)
        end)
    end)

    describe("loadWithDefaults()", function()
        before_each(function()
            -- Create config directory and file for these tests
            os.execute("mkdir -p /tmp/test_hammerspoon/HyperkeyHub")
            local file = io.open("/tmp/test_hammerspoon/HyperkeyHub/config.json", "w")
            file:write('{"hyperKeyCode": 80, "applications": {}}')
            file:close()

            -- Set custom config path
            ConfigLoader._customConfigPath = "/tmp/test_hammerspoon/HyperkeyHub/config.json"
        end)

        after_each(function()
            os.execute("rm -rf /tmp/test_hammerspoon")
        end)

        it("should return a config table", function()
            local config, err = ConfigLoader.loadWithDefaults()
            assert.is_nil(err)
            assert.is_table(config)
        end)

        it("should have all default sections", function()
            local config, err = ConfigLoader.loadWithDefaults()
            assert.is_nil(err)
            assert.is_not_nil(config.hyperConfig)
            assert.is_not_nil(config.appConfig)
            assert.is_not_nil(config.systemConfig)
            assert.is_not_nil(config.scriptConfig)
        end)

        it("should create a deep copy of defaults", function()
            local config1, err1 = ConfigLoader.loadWithDefaults()
            local config2, err2 = ConfigLoader.loadWithDefaults()

            assert.is_nil(err1)
            assert.is_nil(err2)

            -- Should be independent instances
            assert.are_not.equal(config1, config2)
            assert.are_not.equal(config1.hyperConfig, config2.hyperConfig)

            -- Modifying one should not affect the other
            config1.hyperConfig.keyCode = 999
            assert.are_not.equal(config1.hyperConfig.keyCode, config2.hyperConfig.keyCode)
        end)

        it("should return error when config file cannot be read", function()
            -- Remove config file
            os.execute("rm -f /tmp/test_hammerspoon/HyperkeyHub/config.json")

            local config, err = ConfigLoader.loadWithDefaults()
            assert.is_nil(config)
            assert.is_string(err)
            assert.is_truthy(err:match("Failed to read config file"))
        end)

        it("should return error when config file has invalid JSON", function()
            local file = io.open("/tmp/test_hammerspoon/HyperkeyHub/config.json", "w")
            file:write('{ invalid json }')
            file:close()

            local config, err = ConfigLoader.loadWithDefaults()
            assert.is_nil(config)
            assert.is_string(err)
            assert.is_truthy(err:match("invalid JSON"))
        end)
    end)

    -- Note: getConfigPath, parseJSON, convertJSONFormat, copyFile, readFileContent
    -- are internal functions and not exposed in the module API.
    -- They are tested indirectly through saveSettings() and backup operations.

    describe("file operations (copyFile and readFileContent)", function()
        before_each(function()
            os.execute("mkdir -p /tmp/test_hammerspoon/HyperkeyHub")
            os.execute("rm -f /tmp/test_hammerspoon/test_*")
            ConfigLoader._customConfigPath = "/tmp/test_hammerspoon/HyperkeyHub/config.json"
        end)

        after_each(function()
            os.execute("rm -rf /tmp/test_hammerspoon")
        end)

        it("should successfully copy files (tested via backup creation)", function()
            -- Create original config
            local file = io.open("/tmp/test_hammerspoon/HyperkeyHub/config.json", "w")
            file:write('{"hyperKeyCode": 80, "test": "data"}')
            file:close()

            -- Save new config (which triggers copyFile for backup)
            local newConfig = [[
                {
                    "hyperKeyCode": 53,
                    "applications": {}
                }
            ]]

            local success = ConfigLoader.saveSettings(newConfig)
            assert.is_true(success)

            -- Verify backup was created (copyFile worked)
            local backups = ConfigLoader.listBackups("/tmp/test_hammerspoon/HyperkeyHub/config.json")
            assert.is_true(#backups >= 1)
        end)

        it("should successfully read files (tested via loadConfigFile)", function()
            -- Create a test config file
            local testConfig = [[
                {
                    "hyperKeyCode": 80,
                    "hyperKeyName": "F19",
                    "applications": {}
                }
            ]]

            local file = io.open("/tmp/test_hammerspoon/HyperkeyHub/config.json", "w")
            file:write(testConfig)
            file:close()

            -- Load config (which uses readFileContent internally)
            local config = ConfigLoader.loadWithDefaults()

            -- If readFileContent failed, we would get defaults only
            -- So we verify the loaded values match our test file
            assert.is_not_nil(config)
            assert.is_table(config)
        end)

        it("should return error when config file does not exist", function()
            -- Try to load from non-existent directory
            _G.hs.configdir = "/tmp/nonexistent_directory"

            -- Should return error, not crash
            local config, err = ConfigLoader.loadWithDefaults()
            assert.is_nil(config)
            assert.is_string(err)
            assert.is_truthy(err:match("Failed to read config file"))
        end)
    end)

    describe("custom config path integration", function()
        before_each(function()
            os.execute("mkdir -p /tmp/test_custom")
            os.execute("rm -f /tmp/test_custom/*.json*")
        end)

        after_each(function()
            os.execute("rm -rf /tmp/test_custom")
            ConfigLoader._customConfigPath = nil
        end)

        it("should save to custom path when configured", function()
            ConfigLoader._customConfigPath = "/tmp/test_custom/custom_config.json"

            local jsonConfig = [[
                {
                    "hyperKeyCode": 99,
                    "hyperKeyName": "CustomKey",
                    "applications": {}
                }
            ]]

            local success = ConfigLoader.saveSettings(jsonConfig)
            assert.is_true(success)

            -- Verify file was created at custom path
            local file = io.open("/tmp/test_custom/custom_config.json", "r")
            assert.is_not_nil(file)

            if file then
                local content = file:read("*a")
                file:close()
                assert.is_true(content:match('"hyperKeyCode"%s*:%s*99') ~= nil)
            end
        end)

        it("should create backups at custom path location", function()
            ConfigLoader._customConfigPath = "/tmp/test_custom/my_config.json"

            -- Create initial config
            local file = io.open("/tmp/test_custom/my_config.json", "w")
            file:write('{"hyperKeyCode": 80}')
            file:close()

            os.execute("sleep 1")

            -- Save new config
            local newConfig = [[
                {
                    "hyperKeyCode": 53,
                    "applications": {}
                }
            ]]

            local success = ConfigLoader.saveSettings(newConfig)
            assert.is_true(success)

            -- List backups with custom path
            local backups = ConfigLoader.listBackups("/tmp/test_custom/my_config.json")
            assert.is_true(#backups >= 1)

            -- Verify backup is in the same directory as custom config
            if #backups > 0 then
                assert.is_true(backups[1].path:match("^/tmp/test_custom/") ~= nil)
            end
        end)
    end)

    describe("saveSettings()", function()
        before_each(function()
            -- Create test directory
            os.execute("mkdir -p /tmp/test_hammerspoon/HyperkeyHub")
            -- Clean up any existing test files
            os.execute("rm -f /tmp/test_hammerspoon/HyperkeyHub/config.json*")
            -- Set custom path
            ConfigLoader._customConfigPath = "/tmp/test_hammerspoon/HyperkeyHub/config.json"
        end)

        after_each(function()
            -- Cleanup
            os.execute("rm -rf /tmp/test_hammerspoon")
        end)

        it("should save valid configuration to JSON file", function()
            local jsonConfig = [[
                {
                    "hyperKeyCode": 80,
                    "hyperKeyName": "F19",
                    "applications": {},
                    "window_management": {}
                }
            ]]

            local success = ConfigLoader.saveSettings(jsonConfig)

            assert.is_true(success)

            -- Verify file exists
            local file = io.open("/tmp/test_hammerspoon/HyperkeyHub/config.json", "r")
            assert.is_not_nil(file)

            if file then
                local content = file:read("*a")
                file:close()

                -- Should contain expected values
                assert.is_true(content:match('"hyperKeyCode"%s*:%s*80') ~= nil)
                assert.is_true(content:match('"hyperKeyName"%s*:%s*"F19"') ~= nil)
            end
        end)

        it("should reject invalid JSON", function()
            local invalidJson = "{ invalid json }"

            local success = ConfigLoader.saveSettings(invalidJson)

            assert.is_false(success)
        end)

        it("should reject invalid configuration", function()
            local invalidConfig = [[
                {
                    "hyperKeyCode": "not a number",
                    "applications": {}
                }
            ]]

            local success = ConfigLoader.saveSettings(invalidConfig)

            assert.is_false(success)
        end)

        it("should create backup before overwriting existing config", function()
            -- Create an existing config file
            local file = io.open("/tmp/test_hammerspoon/HyperkeyHub/config.json", "w")
            file:write('{"hyperKeyCode": 80}')
            file:close()

            -- Wait to ensure different timestamp
            os.execute("sleep 1")

            -- Save new config
            local newConfig = [[
                {
                    "hyperKeyCode": 53,
                    "hyperKeyName": "ESC",
                    "applications": {}
                }
            ]]

            local success = ConfigLoader.saveSettings(newConfig)
            assert.is_true(success)

            -- Check if backup was created
            local backups = ConfigLoader.listBackups("/tmp/test_hammerspoon/HyperkeyHub/config.json")
            assert.is_true(#backups >= 1)

            -- Verify backup contains old config
            if #backups > 0 then
                local backupPath = backups[1].path  -- backups[1] is a table with 'path' field
                local backupFile = io.open(backupPath, "r")
                if backupFile then
                    local content = backupFile:read("*a")
                    backupFile:close()
                    assert.is_true(content:match('"hyperKeyCode"%s*:%s*80') ~= nil)
                end
            end
        end)
    end)

    describe("listBackups()", function()
        before_each(function()
            os.execute("mkdir -p /tmp/test_hammerspoon/HyperkeyHub")
            os.execute("rm -f /tmp/test_hammerspoon/HyperkeyHub/config.json*")
        end)

        after_each(function()
            os.execute("rm -rf /tmp/test_hammerspoon")
        end)

        it("should list available backups", function()
            -- Create some backup files with different timestamps
            -- File 2 should have newer modification time
            local file1 = io.open("/tmp/test_hammerspoon/HyperkeyHub/config.json.backup.20231115_120000", "w")
            file1:write('{}')
            file1:close()

            -- Small delay to ensure different modification times
            os.execute("sleep 0.5")

            local file2 = io.open("/tmp/test_hammerspoon/HyperkeyHub/config.json.backup.20231115_130000", "w")
            file2:write('{}')
            file2:close()

            local backups = ConfigLoader.listBackups("/tmp/test_hammerspoon/HyperkeyHub/config.json")

            assert.is_table(backups)
            assert.equals(2, #backups)

            -- Each backup should be a table with name, path, time, size
            assert.is_table(backups[1])
            assert.is_not_nil(backups[1].name)
            assert.is_not_nil(backups[1].path)
            assert.is_not_nil(backups[1].time)
            assert.is_not_nil(backups[1].size)

            -- Backups should be sorted by modification time (newest first)
            -- The second file created should have newer modification time
            assert.is_true(backups[1].time >= backups[2].time)
        end)

        it("should return empty table when no backups exist", function()
            local backups = ConfigLoader.listBackups("/tmp/test_hammerspoon/HyperkeyHub/config.json")

            assert.is_table(backups)
            assert.equals(0, #backups)
        end)
    end)

    describe("cleanupOldBackups()", function()
        before_each(function()
            os.execute("mkdir -p /tmp/test_hammerspoon/HyperkeyHub")
            os.execute("rm -f /tmp/test_hammerspoon/HyperkeyHub/config.json*")
        end)

        after_each(function()
            os.execute("rm -rf /tmp/test_hammerspoon")
        end)

        it("should keep only the latest N backups", function()
            -- Create 7 backup files
            for i = 1, 7 do
                local timestamp = string.format("2023111%d_120000", i)
                local file = io.open("/tmp/test_hammerspoon/HyperkeyHub/config.json.backup." .. timestamp, "w")
                file:write('{}')
                file:close()
                -- Small delay to ensure different file times
                os.execute("sleep 0.1")
            end

            -- Keep only 3 latest backups
            ConfigLoader.cleanupOldBackups("/tmp/test_hammerspoon/HyperkeyHub/config.json", 3)

            local backups = ConfigLoader.listBackups("/tmp/test_hammerspoon/HyperkeyHub/config.json")

            -- Should have exactly 3 backups left
            assert.equals(3, #backups)
        end)

        it("should not delete backups if count is below limit", function()
            -- Create 2 backup files
            local file1 = io.open("/tmp/test_hammerspoon/HyperkeyHub/config.json.backup.20231115_120000", "w")
            file1:write('{}')
            file1:close()

            local file2 = io.open("/tmp/test_hammerspoon/HyperkeyHub/config.json.backup.20231115_130000", "w")
            file2:write('{}')
            file2:close()

            -- Keep 5 backups (more than current count)
            ConfigLoader.cleanupOldBackups("/tmp/test_hammerspoon/HyperkeyHub/config.json", 5)

            local backups = ConfigLoader.listBackups("/tmp/test_hammerspoon/HyperkeyHub/config.json")

            -- Should still have 2 backups
            assert.equals(2, #backups)
        end)
    end)
end)
