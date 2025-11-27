-- SystemActions module unit tests

describe("SystemActions", function()
    local SystemActions

    before_each(function()
        -- Reset mocks
        reset_mocks()

        -- Reload SystemActions module for each test
        package.loaded["system_actions"] = nil
        package.loaded["logger"] = nil
        SystemActions = require("system_actions")
    end)

    describe("createActions()", function()
        it("should return a table of actions", function()
            local mockObj = {}
            local mockLogger = { alert = function() end }
            local mockConfigLoader = { saveSettings = function() return true end }
            local mockSettingsUI = { showSettings = function() end }

            local actions = SystemActions.createActions(
                mockObj,
                mockLogger,
                mockConfigLoader,
                mockSettingsUI
            )

            assert.is_table(actions)
        end)

        it("should have all required system actions", function()
            local mockObj = {}
            local mockLogger = { alert = function() end }
            local mockConfigLoader = { saveSettings = function() return true end }
            local mockSettingsUI = { showSettings = function() end }

            local actions = SystemActions.createActions(
                mockObj,
                mockLogger,
                mockConfigLoader,
                mockSettingsUI
            )

            -- Check all required actions exist
            assert.is_not_nil(actions.hammerspoon)
            assert.is_not_nil(actions.reload)
            assert.is_not_nil(actions.settings)
        end)

        it("should have correct structure for each action", function()
            local mockObj = {}
            local mockLogger = { alert = function() end }
            local mockConfigLoader = { saveSettings = function() return true end }
            local mockSettingsUI = { showSettings = function() end }

            local actions = SystemActions.createActions(
                mockObj,
                mockLogger,
                mockConfigLoader,
                mockSettingsUI
            )

            -- Each action should have key, action function, and name
            for _, actionName in ipairs({"hammerspoon", "reload", "settings"}) do
                local action = actions[actionName]
                assert.is_string(action.key, actionName .. " should have a key")
                assert.is_function(action.action, actionName .. " should have an action function")
                assert.is_string(action.name, actionName .. " should have a name")
            end
        end)

        it("should assign unique key combinations (key + modifiers) to each action", function()
            local mockObj = {}
            local mockLogger = { alert = function() end }
            local mockConfigLoader = { saveSettings = function() return true end }
            local mockSettingsUI = { showSettings = function() end }

            local actions = SystemActions.createActions(
                mockObj,
                mockLogger,
                mockConfigLoader,
                mockSettingsUI
            )

            local keyCombinations = {}
            for _, action in pairs(actions) do
                -- Create unique identifier from key + modifiers
                local modifiers = action.modifiers or {}
                table.sort(modifiers)
                local combo = action.key .. "+" .. table.concat(modifiers, "+")

                assert.is_nil(keyCombinations[combo], "Duplicate key combination found: " .. combo)
                keyCombinations[combo] = true
            end
        end)

        it("should have correct key bindings", function()
            local mockObj = {}
            local mockLogger = { alert = function() end }
            local mockConfigLoader = { saveSettings = function() return true end }
            local mockSettingsUI = { showSettings = function() end }

            local actions = SystemActions.createActions(
                mockObj,
                mockLogger,
                mockConfigLoader,
                mockSettingsUI
            )

            -- Verify expected key bindings
            assert.equals("h", actions.hammerspoon.key)
            assert.equals("r", actions.reload.key)
            assert.equals(",", actions.settings.key)
        end)

        it("hammerspoon action should toggle console", function()
            local mockObj = {}
            local mockLogger = { alert = function() end }
            local mockConfigLoader = { saveSettings = function() return true end }
            local mockSettingsUI = { showSettings = function() end }

            local actions = SystemActions.createActions(
                mockObj,
                mockLogger,
                mockConfigLoader,
                mockSettingsUI
            )

            -- Mock hs.toggleConsole
            local toggleCalled = false
            _G.hs.toggleConsole = function()
                toggleCalled = true
            end

            -- Execute action
            actions.hammerspoon.action()

            assert.is_true(toggleCalled)
        end)

        it("reload action should call logger and hs.reload", function()
            local mockObj = {}
            local alertCalled = false
            local alertMessage = ""
            local mockLogger = {
                alert = function(self, msg)
                    alertCalled = true
                    alertMessage = msg
                    assert.is_string(msg)
                end
            }
            local mockConfigLoader = { saveSettings = function() return true end }
            local mockSettingsUI = { showSettings = function() end }

            local actions = SystemActions.createActions(
                mockObj,
                mockLogger,
                mockConfigLoader,
                mockSettingsUI
            )

            -- Mock hs.reload
            local reloadCalled = false
            _G.hs.reload = function()
                reloadCalled = true
            end

            -- Execute action
            actions.reload.action()

            assert.is_true(alertCalled)
            assert.is_true(reloadCalled)
        end)

        it("settings action should call showSettings with correct callbacks", function()
            local mockObj = {}
            local mockLogger = { alert = function() end }
            local mockConfigLoader = {
                saveSettings = function(config)
                    return true
                end
            }

            local showSettingsCalled = false
            local mockSettingsUI = {
                showSettings = function(obj, saveCallback, successCallback)
                    showSettingsCalled = true
                    assert.is_not_nil(obj)
                    assert.is_function(saveCallback)
                    assert.is_function(successCallback)
                end
            }

            local actions = SystemActions.createActions(
                mockObj,
                mockLogger,
                mockConfigLoader,
                mockSettingsUI
            )

            -- Execute action
            actions.settings.action()

            assert.is_true(showSettingsCalled)
        end)

    end)
end)
