describe("Bootstrap", function()
    local Bootstrap

    before_each(function()
        package.loaded["bootstrap"] = nil
        Bootstrap = require("bootstrap")
    end)

    describe("loadModules", function()
        it("loads all required modules", function()
            local loadedModules = {}
            local mockRequire = function(moduleName)
                loadedModules[moduleName] = true
                return { name = moduleName }
            end

            local modules = Bootstrap.loadModules(mockRequire)

            assert.is_not_nil(modules.Logger)
            assert.is_not_nil(modules.EventBus)
            assert.is_not_nil(modules.WindowManager)
            assert.is_not_nil(modules.AppLauncher)
            assert.is_not_nil(modules.ConfigLoader)
            assert.is_not_nil(modules.HyperKey)
            assert.is_not_nil(modules.SettingsUI)
            assert.is_not_nil(modules.SystemActions)
            assert.is_not_nil(modules.ScriptRunner)
        end)

        it("calls requireModuleFn for each module", function()
            local callCount = 0
            local calledModules = {}
            local mockRequire = function(moduleName)
                callCount = callCount + 1
                calledModules[moduleName] = true
                return { name = moduleName }
            end

            Bootstrap.loadModules(mockRequire)

            assert.equals(9, callCount)
            assert.is_true(calledModules["logger"])
            assert.is_true(calledModules["event_bus"])
            assert.is_true(calledModules["window_manager"])
            assert.is_true(calledModules["app_launcher"])
            assert.is_true(calledModules["config_loader"])
            assert.is_true(calledModules["hyper_key"])
            assert.is_true(calledModules["settings_ui"])
            assert.is_true(calledModules["system_actions"])
            assert.is_true(calledModules["script_runner"])
        end)

        it("returns module objects with expected structure", function()
            local mockRequire = function(moduleName)
                return { moduleName = moduleName, initialized = false }
            end

            local modules = Bootstrap.loadModules(mockRequire)

            assert.equals("logger", modules.Logger.moduleName)
            assert.equals("event_bus", modules.EventBus.moduleName)
            assert.equals("window_manager", modules.WindowManager.moduleName)
        end)
    end)

    describe("loadConfiguration", function()
        it("loads configuration successfully", function()
            local obj = {}
            local mockConfig = {
                hyperConfig = {},
                appConfig = {},
                systemConfig = { functions = {} }
            }
            local mockModules = {
                ConfigLoader = {
                    _customConfigPath = nil,
                    loadWithDefaults = function()
                        return mockConfig, nil
                    end
                },
                SystemActions = {
                    createActions = function()
                        return { action1 = {}, action2 = {} }
                    end
                },
                Logger = {
                    new = function()
                        return { name = "logger" }
                    end
                },
                SettingsUI = {}
            }

            local config, err = Bootstrap.loadConfiguration(obj, mockModules, "/path/to/config")

            assert.is_nil(err)
            assert.is_not_nil(config)
            assert.equals("/path/to/config", obj.configPath)
            assert.equals("/path/to/config", mockModules.ConfigLoader._customConfigPath)
        end)

        it("sets customConfigPath correctly", function()
            local obj = {}
            local mockConfig = {
                hyperConfig = {},
                appConfig = {},
                systemConfig = { functions = {} }
            }
            local mockModules = {
                ConfigLoader = {
                    _customConfigPath = nil,
                    loadWithDefaults = function()
                        return mockConfig, nil
                    end
                },
                SystemActions = {
                    createActions = function()
                        return {}
                    end
                },
                Logger = {
                    new = function()
                        return {}
                    end
                },
                SettingsUI = {}
            }

            Bootstrap.loadConfiguration(obj, mockModules, "/custom/path")

            assert.equals("/custom/path", mockModules.ConfigLoader._customConfigPath)
            assert.equals("/custom/path", obj.configPath)
        end)

        it("returns error when config loading fails", function()
            local obj = {}
            local mockModules = {
                ConfigLoader = {
                    _customConfigPath = nil,
                    loadWithDefaults = function()
                        return nil, "Failed to load config"
                    end
                }
            }

            local config, err = Bootstrap.loadConfiguration(obj, mockModules, "/path/to/config")

            assert.is_nil(config)
            assert.equals("Failed to load config", err)
        end)

        it("creates system actions with correct parameters", function()
            local obj = { name = "testObj" }
            local createActionsCalled = false
            local createActionsParams = {}
            local mockConfig = {
                hyperConfig = {},
                appConfig = {},
                systemConfig = { functions = {} }
            }
            local mockLogger = { name = "mockLogger" }
            local mockModules = {
                ConfigLoader = {
                    _customConfigPath = nil,
                    loadWithDefaults = function()
                        return mockConfig, nil
                    end
                },
                SystemActions = {
                    createActions = function(obj, logger, configLoader, settingsUI, systemConfig)
                        createActionsCalled = true
                        createActionsParams = {
                            obj = obj,
                            logger = logger,
                            configLoader = configLoader,
                            settingsUI = settingsUI,
                            systemConfig = systemConfig
                        }
                        return { testAction = {} }
                    end
                },
                Logger = {
                    new = function()
                        return mockLogger
                    end
                },
                SettingsUI = { name = "mockSettingsUI" }
            }

            Bootstrap.loadConfiguration(obj, mockModules, "/path/to/config")

            assert.is_true(createActionsCalled)
            assert.equals(obj, createActionsParams.obj)
            assert.equals(mockLogger, createActionsParams.logger)
            assert.equals(mockModules.ConfigLoader, createActionsParams.configLoader)
            assert.equals(mockModules.SettingsUI, createActionsParams.settingsUI)
        end)

        it("does not overwrite existing configPath in obj", function()
            local obj = { configPath = "/existing/path" }
            local mockConfig = {
                hyperConfig = {},
                appConfig = {},
                systemConfig = { functions = {} }
            }
            local mockModules = {
                ConfigLoader = {
                    _customConfigPath = nil,
                    loadWithDefaults = function()
                        return mockConfig, nil
                    end
                },
                SystemActions = {
                    createActions = function()
                        return {}
                    end
                },
                Logger = {
                    new = function()
                        return {}
                    end
                },
                SettingsUI = {}
            }

            Bootstrap.loadConfiguration(obj, mockModules, "/new/path")

            assert.equals("/existing/path", obj.configPath)
            assert.equals("/existing/path", mockModules.ConfigLoader._customConfigPath)
        end)
    end)

    describe("initializeModules", function()
        it("initializes WindowManager with eventBus", function()
            local windowManagerInitCalled = false
            local windowManagerEventBus = nil
            local mockModules = {
                WindowManager = {
                    init = function(self, eventBus)
                        windowManagerInitCalled = true
                        windowManagerEventBus = eventBus
                    end
                },
                AppLauncher = {
                    init = function() end
                },
                ScriptRunner = {
                    init = function() end
                }
            }
            local mockEventBus = { name = "eventBus" }

            Bootstrap.initializeModules(mockModules, mockEventBus)

            assert.is_true(windowManagerInitCalled)
            assert.equals(mockEventBus, windowManagerEventBus)
        end)

        it("initializes AppLauncher with eventBus", function()
            local appLauncherInitCalled = false
            local appLauncherEventBus = nil
            local mockModules = {
                WindowManager = {
                    init = function() end
                },
                AppLauncher = {
                    init = function(self, eventBus)
                        appLauncherInitCalled = true
                        appLauncherEventBus = eventBus
                    end
                },
                ScriptRunner = {
                    init = function() end
                }
            }
            local mockEventBus = { name = "eventBus" }

            Bootstrap.initializeModules(mockModules, mockEventBus)

            assert.is_true(appLauncherInitCalled)
            assert.equals(mockEventBus, appLauncherEventBus)
        end)

        it("initializes ScriptRunner with eventBus", function()
            local scriptRunnerInitCalled = false
            local scriptRunnerEventBus = nil
            local mockModules = {
                WindowManager = {
                    init = function() end
                },
                AppLauncher = {
                    init = function() end
                },
                ScriptRunner = {
                    init = function(self, eventBus)
                        scriptRunnerInitCalled = true
                        scriptRunnerEventBus = eventBus
                    end
                }
            }
            local mockEventBus = { name = "eventBus" }

            Bootstrap.initializeModules(mockModules, mockEventBus)

            assert.is_true(scriptRunnerInitCalled)
            assert.equals(mockEventBus, scriptRunnerEventBus)
        end)

        it("initializes all modules in correct order", function()
            local initOrder = {}
            local mockModules = {
                WindowManager = {
                    init = function()
                        table.insert(initOrder, "WindowManager")
                    end
                },
                AppLauncher = {
                    init = function()
                        table.insert(initOrder, "AppLauncher")
                    end
                },
                ScriptRunner = {
                    init = function()
                        table.insert(initOrder, "ScriptRunner")
                    end
                }
            }

            Bootstrap.initializeModules(mockModules, {})

            assert.equals(3, #initOrder)
            assert.equals("WindowManager", initOrder[1])
            assert.equals("AppLauncher", initOrder[2])
            assert.equals("ScriptRunner", initOrder[3])
        end)
    end)
end)
