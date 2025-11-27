-- Test suite for schema migrations

require("spec.helpers.hammerspoon_mock")

describe("Migrator", function()
    local Migrator
    local mockBackupManager
    local mockLogger

    before_each(function()
        -- Load the module
        local moduleDir = debug.getinfo(1, "S").source:match("@(.*/)")
        local migratorPath = moduleDir:gsub("spec/", "") .. "modules/config/migrations.lua"
        Migrator = dofile(migratorPath)

        -- Setup mocks
        mockBackupManager = {
            createBackup = function(path, reason)
                return "/path/to/backup.json"
            end
        }

        mockLogger = {
            info = function(...) end,
            debug = function(...) end,
            warn = function(...) end,
            error = function(...) end,
            alert = function(...) end
        }
    end)

    describe("CURRENT_SCHEMA_VERSION", function()
        it("should be defined and be a number", function()
            assert.is_not_nil(Migrator.CURRENT_SCHEMA_VERSION)
            assert.is_number(Migrator.CURRENT_SCHEMA_VERSION)
        end)

        it("should be 1 (initial version)", function()
            assert.equals(1, Migrator.CURRENT_SCHEMA_VERSION)
        end)
    end)

    describe("getSchemaVersion", function()
        it("should return 1 for nil config", function()
            assert.equals(1, Migrator.getSchemaVersion(nil))
        end)

        it("should return 1 for config without schema_version", function()
            local config = { hyperKeyCode = 80 }
            assert.equals(1, Migrator.getSchemaVersion(config))
        end)

        it("should return the schema_version from config", function()
            local config = { schema_version = 2, hyperKeyCode = 80 }
            assert.equals(2, Migrator.getSchemaVersion(config))
        end)
    end)

    describe("needsMigration", function()
        it("should return false for nil config", function()
            assert.is_false(Migrator.needsMigration(nil))
        end)

        it("should return false when current version matches", function()
            local config = { schema_version = Migrator.CURRENT_SCHEMA_VERSION }
            assert.is_false(Migrator.needsMigration(config))
        end)

        it("should return false when no schema_version field (v1 assumed)", function()
            local config = { hyperKeyCode = 80 }
            assert.is_false(Migrator.needsMigration(config))
        end)

        it("should return true when schema_version is lower", function()
            -- This test is for future versions
            -- When CURRENT_SCHEMA_VERSION becomes 2 or higher, this will be relevant
            local config = { schema_version = 0 }
            assert.is_true(Migrator.needsMigration(config))
        end)
    end)

    describe("migrate", function()
        it("should return original config if nil", function()
            local result = Migrator.migrate(nil, 1, 2, mockBackupManager, mockLogger)
            assert.is_nil(result)
        end)

        it("should return original config if fromVersion >= toVersion", function()
            local config = { schema_version = 2, hyperKeyCode = 80 }
            local result = Migrator.migrate(config, 2, 2, mockBackupManager, mockLogger)
            assert.equals(config, result)

            result = Migrator.migrate(config, 3, 2, mockBackupManager, mockLogger)
            assert.equals(config, result)
        end)

        it("should create backup before migration", function()
            local backupCalled = false
            local testBackupManager = {
                createBackup = function(path, reason)
                    backupCalled = true
                    assert.is_string(path)
                    assert.is_string(reason)
                    assert.matches("before_migration", reason)
                    return "/backup/path.json"
                end
            }

            local config = { schema_version = 1, hyperKeyCode = 80 }
            Migrator.migrate(config, 1, 2, testBackupManager, mockLogger)

            assert.is_true(backupCalled)
        end)

        it("should update schema_version even without migration function", function()
            -- When migrating from v1 to v2 without a migration function defined
            local config = { schema_version = 1, hyperKeyCode = 80 }
            local result = Migrator.migrate(config, 1, 2, mockBackupManager, mockLogger)

            -- Schema version should be updated
            assert.equals(2, result.schema_version)
            -- Other fields should remain unchanged
            assert.equals(80, result.hyperKeyCode)
        end)

        it("should handle backup failure gracefully", function()
            local failingBackupManager = {
                createBackup = function()
                    error("Backup failed")
                end
            }

            local config = { schema_version = 1, hyperKeyCode = 80 }
            -- Should not throw error, just log warning
            local result = Migrator.migrate(config, 1, 2, failingBackupManager, mockLogger)

            assert.is_not_nil(result)
            assert.equals(2, result.schema_version)
        end)
    end)

    describe("future migration scenarios", function()
        it("should provide template for adding migration functions", function()
            -- This is a documentation test showing how to add migrations
            -- Example migration function for v1 -> v2:
            --
            -- migrations[1] = function(config)
            --     if config.old_field then
            --         config.new_field = config.old_field
            --         config.old_field = nil
            --     end
            --     return config
            -- end

            assert.is_true(true) -- Template documented
        end)
    end)
end)
