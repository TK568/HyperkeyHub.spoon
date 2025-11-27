-- Logger module unit tests

describe("Logger", function()
    local Logger

    before_each(function()
        reset_mocks()
        package.loaded["logger"] = nil
        Logger = require("logger")
    end)

    describe("Logger.new", function()
        it("tracks created instances", function()
            local initialCount = #Logger.instances
            local instance = Logger.new("SystemModule")

            assert.equals(initialCount + 1, #Logger.instances)
            local record = Logger.instances[#Logger.instances]
            assert.equals("SystemModule", record.name)
            assert.equals(instance, record.instance)
        end)
    end)

    describe("Logger.setGlobalLevel", function()
        it("sets the log level to debug", function()
            Logger.setGlobalLevel("debug")
            assert.equals(Logger.DEBUG, Logger.level)

            local lastLog = hammerspoon_mock.printf_calls[#hammerspoon_mock.printf_calls]
            assert.is_truthy(lastLog:match("Global log level set to debug"))
        end)

        it("accepts mixed-case level names", function()
            Logger.setGlobalLevel("WARN")
            assert.equals(Logger.WARN, Logger.level)
        end)

        it("logs the number of tracked instances", function()
            -- Create two more instances (global logger is already registered)
            Logger.new("ModuleA")
            Logger.new("ModuleB")

            Logger.setGlobalLevel("info")

            local lastLog = hammerspoon_mock.printf_calls[#hammerspoon_mock.printf_calls]
            assert.is_truthy(lastLog:match("Global log level set to info"))
            assert.is_truthy(lastLog:match("3 instances"))
        end)

        it("warns when an unknown log level is provided", function()
            local previousLevel = Logger.DEBUG
            Logger.level = previousLevel
            Logger.setGlobalLevel("verbose")

            assert.equals(previousLevel, Logger.level)
            assert.is_true(#hammerspoon_mock.printf_calls > 0)
            local lastLog = hammerspoon_mock.printf_calls[#hammerspoon_mock.printf_calls]
            assert.is_truthy(lastLog:match("Unknown log level"))
        end)
    end)
end)
