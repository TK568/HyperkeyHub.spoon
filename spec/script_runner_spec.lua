-- ScriptRunner module unit tests

describe("ScriptRunner", function()
    local ScriptRunner
    local EventBus
    local scriptExecuteCalls
    local originalIoOpen
    local originalOsGetenv

    before_each(function()
        reset_mocks()
        package.loaded["script_runner"] = nil
        package.loaded["event_bus"] = nil
        package.loaded["logger"] = nil

        scriptExecuteCalls = {}

        -- Save original functions
        originalIoOpen = _G.io.open
        originalOsGetenv = _G.os.getenv

        -- Mock hs.task.new
        -- Both shell scripts and AppleScripts now use hs.task.new
        _G.hs.task = {
            new = function(command, callback, args)
                local execType = "shell"
                if command == "/usr/bin/osascript" then
                    execType = "applescript"
                end
                table.insert(scriptExecuteCalls, {
                    type = execType,
                    command = command,
                    args = args
                })
                return {
                    waitUntilExit = function()
                        return 0  -- Success exit code
                    end,
                    start = function() end
                }
            end
        }

        -- Mock hs.inspect
        _G.hs.inspect = function(obj)
            return tostring(obj)
        end

        -- Mock io.open for file existence checks
        _G.io.open = function(path, mode)
            if mode == "r" then
                -- Return mock file object
                return {
                    close = function() end,
                    read = function(self, arg)
                        if arg == "*a" then
                            return "mock script content"
                        end
                    end
                }
            end
            return nil
        end

        -- Mock os.getenv
        _G.os.getenv = function(var)
            if var == "HOME" then
                return "/Users/testuser"
            end
            return nil
        end

        EventBus = require("event_bus")
        ScriptRunner = require("script_runner")
    end)

    after_each(function()
        -- Restore original functions
        _G.io.open = originalIoOpen
        _G.os.getenv = originalOsGetenv
    end)

    describe("init", function()
        it("initializes with event bus", function()
            local eventBus = EventBus:new()
            local result = ScriptRunner:init(eventBus)

            assert.are.equal(ScriptRunner, result)
            assert.are.equal(eventBus, ScriptRunner.eventBus)
        end)
    end)

    describe("script:execute event", function()
        local eventBus

        before_each(function()
            eventBus = EventBus:new()
            ScriptRunner:init(eventBus)
        end)

        it("executes inline shell script", function()
            eventBus:emit("script:execute", {
                type = "shell",
                script_inline = "echo 'Hello World'",
                name = "Test Script"
            })

            assert.are.equal(1, #scriptExecuteCalls)
            assert.are.equal("shell", scriptExecuteCalls[1].type)
        end)

        it("executes shell script from file path", function()
            eventBus:emit("script:execute", {
                type = "shell",
                script_path = "~/.scripts/test.sh",
                name = "Test Script"
            })

            assert.are.equal(1, #scriptExecuteCalls)
            assert.are.equal("shell", scriptExecuteCalls[1].type)
            assert.are.equal("/bin/bash", scriptExecuteCalls[1].command)
            -- Check that path expansion occurred in args
            assert.are.equal("/Users/testuser/.scripts/test.sh", scriptExecuteCalls[1].args[1])
        end)

        it("executes inline AppleScript", function()
            eventBus:emit("script:execute", {
                type = "applescript",
                script_inline = "display notification 'Hello'",
                name = "Test Notification"
            })

            assert.are.equal(1, #scriptExecuteCalls)
            assert.are.equal("applescript", scriptExecuteCalls[1].type)
            assert.are.equal("/usr/bin/osascript", scriptExecuteCalls[1].command)
            -- Verify script is passed with -e flag
            assert.are.equal("-e", scriptExecuteCalls[1].args[1])
            assert.are.equal("display notification 'Hello'", scriptExecuteCalls[1].args[2])
        end)

        it("executes AppleScript from file path", function()
            eventBus:emit("script:execute", {
                type = "applescript",
                script_path = "~/.scripts/test.scpt",
                name = "Test AppleScript"
            })

            assert.are.equal(1, #scriptExecuteCalls)
            assert.are.equal("applescript", scriptExecuteCalls[1].type)
            assert.are.equal("/usr/bin/osascript", scriptExecuteCalls[1].command)
            -- Check that path expansion occurred in args
            assert.are.equal("/Users/testuser/.scripts/test.scpt", scriptExecuteCalls[1].args[1])
        end)

        it("defaults to shell type when type is not specified", function()
            eventBus:emit("script:execute", {
                script_inline = "echo 'test'",
                name = "Test"
            })

            assert.are.equal(1, #scriptExecuteCalls)
            assert.are.equal("shell", scriptExecuteCalls[1].type)
        end)

        it("handles missing script path and inline gracefully", function()
            local alertCalls = {}
            local originalAlertShow = _G.hs.alert.show

            _G.hs.alert.show = function(msg)
                table.insert(alertCalls, msg)
            end

            eventBus:emit("script:execute", {
                type = "shell",
                name = "Invalid Script"
            })

            _G.hs.alert.show = originalAlertShow
        end)

        it("handles unknown script type", function()
            local alertCalls = {}
            local originalAlertShow = _G.hs.alert.show

            _G.hs.alert.show = function(msg)
                table.insert(alertCalls, msg)
            end

            eventBus:emit("script:execute", {
                type = "unknown",
                script_inline = "test",
                name = "Invalid Type Script"
            })

            assert.is_true(#alertCalls > 0)

            _G.hs.alert.show = originalAlertShow
        end)

        it("handles file not found for shell script", function()
            local originalIoOpen = _G.io.open
            local originalAlertShow = _G.hs.alert.show

            _G.io.open = function(path, mode)
                return nil
            end

            local alertCalls = {}
            _G.hs.alert.show = function(msg)
                table.insert(alertCalls, msg)
            end

            eventBus:emit("script:execute", {
                type = "shell",
                script_path = "/nonexistent/script.sh",
                name = "Missing Script"
            })

            assert.is_true(#alertCalls > 0)

            _G.io.open = originalIoOpen
            _G.hs.alert.show = originalAlertShow
        end)

        it("passes arguments to shell script from file", function()
            eventBus:emit("script:execute", {
                type = "shell",
                script_path = "~/test.sh",
                args = {"arg1", "arg2", "arg3"},
                name = "Test with Args"
            })

            assert.are.equal(1, #scriptExecuteCalls)
            -- Verify args are passed in the correct order
            assert.are.equal("/Users/testuser/test.sh", scriptExecuteCalls[1].args[1])
            assert.are.equal("arg1", scriptExecuteCalls[1].args[2])
            assert.are.equal("arg2", scriptExecuteCalls[1].args[3])
            assert.are.equal("arg3", scriptExecuteCalls[1].args[4])
        end)

        it("passes arguments to AppleScript from file", function()
            eventBus:emit("script:execute", {
                type = "applescript",
                script_path = "~/test.scpt",
                args = {"Message", "Title"},
                name = "Test AppleScript with Args"
            })

            assert.are.equal(1, #scriptExecuteCalls)
            -- Verify args are passed in the correct order
            assert.are.equal("/Users/testuser/test.scpt", scriptExecuteCalls[1].args[1])
            assert.are.equal("Message", scriptExecuteCalls[1].args[2])
            assert.are.equal("Title", scriptExecuteCalls[1].args[3])
        end)

        it("executes Lua script with arguments", function()
            local luaExecuted = false
            local receivedArgs = {}
            local originalLoadfile = _G.loadfile

            -- Mock loadfile for Lua script execution
            _G.loadfile = function(path)
                return function(...)
                    luaExecuted = true
                    receivedArgs = {...}
                end, nil
            end

            eventBus:emit("script:execute", {
                type = "lua",
                script_path = "~/test.lua",
                args = {"move", "0", "0", "0.5", "1"},
                name = "Test Lua Script"
            })

            assert.is_true(luaExecuted)
            assert.are.equal(5, #receivedArgs)
            assert.are.equal("move", receivedArgs[1])
            assert.are.equal("0", receivedArgs[2])
            assert.are.equal("0.5", receivedArgs[4])

            _G.loadfile = originalLoadfile
        end)

        it("executes inline Lua script with arguments", function()
            local luaExecuted = false
            local receivedArgs = {}
            local originalLoad = _G.load

            -- Mock load for inline Lua script execution
            _G.load = function(code)
                return function(...)
                    luaExecuted = true
                    receivedArgs = {...}
                end, nil
            end

            eventBus:emit("script:execute", {
                type = "lua",
                script_inline = "local args = {...}; hs.alert.show(args[1])",
                args = {"Hello", "World"},
                name = "Inline Lua Test"
            })

            assert.is_true(luaExecuted)
            assert.are.equal(2, #receivedArgs)
            assert.are.equal("Hello", receivedArgs[1])
            assert.are.equal("World", receivedArgs[2])

            _G.load = originalLoad
        end)
    end)

    describe("Security tests", function()
        local eventBus

        before_each(function()
            eventBus = EventBus:new()
            ScriptRunner:init(eventBus)
        end)

        it("safely handles shell injection attempt with semicolon", function()
            eventBus:emit("script:execute", {
                type = "shell",
                script_path = "~/test.sh",
                args = {"arg1; rm -rf /", "arg2"},
                name = "Injection Test"
            })

            assert.are.equal(1, #scriptExecuteCalls)
            -- Verify that the malicious argument is passed as-is to args array
            -- hs.task.new will NOT execute the rm command because args are separate
            assert.are.equal("arg1; rm -rf /", scriptExecuteCalls[1].args[2])
            assert.are.equal("arg2", scriptExecuteCalls[1].args[3])
        end)

        it("safely handles shell injection attempt with backticks", function()
            eventBus:emit("script:execute", {
                type = "shell",
                script_inline = "echo test",
                args = {"`whoami`"},
                name = "Backtick Injection Test"
            })

            assert.are.equal(1, #scriptExecuteCalls)
            -- Verify backticks are treated as literal string
            assert.are.equal("`whoami`", scriptExecuteCalls[1].args[3])
        end)

        it("safely handles arguments with single quotes", function()
            eventBus:emit("script:execute", {
                type = "shell",
                script_path = "~/test.sh",
                args = {"it's a test", "another'quote"},
                name = "Quote Test"
            })

            assert.are.equal(1, #scriptExecuteCalls)
            -- Verify quotes are preserved exactly
            assert.are.equal("it's a test", scriptExecuteCalls[1].args[2])
            assert.are.equal("another'quote", scriptExecuteCalls[1].args[3])
        end)

        it("safely handles arguments with double quotes", function()
            eventBus:emit("script:execute", {
                type = "shell",
                script_path = "~/test.sh",
                args = {"test \"quoted\" value"},
                name = "Double Quote Test"
            })

            assert.are.equal(1, #scriptExecuteCalls)
            assert.are.equal("test \"quoted\" value", scriptExecuteCalls[1].args[2])
        end)

        it("safely handles arguments with dollar signs", function()
            eventBus:emit("script:execute", {
                type = "shell",
                script_path = "~/test.sh",
                args = {"$HOME", "$(pwd)", "${USER}"},
                name = "Dollar Sign Test"
            })

            assert.are.equal(1, #scriptExecuteCalls)
            -- Verify dollar signs are treated as literal strings
            assert.are.equal("$HOME", scriptExecuteCalls[1].args[2])
            assert.are.equal("$(pwd)", scriptExecuteCalls[1].args[3])
            assert.are.equal("${USER}", scriptExecuteCalls[1].args[4])
        end)

        it("safely handles AppleScript injection attempts", function()
            eventBus:emit("script:execute", {
                type = "applescript",
                script_inline = "display notification 'test'",
                args = {"'; do shell script \"rm -rf /\""},
                name = "AppleScript Injection Test"
            })

            assert.are.equal(1, #scriptExecuteCalls)
            assert.are.equal("applescript", scriptExecuteCalls[1].type)
            -- Verify the malicious arg is passed as-is
            assert.are.equal("'; do shell script \"rm -rf /\"", scriptExecuteCalls[1].args[3])
        end)

        it("safely handles newlines in arguments", function()
            eventBus:emit("script:execute", {
                type = "shell",
                script_path = "~/test.sh",
                args = {"line1\nrm -rf /"},
                name = "Newline Test"
            })

            assert.are.equal(1, #scriptExecuteCalls)
            assert.are.equal("line1\nrm -rf /", scriptExecuteCalls[1].args[2])
        end)

        it("safely handles special characters in inline scripts", function()
            local maliciousScript = "echo 'test' && rm -rf /"

            eventBus:emit("script:execute", {
                type = "shell",
                script_inline = maliciousScript,
                name = "Malicious Inline Script"
            })

            assert.are.equal(1, #scriptExecuteCalls)
            -- Verify the entire script is passed to bash -c as a single argument
            assert.are.equal("-c", scriptExecuteCalls[1].args[1])
            assert.are.equal(maliciousScript, scriptExecuteCalls[1].args[2])
        end)
    end)
end)
