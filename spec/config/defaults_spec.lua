describe("Defaults", function()
    local Defaults

    before_each(function()
        package.loaded["config.defaults"] = nil
        Defaults = require("config.defaults")
    end)

    describe("Module Structure", function()
        it("returns a table", function()
            assert.is_table(Defaults)
        end)

        it("contains all required top-level keys", function()
            assert.is_not_nil(Defaults.hyperConfig)
            assert.is_not_nil(Defaults.appConfig)
            assert.is_not_nil(Defaults.systemConfig)
            assert.is_not_nil(Defaults.scriptConfig)
        end)

        it("has correct types for top-level sections", function()
            assert.is_table(Defaults.hyperConfig)
            assert.is_table(Defaults.appConfig)
            assert.is_table(Defaults.systemConfig)
            assert.is_table(Defaults.scriptConfig)
        end)
    end)

    describe("hyperConfig", function()
        it("has keyCode defined", function()
            assert.is_not_nil(Defaults.hyperConfig.keyCode)
            assert.is_number(Defaults.hyperConfig.keyCode)
        end)

        it("has F19 as default keyCode (80)", function()
            assert.equals(80, Defaults.hyperConfig.keyCode)
        end)

        it("has keyCodeToChar mapping", function()
            assert.is_not_nil(Defaults.hyperConfig.keyCodeToChar)
            assert.is_table(Defaults.hyperConfig.keyCodeToChar)
        end)

        it("has essential key mappings", function()
            local keyMap = Defaults.hyperConfig.keyCodeToChar
            assert.equals('a', keyMap[0])
            assert.equals('s', keyMap[1])
            assert.equals('space', keyMap[49])
            assert.equals('left', keyMap[123])
            assert.equals('right', keyMap[124])
            assert.equals('down', keyMap[125])
            assert.equals('up', keyMap[126])
        end)

        it("has all alphabet keys mapped", function()
            local keyMap = Defaults.hyperConfig.keyCodeToChar
            local alphabetKeys = {'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'}
            local foundCount = 0

            for _, value in pairs(keyMap) do
                for _, letter in ipairs(alphabetKeys) do
                    if value == letter then
                        foundCount = foundCount + 1
                        break
                    end
                end
            end

            assert.is_true(foundCount >= 26)
        end)

        it("has number keys mapped", function()
            local keyMap = Defaults.hyperConfig.keyCodeToChar
            local numberKeys = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'}
            local foundCount = 0

            for _, value in pairs(keyMap) do
                for _, number in ipairs(numberKeys) do
                    if value == number then
                        foundCount = foundCount + 1
                        break
                    end
                end
            end

            assert.equals(10, foundCount)
        end)

        it("has arrow keys mapped", function()
            local keyMap = Defaults.hyperConfig.keyCodeToChar
            assert.equals('left', keyMap[123])
            assert.equals('right', keyMap[124])
            assert.equals('down', keyMap[125])
            assert.equals('up', keyMap[126])
        end)
    end)

    describe("appConfig", function()
        it("has applications table", function()
            assert.is_not_nil(Defaults.appConfig.applications)
            assert.is_table(Defaults.appConfig.applications)
        end)

        it("has default applications defined", function()
            local apps = Defaults.appConfig.applications
            assert.is_not_nil(apps.finder)
            assert.is_not_nil(apps.safari)
            assert.is_not_nil(apps.terminal)
        end)

        it("finder has correct configuration", function()
            local finder = Defaults.appConfig.applications.finder
            assert.equals("Finder", finder.name)
            assert.equals("f", finder.key)
            assert.equals("com.apple.finder", finder.bundle)
            assert.is_table(finder.modifiers)
            assert.equals(0, #finder.modifiers)
        end)

        it("safari has correct configuration", function()
            local safari = Defaults.appConfig.applications.safari
            assert.equals("Safari", safari.name)
            assert.equals("s", safari.key)
            assert.equals("com.apple.Safari", safari.bundle)
            assert.is_table(safari.modifiers)
            assert.equals(0, #safari.modifiers)
        end)

        it("terminal has correct configuration", function()
            local terminal = Defaults.appConfig.applications.terminal
            assert.equals("Terminal", terminal.name)
            assert.equals("t", terminal.key)
            assert.equals("com.apple.Terminal", terminal.bundle)
            assert.is_table(terminal.modifiers)
            assert.equals(0, #terminal.modifiers)
        end)

        it("all applications have required fields", function()
            local apps = Defaults.appConfig.applications
            for appId, app in pairs(apps) do
                assert.is_not_nil(app.name, "Missing name for " .. appId)
                assert.is_not_nil(app.key, "Missing key for " .. appId)
                assert.is_not_nil(app.bundle, "Missing bundle for " .. appId)
                assert.is_not_nil(app.modifiers, "Missing modifiers for " .. appId)
                assert.is_table(app.modifiers, "Modifiers should be table for " .. appId)
            end
        end)
    end)

    describe("systemConfig", function()
        it("has all required keys", function()
            assert.is_not_nil(Defaults.systemConfig.defaultSystemShortcuts)
            assert.is_not_nil(Defaults.systemConfig.systemShortcuts)
            assert.is_not_nil(Defaults.systemConfig.functions)
            assert.is_not_nil(Defaults.systemConfig.customBindings)
        end)

        it("has correct types for systemConfig keys", function()
            assert.is_table(Defaults.systemConfig.defaultSystemShortcuts)
            assert.is_table(Defaults.systemConfig.systemShortcuts)
            assert.is_table(Defaults.systemConfig.functions)
            assert.is_table(Defaults.systemConfig.customBindings)
        end)

        it("has default system shortcuts defined", function()
            local shortcuts = Defaults.systemConfig.defaultSystemShortcuts
            assert.is_not_nil(shortcuts.hammerspoon)
            assert.is_not_nil(shortcuts.reload)
            assert.is_not_nil(shortcuts.debug)
            assert.is_not_nil(shortcuts.settings)
        end)

        it("hammerspoon shortcut has correct configuration", function()
            local shortcut = Defaults.systemConfig.defaultSystemShortcuts.hammerspoon
            assert.equals("h", shortcut.key)
            assert.is_table(shortcut.modifiers)
            assert.equals(1, #shortcut.modifiers)
            assert.equals("shift", shortcut.modifiers[1])
        end)

        it("reload shortcut has correct configuration", function()
            local shortcut = Defaults.systemConfig.defaultSystemShortcuts.reload
            assert.equals("r", shortcut.key)
            assert.is_table(shortcut.modifiers)
            assert.equals(1, #shortcut.modifiers)
            assert.equals("shift", shortcut.modifiers[1])
        end)

        it("debug shortcut has correct configuration", function()
            local shortcut = Defaults.systemConfig.defaultSystemShortcuts.debug
            assert.equals("d", shortcut.key)
            assert.is_table(shortcut.modifiers)
            assert.equals(1, #shortcut.modifiers)
            assert.equals("shift", shortcut.modifiers[1])
        end)

        it("settings shortcut has correct configuration", function()
            local shortcut = Defaults.systemConfig.defaultSystemShortcuts.settings
            assert.equals(",", shortcut.key)
            assert.is_table(shortcut.modifiers)
            assert.equals(0, #shortcut.modifiers)
        end)

        it("systemShortcuts is empty by default", function()
            local count = 0
            for _ in pairs(Defaults.systemConfig.systemShortcuts) do
                count = count + 1
            end
            assert.equals(0, count)
        end)

        it("functions is empty by default", function()
            local count = 0
            for _ in pairs(Defaults.systemConfig.functions) do
                count = count + 1
            end
            assert.equals(0, count)
        end)

        it("customBindings is empty by default", function()
            assert.equals(0, #Defaults.systemConfig.customBindings)
        end)
    end)

    describe("scriptConfig", function()
        it("has scriptShortcuts table", function()
            assert.is_not_nil(Defaults.scriptConfig.scriptShortcuts)
            assert.is_table(Defaults.scriptConfig.scriptShortcuts)
        end)

        it("scriptShortcuts is empty by default", function()
            local count = 0
            for _ in pairs(Defaults.scriptConfig.scriptShortcuts) do
                count = count + 1
            end
            assert.equals(0, count)
        end)
    end)

    describe("Data Integrity", function()
        it("does not contain nil values in hyperConfig.keyCodeToChar", function()
            for key, value in pairs(Defaults.hyperConfig.keyCodeToChar) do
                assert.is_not_nil(value, "Key " .. key .. " has nil value")
                assert.is_string(value, "Key " .. key .. " should map to string")
            end
        end)

        it("has unique key bindings in default applications", function()
            local usedKeys = {}
            for appId, app in pairs(Defaults.appConfig.applications) do
                local keyCombo = app.key .. table.concat(app.modifiers or {}, ",")
                assert.is_nil(usedKeys[keyCombo], "Duplicate key binding: " .. keyCombo .. " (" .. appId .. ")")
                usedKeys[keyCombo] = appId
            end
        end)

        it("has unique key bindings in default system shortcuts", function()
            local usedKeys = {}
            for shortcutId, shortcut in pairs(Defaults.systemConfig.defaultSystemShortcuts) do
                local keyCombo = shortcut.key .. table.concat(shortcut.modifiers or {}, ",")
                assert.is_nil(usedKeys[keyCombo], "Duplicate key binding: " .. keyCombo .. " (" .. shortcutId .. ")")
                usedKeys[keyCombo] = shortcutId
            end
        end)

        it("does not have conflicts between app and system shortcuts", function()
            local appKeys = {}
            for _, app in pairs(Defaults.appConfig.applications) do
                local keyCombo = app.key .. table.concat(app.modifiers or {}, ",")
                appKeys[keyCombo] = true
            end

            for shortcutId, shortcut in pairs(Defaults.systemConfig.defaultSystemShortcuts) do
                local keyCombo = shortcut.key .. table.concat(shortcut.modifiers or {}, ",")
                assert.is_nil(appKeys[keyCombo], "Key conflict: " .. keyCombo .. " (" .. shortcutId .. ")")
            end
        end)
    end)
end)
