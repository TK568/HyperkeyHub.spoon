describe("Validator", function()
    local Validator

    before_each(function()
        reset_mocks()
        package.loaded["config.validator"] = nil
        Validator = require("config.validator")
    end)

    describe("validateConfig", function()
        describe("basic validation", function()
            it("returns true for valid complete configuration", function()
                local config = {
                    hyperKeyCode = 79,
                    applications = {
                        {name = "Terminal", key = "T", bundle = "com.apple.Terminal"}
                    },
                    window_management = {
                        left = {key = "H"}
                    },
                    system_shortcuts = {
                        reload = {key = "R"}
                    },
                    customBindings = {
                        {key = "X", action = function() end}
                    }
                }
                local success, err = Validator.validateConfig(config)
                assert.is_true(success)
                assert.is_nil(err)
            end)

            it("returns false for nil config", function()
                local success, err = Validator.validateConfig(nil)
                assert.is_false(success)
                assert.equals("Configuration is nil", err)
            end)

            it("returns true for empty config", function()
                local success, err = Validator.validateConfig({})
                assert.is_true(success)
                assert.is_nil(err)
            end)
        end)

        describe("hyperKeyCode validation", function()
            it("accepts valid hyperKeyCode values", function()
                local success, err = Validator.validateConfig({hyperKeyCode = 0})
                assert.is_true(success)

                success, err = Validator.validateConfig({hyperKeyCode = 128})
                assert.is_true(success)

                success, err = Validator.validateConfig({hyperKeyCode = 255})
                assert.is_true(success)
            end)

            it("rejects non-number hyperKeyCode", function()
                local success, err = Validator.validateConfig({hyperKeyCode = "79"})
                assert.is_false(success)
                assert.equals("hyperKeyCode must be a number", err)
            end)

            it("rejects hyperKeyCode below 0", function()
                local success, err = Validator.validateConfig({hyperKeyCode = -1})
                assert.is_false(success)
                assert.equals("hyperKeyCode must be between 0 and 255", err)
            end)

            it("rejects hyperKeyCode above 255", function()
                local success, err = Validator.validateConfig({hyperKeyCode = 256})
                assert.is_false(success)
                assert.equals("hyperKeyCode must be between 0 and 255", err)

                success, err = Validator.validateConfig({hyperKeyCode = 1000})
                assert.is_false(success)
                assert.equals("hyperKeyCode must be between 0 and 255", err)
            end)
        end)

        describe("showAlerts validation", function()
            it("accepts valid string values", function()
                local success, err = Validator.validateConfig({showAlerts = "all"})
                assert.is_true(success)
                assert.is_nil(err)

                success, err = Validator.validateConfig({showAlerts = "errors"})
                assert.is_true(success)
                assert.is_nil(err)

                success, err = Validator.validateConfig({showAlerts = "none"})
                assert.is_true(success)
                assert.is_nil(err)
            end)

            it("accepts boolean values for backward compatibility", function()
                local success, err = Validator.validateConfig({showAlerts = true})
                assert.is_true(success)
                assert.is_nil(err)

                success, err = Validator.validateConfig({showAlerts = false})
                assert.is_true(success)
                assert.is_nil(err)
            end)

            it("accepts config without showAlerts", function()
                local success, err = Validator.validateConfig({})
                assert.is_true(success)
                assert.is_nil(err)
            end)

            it("rejects invalid string values", function()
                local success, err = Validator.validateConfig({showAlerts = "invalid"})
                assert.is_false(success)
                assert.equals("showAlerts must be 'all', 'errors', or 'none'", err)
            end)

            it("rejects non-string non-boolean values", function()
                local success, err = Validator.validateConfig({showAlerts = 1})
                assert.is_false(success)
                assert.equals("showAlerts must be 'all', 'errors', or 'none'", err)
            end)
        end)

        describe("applications validation", function()
            it("accepts valid applications", function()
                local config = {
                    applications = {
                        {name = "Terminal", key = "T", bundle = "com.apple.Terminal"},
                        {name = "Finder", key = "F", bundle = "com.apple.finder", modifiers = {"cmd"}},
                        {name = "Safari", key = "S", bundle = "com.apple.Safari", modifiers = {"cmd", "shift"}}
                    }
                }
                local success, err = Validator.validateConfig(config)
                assert.is_true(success)
                assert.is_nil(err)
            end)

            it("rejects non-table applications", function()
                local success, err = Validator.validateConfig({applications = "invalid"})
                assert.is_false(success)
                assert.equals("applications must be a table", err)
            end)

            it("rejects non-table application entry", function()
                local config = {
                    applications = {"invalid"}
                }
                local success, err = Validator.validateConfig(config)
                assert.is_false(success)
                assert.equals("Application at index 1 must be a table", err)
            end)

            it("rejects application without name", function()
                local config = {
                    applications = {
                        {key = "T", bundle = "com.apple.Terminal"}
                    }
                }
                local success, err = Validator.validateConfig(config)
                assert.is_false(success)
                assert.equals("Application at index 1 is missing valid 'name' (string)", err)
            end)

            it("rejects application with non-string name", function()
                local config = {
                    applications = {
                        {name = 123, key = "T", bundle = "com.apple.Terminal"}
                    }
                }
                local success, err = Validator.validateConfig(config)
                assert.is_false(success)
                assert.equals("Application at index 1 is missing valid 'name' (string)", err)
            end)

            it("rejects application without key", function()
                local config = {
                    applications = {
                        {name = "Terminal", bundle = "com.apple.Terminal"}
                    }
                }
                local success, err = Validator.validateConfig(config)
                assert.is_false(success)
                assert.equals("Application 'Terminal' is missing valid 'key' (string)", err)
            end)

            it("rejects application with non-string key", function()
                local config = {
                    applications = {
                        {name = "Terminal", key = 123, bundle = "com.apple.Terminal"}
                    }
                }
                local success, err = Validator.validateConfig(config)
                assert.is_false(success)
                assert.equals("Application 'Terminal' is missing valid 'key' (string)", err)
            end)

            it("rejects application without bundle", function()
                local config = {
                    applications = {
                        {name = "Terminal", key = "T"}
                    }
                }
                local success, err = Validator.validateConfig(config)
                assert.is_false(success)
                assert.equals("Application 'Terminal' is missing valid 'bundle' (string)", err)
            end)

            it("rejects application with non-string bundle", function()
                local config = {
                    applications = {
                        {name = "Terminal", key = "T", bundle = 123}
                    }
                }
                local success, err = Validator.validateConfig(config)
                assert.is_false(success)
                assert.equals("Application 'Terminal' is missing valid 'bundle' (string)", err)
            end)

            it("rejects application with non-table modifiers", function()
                local config = {
                    applications = {
                        {name = "Terminal", key = "T", bundle = "com.apple.Terminal", modifiers = "cmd"}
                    }
                }
                local success, err = Validator.validateConfig(config)
                assert.is_false(success)
                assert.equals("Application 'Terminal' has invalid 'modifiers' (must be table)", err)
            end)

            it("rejects application with invalid modifier", function()
                local config = {
                    applications = {
                        {name = "Terminal", key = "T", bundle = "com.apple.Terminal", modifiers = {"invalid"}}
                    }
                }
                local success, err = Validator.validateConfig(config)
                assert.is_false(success)
                assert.equals("Application 'Terminal' has invalid modifier 'invalid' (must be cmd, alt, shift, or ctrl)", err)
            end)

            it("accepts all valid modifiers", function()
                local config = {
                    applications = {
                        {name = "Test", key = "T", bundle = "test", modifiers = {"cmd", "alt", "shift", "ctrl"}}
                    }
                }
                local success, err = Validator.validateConfig(config)
                assert.is_true(success)
                assert.is_nil(err)
            end)
        end)

        describe("window_management validation", function()
            it("accepts valid window_management configuration", function()
                local config = {
                    window_management = {
                        left = {key = "H"},
                        right = {key = "L"},
                        maximize = {key = "M", modifiers = {"cmd"}},
                        center = {key = "C"},
                        leftThird = {key = "1"},
                        centerThird = {key = "2"},
                        rightThird = {key = "3"},
                        leftTwoThirds = {key = "4"},
                        rightTwoThirds = {key = "5"},
                        topHalf = {key = "K"},
                        bottomHalf = {key = "J"},
                        topLeftQuarter = {key = "U"},
                        topRightQuarter = {key = "I"},
                        bottomLeftQuarter = {key = "N"},
                        bottomRightQuarter = {key = "M"}
                    }
                }
                local success, err = Validator.validateConfig(config)
                assert.is_true(success)
                assert.is_nil(err)
            end)

            it("rejects non-table window_management", function()
                local success, err = Validator.validateConfig({window_management = "invalid"})
                assert.is_false(success)
                assert.equals("window_management must be a table", err)
            end)

            it("rejects invalid window_management action", function()
                local config = {
                    window_management = {
                        invalid_action = {key = "X"}
                    }
                }
                local success, err = Validator.validateConfig(config)
                assert.is_false(success)
                assert.equals("Invalid window management action: 'invalid_action'", err)
            end)

            it("rejects non-table binding", function()
                local config = {
                    window_management = {
                        left = "invalid"
                    }
                }
                local success, err = Validator.validateConfig(config)
                assert.is_false(success)
                assert.equals("Window management 'left' binding must be a table", err)
            end)

            it("rejects binding without key", function()
                local config = {
                    window_management = {
                        left = {}
                    }
                }
                local success, err = Validator.validateConfig(config)
                assert.is_false(success)
                assert.equals("Window management 'left' is missing valid 'key' (string)", err)
            end)

            it("rejects binding with non-string key", function()
                local config = {
                    window_management = {
                        left = {key = 123}
                    }
                }
                local success, err = Validator.validateConfig(config)
                assert.is_false(success)
                assert.equals("Window management 'left' is missing valid 'key' (string)", err)
            end)

            it("rejects non-table modifiers", function()
                local config = {
                    window_management = {
                        left = {key = "H", modifiers = "cmd"}
                    }
                }
                local success, err = Validator.validateConfig(config)
                assert.is_false(success)
                assert.equals("Window management 'left' has invalid 'modifiers' (must be table)", err)
            end)

            it("rejects invalid modifier", function()
                local config = {
                    window_management = {
                        left = {key = "H", modifiers = {"invalid"}}
                    }
                }
                local success, err = Validator.validateConfig(config)
                assert.is_false(success)
                assert.matches("Window management 'left' has invalid modifier 'invalid'", err)
            end)
        end)

        describe("system_shortcuts validation", function()
            it("accepts valid system_shortcuts configuration", function()
                local config = {
                    system_shortcuts = {
                        hammerspoon = {key = "H"},
                        reload = {key = "R"},
                        debug = {key = "D"},
                        settings = {key = "S", modifiers = {"cmd"}},
                        quit = {key = "Q"},
                        saveWindowPosition = {key = "1"},
                        restoreWindowPosition = {key = "2"}
                    }
                }
                local success, err = Validator.validateConfig(config)
                assert.is_true(success)
                assert.is_nil(err)
            end)

            it("accepts systemShortcuts (camelCase)", function()
                local config = {
                    systemShortcuts = {
                        reload = {key = "R"}
                    }
                }
                local success, err = Validator.validateConfig(config)
                assert.is_true(success)
                assert.is_nil(err)
            end)

            it("rejects non-table system_shortcuts", function()
                local success, err = Validator.validateConfig({system_shortcuts = "invalid"})
                assert.is_false(success)
                assert.equals("system_shortcuts must be a table", err)
            end)

            it("rejects invalid system_shortcuts action", function()
                local config = {
                    system_shortcuts = {
                        invalid_action = {key = "X"}
                    }
                }
                local success, err = Validator.validateConfig(config)
                assert.is_false(success)
                assert.equals("Invalid system shortcut action: 'invalid_action'", err)
            end)

            it("rejects non-table binding", function()
                local config = {
                    system_shortcuts = {
                        reload = "invalid"
                    }
                }
                local success, err = Validator.validateConfig(config)
                assert.is_false(success)
                assert.equals("System shortcut 'reload' binding must be a table", err)
            end)

            it("rejects binding without key", function()
                local config = {
                    system_shortcuts = {
                        reload = {}
                    }
                }
                local success, err = Validator.validateConfig(config)
                assert.is_false(success)
                assert.equals("System shortcut 'reload' is missing valid 'key' (string)", err)
            end)

            it("rejects binding with non-string key", function()
                local config = {
                    system_shortcuts = {
                        reload = {key = 123}
                    }
                }
                local success, err = Validator.validateConfig(config)
                assert.is_false(success)
                assert.equals("System shortcut 'reload' is missing valid 'key' (string)", err)
            end)

            it("rejects non-table modifiers", function()
                local config = {
                    system_shortcuts = {
                        reload = {key = "R", modifiers = "cmd"}
                    }
                }
                local success, err = Validator.validateConfig(config)
                assert.is_false(success)
                assert.equals("System shortcut 'reload' has invalid 'modifiers' (must be table)", err)
            end)

            it("rejects invalid modifier", function()
                local config = {
                    system_shortcuts = {
                        reload = {key = "R", modifiers = {"invalid"}}
                    }
                }
                local success, err = Validator.validateConfig(config)
                assert.is_false(success)
                assert.matches("System shortcut 'reload' has invalid modifier 'invalid'", err)
            end)
        end)

        describe("customBindings validation", function()
            it("accepts valid customBindings configuration", function()
                local config = {
                    customBindings = {
                        {key = "X", action = function() end},
                        {key = "Y", action = function() end, mods = {"cmd"}},
                        {key = "Z", action = function() end, mods = {"cmd", "shift"}}
                    }
                }
                local success, err = Validator.validateConfig(config)
                assert.is_true(success)
                assert.is_nil(err)
            end)

            it("rejects non-table customBindings", function()
                local success, err = Validator.validateConfig({customBindings = "invalid"})
                assert.is_false(success)
                assert.equals("customBindings must be a table", err)
            end)

            it("rejects non-table binding entry", function()
                local config = {
                    customBindings = {"invalid"}
                }
                local success, err = Validator.validateConfig(config)
                assert.is_false(success)
                assert.equals("Custom binding at index 1 must be a table", err)
            end)

            it("rejects binding without key", function()
                local config = {
                    customBindings = {
                        {action = function() end}
                    }
                }
                local success, err = Validator.validateConfig(config)
                assert.is_false(success)
                assert.equals("Custom binding at index 1 is missing valid 'key' (string)", err)
            end)

            it("rejects binding with non-string key", function()
                local config = {
                    customBindings = {
                        {key = 123, action = function() end}
                    }
                }
                local success, err = Validator.validateConfig(config)
                assert.is_false(success)
                assert.equals("Custom binding at index 1 is missing valid 'key' (string)", err)
            end)

            it("rejects binding without action", function()
                local config = {
                    customBindings = {
                        {key = "X"}
                    }
                }
                local success, err = Validator.validateConfig(config)
                assert.is_false(success)
                assert.equals("Custom binding at index 1 is missing valid 'action' (function)", err)
            end)

            it("rejects binding with non-function action", function()
                local config = {
                    customBindings = {
                        {key = "X", action = "invalid"}
                    }
                }
                local success, err = Validator.validateConfig(config)
                assert.is_false(success)
                assert.equals("Custom binding at index 1 is missing valid 'action' (function)", err)
            end)

            it("rejects non-table mods", function()
                local config = {
                    customBindings = {
                        {key = "X", action = function() end, mods = "cmd"}
                    }
                }
                local success, err = Validator.validateConfig(config)
                assert.is_false(success)
                assert.equals("Custom binding at index 1 has invalid 'mods' (must be table)", err)
            end)
        end)
    end)
end)
