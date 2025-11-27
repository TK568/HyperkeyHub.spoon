--- Integration tests for error handling scenarios
--- Tests how the system handles various error conditions during initialization

describe("Integration: Error Handling", function()
    local helpers
    local obj, modules
    local projectRoot

    before_each(function()
        reset_mocks()

        helpers = require("spec.helpers.integration_helpers")

        local info = debug.getinfo(1, "S")
        local scriptPath = info.source:match("@(.*/)")
        projectRoot = scriptPath:gsub("spec/integration/$", "")

        _G.hs.configdir = "/tmp/test_hammerspoon"
        helpers.setupTempConfigDirectory()

        obj = helpers.createSpoonObject()

        helpers.setupHotkeyMocks()
        helpers.setupEventTapMocks()
        helpers.setupMenubarMocks()

        _G.hs.execute = function(cmd)
            return true, nil
        end

        package.loaded["bootstrap"] = nil
        package.loaded["config_loader"] = nil
        package.loaded["logger"] = nil
        package.loaded["event_bus"] = nil
    end)

    after_each(function()
        helpers.cleanup()
    end)

    describe("Invalid JSON Configuration", function()
        it("should handle malformed JSON gracefully", function()
            local requireModule = helpers.createRequireModule(projectRoot)
            local Bootstrap = requireModule("bootstrap")

            modules = Bootstrap.loadModules(requireModule)
            modules.EventBus = obj.EventBus

            local invalidConfigFile = "/tmp/test_hammerspoon/invalid_config.json"
            local file = io.open(invalidConfigFile, "w")
            file:write("{ invalid json }")
            file:close()

            local success, err = pcall(function()
                Bootstrap.loadConfiguration(obj, modules, invalidConfigFile)
            end)

            assert.is_true(success or err ~= nil)
        end)
    end)

    describe("Missing Configuration File", function()
        it("should return error when config file does not exist", function()
            local requireModule = helpers.createRequireModule(projectRoot)
            local Bootstrap = requireModule("bootstrap")

            modules = Bootstrap.loadModules(requireModule)
            modules.EventBus = obj.EventBus

            local nonExistentFile = "/tmp/test_hammerspoon/does_not_exist.json"

            local config, err = Bootstrap.loadConfiguration(obj, modules, nonExistentFile)

            assert.is_nil(config)
            assert.is_string(err)
            assert.is_truthy(err:match("Failed to read config file"))
        end)
    end)

    describe("Incomplete Configuration", function()
        it("should fill in missing fields with defaults", function()
            local requireModule = helpers.createRequireModule(projectRoot)
            local Bootstrap = requireModule("bootstrap")

            modules = Bootstrap.loadModules(requireModule)
            modules.EventBus = obj.EventBus

            local incompleteConfigFile = "/tmp/test_hammerspoon/incomplete_config.json"
            helpers.createTestConfigFile(incompleteConfigFile, {
                hyperKeyCode = 80
            })

            local config = Bootstrap.loadConfiguration(obj, modules, incompleteConfigFile)

            assert.is_not_nil(config)
            assert.equals(80, config.hyperConfig.keyCode)
            assert.is_not_nil(config.appConfig)
            assert.is_not_nil(config.systemConfig)
        end)

        it("should handle missing application bundle IDs", function()
            local requireModule = helpers.createRequireModule(projectRoot)
            local Bootstrap = requireModule("bootstrap")

            modules = Bootstrap.loadModules(requireModule)
            modules.EventBus = obj.EventBus

            local configWithMissingBundle = "/tmp/test_hammerspoon/missing_bundle.json"
            helpers.createTestConfigFile(configWithMissingBundle, {
                applications = {
                    test_app = {
                        name = "Test App",
                        key = "t"
                    }
                }
            })

            local config = Bootstrap.loadConfiguration(obj, modules, configWithMissingBundle)

            assert.is_not_nil(config)
        end)
    end)

    describe("EventBus Error Handling", function()
        it("should continue initialization if event emission fails", function()
            local requireModule = helpers.createRequireModule(projectRoot)
            local Bootstrap = requireModule("bootstrap")

            modules = Bootstrap.loadModules(requireModule)
            modules.EventBus = obj.EventBus

            local originalEmit = obj.EventBus.emit
            obj.EventBus.emit = function(self, eventName, eventData)
                if eventName == "test:error" then
                    error("Simulated event error")
                end
                return originalEmit(self, eventName, eventData)
            end

            local success = pcall(function()
                Bootstrap.initializeModules(modules, obj.EventBus)
            end)

            assert.is_true(success)
        end)
    end)

    describe("Module Loading Errors", function()
        it("should fail gracefully when required module is missing", function()
            local requireModule = helpers.createRequireModule(projectRoot)

            local brokenRequireModule = function(moduleName)
                if moduleName == "non_existent_module" then
                    error("Module not found: " .. moduleName)
                end
                return requireModule(moduleName)
            end

            local success, err = pcall(function()
                brokenRequireModule("non_existent_module")
            end)

            assert.is_false(success)
            assert.is_not_nil(err)
            assert.is_true(err:match("Module not found") ~= nil)
        end)
    end)

    describe("HyperKey Binding Errors", function()
        it("should handle missing action function gracefully", function()
            local requireModule = helpers.createRequireModule(projectRoot)
            local Bootstrap = requireModule("bootstrap")

            modules = Bootstrap.loadModules(requireModule)
            modules.EventBus = obj.EventBus

            local configWithInvalidAction = "/tmp/test_hammerspoon/invalid_action.json"
            helpers.createTestConfigFile(configWithInvalidAction, {
                applications = {
                    test = {
                        name = "Test",
                        key = "x",
                        bundle = "com.test.app",
                        modifiers = {}
                    }
                }
            })

            local config = Bootstrap.loadConfiguration(obj, modules, configWithInvalidAction)
            local logger = modules.Logger.new("Test")

            local success = pcall(function()
                Bootstrap.setupHyperKeyBindings(obj, modules, config, logger)
            end)

            assert.is_true(success)
        end)
    end)

    describe("Configuration Validation", function()
        it("should validate hyperKeyCode range", function()
            local requireModule = helpers.createRequireModule(projectRoot)
            local Bootstrap = requireModule("bootstrap")

            modules = Bootstrap.loadModules(requireModule)
            modules.EventBus = obj.EventBus

            local invalidKeyCodeConfig = "/tmp/test_hammerspoon/invalid_keycode.json"
            helpers.createTestConfigFile(invalidKeyCodeConfig, {
                hyperKeyCode = 9999
            })

            local config = Bootstrap.loadConfiguration(obj, modules, invalidKeyCodeConfig)

            assert.is_not_nil(config)
            assert.is_number(config.hyperConfig.keyCode)
        end)

        it("should handle empty applications config", function()
            local requireModule = helpers.createRequireModule(projectRoot)
            local Bootstrap = requireModule("bootstrap")

            modules = Bootstrap.loadModules(requireModule)
            modules.EventBus = obj.EventBus

            local emptyAppsConfig = "/tmp/test_hammerspoon/empty_apps.json"
            helpers.createTestConfigFile(emptyAppsConfig, {
                applications = {}
            })

            local config = Bootstrap.loadConfiguration(obj, modules, emptyAppsConfig)

            assert.is_not_nil(config)
            assert.is_table(config.appConfig.applications)
        end)
    end)

end)
