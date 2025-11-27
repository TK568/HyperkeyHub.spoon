-- Configuration defaults module
-- Provides default configuration values for HyperkeyHub

--- Commonly used key codes
--- @type table<string, number>
local KEY_CODES = {
    F19 = 80,
    ESC = 53
}

--- Default configuration structure
--- Contains all default settings for HyperkeyHub
--- @class DefaultConfig
--- @field hyperConfig table Hyper key configuration (keyCode, keyCodeToChar)
--- @field appConfig table Application launcher configuration
--- @field systemConfig table System shortcuts and actions configuration
--- @field scriptConfig table Script shortcuts configuration
---
--- Note: systemConfig.functions cannot be defined here because they contain
--- closures that reference 'obj'. These will be initialized in init.lua.
local defaults = {
    showAlerts = "all",  -- "all" | "errors" | "none"
    hyperConfig = {
        keyCode = KEY_CODES.F19,
        keyCodeToChar = {
            [0] = 'a', [1] = 's', [2] = 'd', [3] = 'f', [4] = 'h', [5] = 'g',
            [6] = 'z', [7] = 'x', [8] = 'c', [9] = 'v', [11] = 'b', [12] = 'q',
            [13] = 'w', [14] = 'e', [15] = 'r', [16] = 'y', [17] = 't', [18] = '1',
            [19] = '2', [20] = '3', [21] = '4', [22] = '6', [23] = '5', [24] = '=',
            [25] = '9', [26] = '7', [27] = '-', [28] = '8', [29] = '0', [30] = ']',
            [31] = 'o', [32] = 'u', [33] = '[', [34] = 'i', [35] = 'p', [37] = 'l',
            [38] = 'j', [39] = "'", [40] = 'k', [41] = ';', [42] = '\\', [43] = ',',
            [44] = '/', [45] = 'n', [46] = 'm', [47] = '.', [49] = 'space',
            [123] = 'left', [124] = 'right', [125] = 'down', [126] = 'up'
        }
    },
    appConfig = {
        applications = {
            finder = {
                name = "Finder",
                key = "f",
                bundle = "com.apple.finder",
                modifiers = {}
            },
            safari = {
                name = "Safari",
                key = "s",
                bundle = "com.apple.Safari",
                modifiers = {}
            },
            terminal = {
                name = "Terminal",
                key = "t",
                bundle = "com.apple.Terminal",
                modifiers = {}
            }
        }
    },
    systemConfig = {
        defaultSystemShortcuts = {
            hammerspoon = { key = "h", modifiers = {"shift"} },
            reload = { key = "r", modifiers = {"shift"} },
            debug = { key = "d", modifiers = {"shift"} },
            settings = { key = ",", modifiers = {} }
        },
        systemShortcuts = {},
        functions = {},
        customBindings = {}
    },
    scriptConfig = {
        scriptShortcuts = {}
    }
}

return defaults
