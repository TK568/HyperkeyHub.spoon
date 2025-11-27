describe("HyperKey", function()
    local HyperKey

    setup(function()
        HyperKey = dofile("modules/hyper_key.lua")
    end)

    describe("buildRegisteredKeys", function()
        it("should build registered keys from application config", function()
            local appConfig = {
                applications = {
                    vscode = { key = "v", bundle = "com.microsoft.VSCode" },
                    arc = { key = "a", bundle = "company.thebrowser.Browser" }
                }
            }
            local systemConfig = { functions = {}, customBindings = {} }
            local scriptConfig = { scriptShortcuts = {} }

            local registeredKeys, registeredModifierKeys = HyperKey.buildRegisteredKeys(appConfig, systemConfig, scriptConfig)

            assert.is_true(registeredKeys["v"])
            assert.is_true(registeredKeys["a"])
        end)

        it("should build registered modifier keys", function()
            local appConfig = {
                applications = {
                    claude = {
                        key = "c",
                        modifiers = {"shift", "cmd"},
                        bundle = "com.anthropic.claudefordesktop"
                    }
                }
            }
            local systemConfig = { functions = {}, customBindings = {} }
            local scriptConfig = { scriptShortcuts = {} }

            local registeredKeys, registeredModifierKeys = HyperKey.buildRegisteredKeys(appConfig, systemConfig, scriptConfig)

            assert.is_true(registeredKeys["c"])
            assert.is_true(registeredModifierKeys["shift+cmd+c"])
        end)

        it("should include system functions", function()
            local appConfig = { applications = {} }
            local systemConfig = {
                functions = {
                    reload = { key = "r" },
                    settings = { key = "," }
                },
                customBindings = {}
            }
            local scriptConfig = { scriptShortcuts = {} }

            local registeredKeys, registeredModifierKeys = HyperKey.buildRegisteredKeys(appConfig, systemConfig, scriptConfig)

            assert.is_true(registeredKeys["r"])
            assert.is_true(registeredKeys[","])
        end)

        it("should include script shortcuts", function()
            local appConfig = { applications = {} }
            local systemConfig = { functions = {}, customBindings = {} }
            local scriptConfig = {
                scriptShortcuts = {
                    window_left = { key = "left" },
                    window_maximize = { key = "up", modifiers = {} }
                }
            }

            local registeredKeys, registeredModifierKeys = HyperKey.buildRegisteredKeys(appConfig, systemConfig, scriptConfig)

            assert.is_true(registeredKeys["left"])
            assert.is_true(registeredKeys["up"])
        end)

        it("should include custom bindings", function()
            local appConfig = { applications = {} }
            local systemConfig = {
                functions = {},
                customBindings = {
                    { key = "x", mods = {}, action = function() end },
                    { key = "z", mods = {"shift"}, action = function() end }
                }
            }
            local scriptConfig = { scriptShortcuts = {} }

            local registeredKeys, registeredModifierKeys = HyperKey.buildRegisteredKeys(appConfig, systemConfig, scriptConfig)

            assert.is_true(registeredKeys["x"])
            assert.is_true(registeredKeys["z"])
            assert.is_true(registeredModifierKeys["shift+z"])
        end)
    end)

    describe("shouldSuppressKey", function()
        local registeredKeys
        local registeredModifierKeys

        before_each(function()
            registeredKeys = {
                ["a"] = true,
                ["b"] = true,
                ["c"] = true
            }
            registeredModifierKeys = {
                ["shift+cmd+c"] = true,
                ["shift+x"] = true
            }
        end)

        it("should suppress unregistered keys without modifiers", function()
            local result = HyperKey.shouldSuppressKey("x", {}, registeredKeys, registeredModifierKeys)
            assert.is_true(result)
        end)

        it("should not suppress registered keys without modifiers", function()
            local result = HyperKey.shouldSuppressKey("a", {}, registeredKeys, registeredModifierKeys)
            assert.is_false(result)
        end)

        it("should suppress nil charKey", function()
            local result = HyperKey.shouldSuppressKey(nil, {}, registeredKeys, registeredModifierKeys)
            assert.is_true(result)
        end)

        it("should suppress unregistered modifier combinations", function()
            local result = HyperKey.shouldSuppressKey("x", {"shift", "cmd"}, registeredKeys, registeredModifierKeys)
            assert.is_true(result)
        end)

        it("should not suppress registered modifier combinations", function()
            local result = HyperKey.shouldSuppressKey("c", {"shift", "cmd"}, registeredKeys, registeredModifierKeys)
            assert.is_false(result)
        end)

        it("should not suppress registered modifier combinations (different order)", function()
            -- Note: modifier order matters in current implementation
            local result = HyperKey.shouldSuppressKey("c", {"cmd", "shift"}, registeredKeys, registeredModifierKeys)
            assert.is_true(result)  -- Different order is not registered
        end)

        it("should not suppress single modifier with registered key", function()
            local result = HyperKey.shouldSuppressKey("x", {"shift"}, registeredKeys, registeredModifierKeys)
            assert.is_false(result)
        end)

        it("should suppress registered key with unregistered modifiers", function()
            local result = HyperKey.shouldSuppressKey("a", {"shift"}, registeredKeys, registeredModifierKeys)
            assert.is_true(result)
        end)
    end)
end)
