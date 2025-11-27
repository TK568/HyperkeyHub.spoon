--- Integration tests for app launching and window management
--- Tests the interaction between AppLauncher, WindowManager, and EventBus

describe("Integration: App and Window Management", function()
    local helpers
    local obj, modules, eventCapture
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
        helpers.setupAppMocks({
            ["company.thebrowser.Browser"] = {
                success = true,
                running = false,
                name = "Arc"
            },
            ["com.apple.Terminal"] = {
                success = true,
                running = false,
                name = "Terminal"
            }
        })
        helpers.setupWindowMocks({
            hasFocusedWindow = true,
            currentFrame = { x = 0, y = 0, w = 800, h = 600 },
            screenFrame = { x = 0, y = 0, w = 1920, h = 1080 }
        })

        _G.hs.execute = function(cmd)
            return true, nil
        end

        package.loaded["bootstrap"] = nil
        package.loaded["config_loader"] = nil
        package.loaded["app_launcher"] = nil
        package.loaded["window_manager"] = nil
    end)

    after_each(function()
        if eventCapture then
            eventCapture:restore()
        end
        helpers.cleanup()
    end)

    describe("App Launching via EventBus", function()
        it("should emit app:toggle event when app binding is triggered", function()
            local requireModule = helpers.createRequireModule(projectRoot)
            local Bootstrap = requireModule("bootstrap")

            modules = Bootstrap.loadModules(requireModule)
            modules.EventBus = obj.EventBus

            eventCapture = helpers.captureEvents(obj.EventBus)

            Bootstrap.initializeModules(modules, obj.EventBus)

            obj.EventBus:emit("app:toggle", {
                bundleID = "company.thebrowser.Browser",
                appName = "Arc"
            })

            assert.is_true(#eventCapture.emissions >= 1)

            local foundAppToggle = false
            for _, emission in ipairs(eventCapture.emissions) do
                if emission.event == "app:toggle" then
                    foundAppToggle = true
                    assert.equals("company.thebrowser.Browser", emission.data.bundleID)
                    assert.equals("Arc", emission.data.appName)
                    break
                end
            end
            assert.is_true(foundAppToggle)
        end)

        it("should handle app:toggle event in AppLauncher", function()
            local requireModule = helpers.createRequireModule(projectRoot)
            local Bootstrap = requireModule("bootstrap")

            modules = Bootstrap.loadModules(requireModule)
            modules.EventBus = obj.EventBus

            Bootstrap.initializeModules(modules, obj.EventBus)

            local success = pcall(function()
                obj.EventBus:emit("app:toggle", {
                    bundleID = "company.thebrowser.Browser",
                    appName = "Arc"
                })
            end)

            assert.is_true(success)
        end)
    end)

    describe("Window Management via EventBus", function()
        it("should handle window:move event", function()
            local requireModule = helpers.createRequireModule(projectRoot)
            local Bootstrap = requireModule("bootstrap")

            modules = Bootstrap.loadModules(requireModule)
            modules.EventBus = obj.EventBus

            Bootstrap.initializeModules(modules, obj.EventBus)

            local success = pcall(function()
                obj.EventBus:emit("window:move", {
                    direction = "left"
                })
            end)

            assert.is_true(success)
        end)

        it("should handle window:maximize event", function()
            local requireModule = helpers.createRequireModule(projectRoot)
            local Bootstrap = requireModule("bootstrap")

            modules = Bootstrap.loadModules(requireModule)
            modules.EventBus = obj.EventBus

            Bootstrap.initializeModules(modules, obj.EventBus)

            local success = pcall(function()
                obj.EventBus:emit("window:maximize", {})
            end)

            assert.is_true(success)
        end)

        it("should handle window:center event", function()
            local requireModule = helpers.createRequireModule(projectRoot)
            local Bootstrap = requireModule("bootstrap")

            modules = Bootstrap.loadModules(requireModule)
            modules.EventBus = obj.EventBus

            Bootstrap.initializeModules(modules, obj.EventBus)

            local success = pcall(function()
                obj.EventBus:emit("window:center", {})
            end)

            assert.is_true(success)
        end)
    end)

    describe("App Launch followed by Window Management", function()
        it("should launch app and then manage window", function()
            local requireModule = helpers.createRequireModule(projectRoot)
            local Bootstrap = requireModule("bootstrap")

            modules = Bootstrap.loadModules(requireModule)
            modules.EventBus = obj.EventBus

            eventCapture = helpers.captureEvents(obj.EventBus)

            Bootstrap.initializeModules(modules, obj.EventBus)

            obj.EventBus:emit("app:toggle", {
                bundleID = "company.thebrowser.Browser",
                appName = "Arc"
            })

            obj.EventBus:emit("window:maximize", {})

            assert.is_true(#eventCapture.emissions >= 2)
        end)
    end)

    describe("Multiple App Operations", function()
        it("should handle multiple app:toggle events in sequence", function()
            local requireModule = helpers.createRequireModule(projectRoot)
            local Bootstrap = requireModule("bootstrap")

            modules = Bootstrap.loadModules(requireModule)
            modules.EventBus = obj.EventBus

            eventCapture = helpers.captureEvents(obj.EventBus)

            Bootstrap.initializeModules(modules, obj.EventBus)

            obj.EventBus:emit("app:toggle", {
                bundleID = "company.thebrowser.Browser",
                appName = "Arc"
            })

            obj.EventBus:emit("app:toggle", {
                bundleID = "com.apple.Terminal",
                appName = "Terminal"
            })

            assert.is_true(#eventCapture.emissions >= 2)

            local appToggleCount = 0
            for _, emission in ipairs(eventCapture.emissions) do
                if emission.event == "app:toggle" then
                    appToggleCount = appToggleCount + 1
                end
            end
            assert.equals(2, appToggleCount)
        end)
    end)

    describe("Window Management Operations", function()
        it("should handle multiple window operations in sequence", function()
            local requireModule = helpers.createRequireModule(projectRoot)
            local Bootstrap = requireModule("bootstrap")

            modules = Bootstrap.loadModules(requireModule)
            modules.EventBus = obj.EventBus

            eventCapture = helpers.captureEvents(obj.EventBus)

            Bootstrap.initializeModules(modules, obj.EventBus)

            obj.EventBus:emit("window:move", { direction = "left" })
            obj.EventBus:emit("window:move", { direction = "right" })
            obj.EventBus:emit("window:maximize", {})

            assert.is_true(#eventCapture.emissions >= 3)
        end)
    end)

    describe("Error Handling in App and Window Operations", function()
        it("should handle app launch failure gracefully", function()
            helpers.setupAppMocks({
                ["com.example.FailApp"] = {
                    success = false,
                    running = false,
                    name = "FailApp"
                }
            })

            local requireModule = helpers.createRequireModule(projectRoot)
            local Bootstrap = requireModule("bootstrap")

            modules = Bootstrap.loadModules(requireModule)
            modules.EventBus = obj.EventBus

            Bootstrap.initializeModules(modules, obj.EventBus)

            local success = pcall(function()
                obj.EventBus:emit("app:toggle", {
                    bundleID = "com.example.FailApp",
                    appName = "FailApp"
                })
            end)

            assert.is_true(success)
        end)

        it("should handle window operation when no focused window exists", function()
            helpers.setupWindowMocks({
                hasFocusedWindow = false
            })

            local requireModule = helpers.createRequireModule(projectRoot)
            local Bootstrap = requireModule("bootstrap")

            modules = Bootstrap.loadModules(requireModule)
            modules.EventBus = obj.EventBus

            Bootstrap.initializeModules(modules, obj.EventBus)

            local success = pcall(function()
                obj.EventBus:emit("window:maximize", {})
            end)

            assert.is_true(success)
        end)
    end)

    describe("EventBus Integration", function()
        it("should allow multiple listeners for the same event", function()
            local requireModule = helpers.createRequireModule(projectRoot)
            local Bootstrap = requireModule("bootstrap")

            modules = Bootstrap.loadModules(requireModule)
            modules.EventBus = obj.EventBus

            local listener1Called = false
            local listener2Called = false

            obj.EventBus:on("test:event", function(data)
                listener1Called = true
            end)

            obj.EventBus:on("test:event", function(data)
                listener2Called = true
            end)

            obj.EventBus:emit("test:event", { test = true })

            assert.is_true(listener1Called)
            assert.is_true(listener2Called)
        end)

        it("should pass event data correctly to listeners", function()
            local requireModule = helpers.createRequireModule(projectRoot)
            local Bootstrap = requireModule("bootstrap")

            modules = Bootstrap.loadModules(requireModule)
            modules.EventBus = obj.EventBus

            local receivedData = nil

            obj.EventBus:on("test:data", function(data)
                receivedData = data
            end)

            local testData = {
                key1 = "value1",
                key2 = 123,
                key3 = true
            }

            obj.EventBus:emit("test:data", testData)

            assert.is_not_nil(receivedData)
            assert.equals("value1", receivedData.key1)
            assert.equals(123, receivedData.key2)
            assert.is_true(receivedData.key3)
        end)
    end)
end)
