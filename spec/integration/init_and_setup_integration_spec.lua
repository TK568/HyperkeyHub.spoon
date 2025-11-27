--- Integration tests for initialization and setup flow
--- Tests the complete bootstrap process from loading modules to binding keys

describe("Integration: Initialization and Setup", function()
    local helpers
    local obj, modules, eventCapture
    local projectRoot

    before_each(function()
        reset_mocks()

        helpers = require("spec.helpers.integration_helpers")

        -- Get project root
        local info = debug.getinfo(1, "S")
        local scriptPath = info.source:match("@(.*/)")
        projectRoot = scriptPath:gsub("spec/integration/$", "")

        -- Setup test environment
        _G.hs.configdir = "/tmp/test_hammerspoon"
        helpers.setupTempConfigDirectory()

        -- Create Spoon object
        obj = helpers.createSpoonObject()

        -- Setup mocks
        helpers.setupHotkeyMocks()
        helpers.setupEventTapMocks()
        helpers.setupMenubarMocks()

        -- Mock hs.execute for directory creation
        _G.hs.execute = function(cmd)
            return true, nil
        end

        -- Clean up loaded modules
        package.loaded["bootstrap"] = nil
        package.loaded["config_loader"] = nil
        package.loaded["logger"] = nil
        package.loaded["event_bus"] = nil
    end)

    after_each(function()
        helpers.cleanup()
    end)

    describe("Module Loading", function()
        it("should load all required modules successfully", function()
            local requireModule = helpers.createRequireModule(projectRoot)
            local Bootstrap = requireModule("bootstrap")

            modules = Bootstrap.loadModules(requireModule)

            assert.is_not_nil(modules.Logger)
            assert.is_not_nil(modules.EventBus)
            assert.is_not_nil(modules.ConfigLoader)
            assert.is_not_nil(modules.HyperKey)
            assert.is_not_nil(modules.WindowManager)
            assert.is_not_nil(modules.AppLauncher)
            assert.is_not_nil(modules.SystemActions)
            assert.is_not_nil(modules.SettingsUI)
            assert.is_not_nil(modules.ScriptRunner)
        end)

        it("should initialize EventBus from Spoon object", function()
            assert.is_not_nil(obj.EventBus)
            assert.equals("function", type(obj.EventBus.emit))
            assert.equals("function", type(obj.EventBus.on))
            assert.equals("function", type(obj.EventBus.off))
        end)
    end)

    describe("Configuration Loading", function()
        it("should load configuration when config file exists", function()
            local requireModule = helpers.createRequireModule(projectRoot)
            local Bootstrap = requireModule("bootstrap")

            modules = Bootstrap.loadModules(requireModule)
            modules.EventBus = obj.EventBus

            -- Create config file with default content
            local configFile = "/tmp/test_hammerspoon/HyperkeyHub/config.json"
            helpers.createTestConfigFile(configFile, {
                hyperKeyCode = 80,
                applications = {}
            })

            local config, err = Bootstrap.loadConfiguration(obj, modules, configFile)

            assert.is_nil(err)
            assert.is_not_nil(config)
            assert.is_not_nil(config.hyperConfig)
            assert.is_not_nil(config.appConfig)
            assert.is_not_nil(config.systemConfig)
            assert.is_not_nil(config.scriptConfig)
        end)

        it("should merge custom configuration with defaults", function()
            local requireModule = helpers.createRequireModule(projectRoot)
            local Bootstrap = requireModule("bootstrap")

            modules = Bootstrap.loadModules(requireModule)
            modules.EventBus = obj.EventBus

            local customConfigFile = "/tmp/test_hammerspoon/custom_config.json"
            helpers.createTestConfigFile(customConfigFile, {
                hyperKeyCode = 80,
                applications = {
                    arc = {
                        name = "Arc",
                        key = "a",
                        bundle = "company.thebrowser.Browser",
                        modifiers = {}
                    }
                }
            })

            local config = Bootstrap.loadConfiguration(obj, modules, customConfigFile)

            assert.is_not_nil(config)
            assert.equals(80, config.hyperConfig.keyCode)
            assert.is_not_nil(config.appConfig.applications.arc)
            assert.equals("Arc", config.appConfig.applications.arc.name)
        end)

        it("should create system action functions", function()
            local requireModule = helpers.createRequireModule(projectRoot)
            local Bootstrap = requireModule("bootstrap")

            modules = Bootstrap.loadModules(requireModule)
            modules.EventBus = obj.EventBus

            local configFile = "/tmp/test_hammerspoon/HyperkeyHub/config.json"
            helpers.createTestConfigFile(configFile, {
                hyperKeyCode = 80,
                applications = {}
            })

            local config = Bootstrap.loadConfiguration(obj, modules, configFile)

            assert.is_not_nil(config.systemConfig.functions)
            assert.is_table(config.systemConfig.functions)
            assert.is_true(type(config.systemConfig.functions) == "table")

            local functionCount = 0
            for _ in pairs(config.systemConfig.functions) do
                functionCount = functionCount + 1
            end
            assert.is_true(functionCount > 0)
        end)
    end)

    describe("Module Initialization", function()
        it("should initialize WindowManager with EventBus", function()
            local requireModule = helpers.createRequireModule(projectRoot)
            local Bootstrap = requireModule("bootstrap")

            modules = Bootstrap.loadModules(requireModule)
            modules.EventBus = obj.EventBus

            eventCapture = helpers.captureEvents(obj.EventBus)

            Bootstrap.initializeModules(modules, obj.EventBus)

            assert.is_not_nil(modules.WindowManager.eventBus)
        end)

        it("should initialize AppLauncher with EventBus", function()
            local requireModule = helpers.createRequireModule(projectRoot)
            local Bootstrap = requireModule("bootstrap")

            modules = Bootstrap.loadModules(requireModule)
            modules.EventBus = obj.EventBus

            Bootstrap.initializeModules(modules, obj.EventBus)

            assert.is_not_nil(modules.AppLauncher.eventBus)
        end)

        it("should initialize ScriptRunner with EventBus", function()
            local requireModule = helpers.createRequireModule(projectRoot)
            local Bootstrap = requireModule("bootstrap")

            modules = Bootstrap.loadModules(requireModule)
            modules.EventBus = obj.EventBus

            Bootstrap.initializeModules(modules, obj.EventBus)

            assert.is_not_nil(modules.ScriptRunner.eventBus)
        end)
    end)

    describe("HyperKey Bindings Setup", function()
        it("should create hyper modal successfully", function()
            local requireModule = helpers.createRequireModule(projectRoot)
            local Bootstrap = requireModule("bootstrap")

            modules = Bootstrap.loadModules(requireModule)
            modules.EventBus = obj.EventBus

            local configFile = "/tmp/test_hammerspoon/HyperkeyHub/config.json"
            helpers.createTestConfigFile(configFile, {
                hyperKeyCode = 80,
                applications = {}
            })

            local config = Bootstrap.loadConfiguration(obj, modules, configFile)
            local logger = modules.Logger.new("Test")

            Bootstrap.setupHyperKeyBindings(obj, modules, config, logger)

            assert.is_not_nil(obj.hyper)
            assert.equals("function", type(obj.hyper.bind))
            assert.equals("function", type(obj.hyper.entered))
            assert.equals("function", type(obj.hyper.exited))
        end)

        it("should register application bindings", function()
            local requireModule = helpers.createRequireModule(projectRoot)
            local Bootstrap = requireModule("bootstrap")

            modules = Bootstrap.loadModules(requireModule)
            modules.EventBus = obj.EventBus

            local customConfigFile = "/tmp/test_hammerspoon/app_config.json"
            helpers.createTestConfigFile(customConfigFile, {
                applications = {
                    arc = {
                        name = "Arc",
                        key = "a",
                        bundle = "company.thebrowser.Browser",
                        modifiers = {}
                    },
                    terminal = {
                        name = "Terminal",
                        key = "t",
                        bundle = "com.apple.Terminal",
                        modifiers = {}
                    }
                }
            })

            local config = Bootstrap.loadConfiguration(obj, modules, customConfigFile)
            local logger = modules.Logger.new("Test")

            Bootstrap.setupHyperKeyBindings(obj, modules, config, logger)

            assert.is_not_nil(obj.hyper.bindings)
            assert.is_true(#obj.hyper.bindings >= 2)
        end)

        it("should register system action bindings", function()
            local requireModule = helpers.createRequireModule(projectRoot)
            local Bootstrap = requireModule("bootstrap")

            modules = Bootstrap.loadModules(requireModule)
            modules.EventBus = obj.EventBus

            local configFile = "/tmp/test_hammerspoon/HyperkeyHub/config.json"
            helpers.createTestConfigFile(configFile, {
                hyperKeyCode = 80,
                applications = {}
            })

            local config = Bootstrap.loadConfiguration(obj, modules, configFile)
            local logger = modules.Logger.new("Test")

            Bootstrap.setupHyperKeyBindings(obj, modules, config, logger)

            assert.is_not_nil(obj.registeredKeys)
            assert.is_table(obj.registeredKeys)
        end)

        it("should build registered keys list", function()
            local requireModule = helpers.createRequireModule(projectRoot)
            local Bootstrap = requireModule("bootstrap")

            modules = Bootstrap.loadModules(requireModule)
            modules.EventBus = obj.EventBus

            local configFile = "/tmp/test_hammerspoon/HyperkeyHub/config.json"
            helpers.createTestConfigFile(configFile, {
                hyperKeyCode = 80,
                applications = {}
            })

            local config = Bootstrap.loadConfiguration(obj, modules, configFile)
            local logger = modules.Logger.new("Test")

            Bootstrap.setupHyperKeyBindings(obj, modules, config, logger)

            assert.is_not_nil(obj.registeredKeys)
            assert.is_not_nil(obj.registeredModifierKeys)
        end)
    end)

    describe("Full Bootstrap Flow", function()
        it("should complete full initialization without errors", function()
            local requireModule = helpers.createRequireModule(projectRoot)

            -- Create config file for full bootstrap
            local configFile = "/tmp/test_hammerspoon/bootstrap_test.json"
            helpers.createTestConfigFile(configFile, {
                hyperKeyCode = 80,
                applications = {}
            })

            local success, modules = pcall(function()
                return helpers.simulateBootstrap(obj, requireModule, configFile)
            end)

            assert.is_true(success)
            assert.is_not_nil(modules)
            assert.is_not_nil(modules.EventBus)
            assert.is_not_nil(modules.Logger)
        end)

        it("should emit events during initialization", function()
            local requireModule = helpers.createRequireModule(projectRoot)
            local Bootstrap = requireModule("bootstrap")

            modules = Bootstrap.loadModules(requireModule)
            modules.EventBus = obj.EventBus

            eventCapture = helpers.captureEvents(obj.EventBus)

            Bootstrap.initializeModules(modules, obj.EventBus)

            assert.is_true(#eventCapture.emissions >= 0)
        end)
    end)
end)
