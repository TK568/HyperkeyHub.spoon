describe("ModuleLoader", function()
    local ModuleLoader
    local testDir
    local testModulePath

    before_each(function()
        package.loaded["utils.module_loader"] = nil
        ModuleLoader = require("utils.module_loader")

        -- Create temporary test directory
        testDir = "/tmp/hyperkeyhub_moduleloader_test_" .. os.time() .. "/"
        os.execute("mkdir -p " .. testDir)

        -- Create a simple test module
        testModulePath = testDir .. "test_module.lua"
        local f = io.open(testModulePath, "w")
        f:write("return { name = 'TestModule', value = 42 }")
        f:close()
    end)

    after_each(function()
        -- Clean up temporary directory
        os.execute("rm -rf " .. testDir)
    end)

    describe("requireRelative", function()
        it("loads module successfully with valid path", function()
            local result = ModuleLoader.requireRelative(testDir, "test_module")

            assert.is_not_nil(result)
            assert.is_table(result)
            assert.equals("TestModule", result.name)
            assert.equals(42, result.value)
        end)

        it("returns correct module object", function()
            local result = ModuleLoader.requireRelative(testDir, "test_module")

            assert.is_table(result)
            assert.equals("TestModule", result.name)
        end)

        it("handles basePath with trailing slash", function()
            local result = ModuleLoader.requireRelative(testDir, "test_module")

            assert.is_not_nil(result)
            assert.equals("TestModule", result.name)
        end)

        it("handles basePath without trailing slash", function()
            local basePathNoSlash = testDir:sub(1, -2)

            -- Create module at path without trailing slash
            local result = ModuleLoader.requireRelative(basePathNoSlash .. "/", "test_module")

            assert.is_not_nil(result)
            assert.equals("TestModule", result.name)
        end)

        it("raises error for non-existent file", function()
            assert.has_error(function()
                ModuleLoader.requireRelative(testDir, "nonexistent_module")
            end)
        end)

        it("raises error for file with syntax error", function()
            local syntaxErrorPath = testDir .. "syntax_error.lua"
            local f = io.open(syntaxErrorPath, "w")
            f:write("return { invalid syntax here")
            f:close()

            assert.has_error(function()
                ModuleLoader.requireRelative(testDir, "syntax_error")
            end)
        end)

        it("can load multiple modules from same basePath", function()
            -- Create second test module
            local secondModulePath = testDir .. "second_module.lua"
            local f = io.open(secondModulePath, "w")
            f:write("return { name = 'SecondModule' }")
            f:close()

            local first = ModuleLoader.requireRelative(testDir, "test_module")
            local second = ModuleLoader.requireRelative(testDir, "second_module")

            assert.equals("TestModule", first.name)
            assert.equals("SecondModule", second.name)
        end)
    end)

    describe("setupRequireHelper", function()
        it("returns a function", function()
            local requireHelper = ModuleLoader.setupRequireHelper()

            assert.is_function(requireHelper)
        end)

        it("returned function loads modules correctly", function()
            -- Create a subdirectory structure
            local subDir = testDir .. "submodules/"
            os.execute("mkdir -p " .. subDir)

            local subModulePath = subDir .. "helper_module.lua"
            local f = io.open(subModulePath, "w")
            f:write("return { loaded = true, helper = 'module' }")
            f:close()

            -- Mock debug.getinfo to return our test directory
            local originalGetInfo = debug.getinfo
            debug.getinfo = function(level, what)
                if level == 2 and what == "S" then
                    return { source = "@" .. subDir .. "caller.lua" }
                end
                return originalGetInfo(level, what)
            end

            local requireHelper = ModuleLoader.setupRequireHelper()
            local result = requireHelper("helper_module")

            assert.is_not_nil(result)
            assert.is_true(result.loaded)
            assert.equals("module", result.helper)

            -- Restore original debug.getinfo
            debug.getinfo = originalGetInfo
        end)

        it("handles errors when loading non-existent module", function()
            -- Mock debug.getinfo to return our test directory
            local originalGetInfo = debug.getinfo
            debug.getinfo = function(level, what)
                if level == 2 and what == "S" then
                    return { source = "@" .. testDir .. "caller.lua" }
                end
                return originalGetInfo(level, what)
            end

            local requireHelper = ModuleLoader.setupRequireHelper()

            assert.has_error(function()
                requireHelper("nonexistent")
            end)

            -- Restore original debug.getinfo
            debug.getinfo = originalGetInfo
        end)
    end)

    describe("Integration", function()
        it("can be used to create a custom require function", function()
            -- Create a module structure
            local moduleDir = testDir .. "mymodules/"
            os.execute("mkdir -p " .. moduleDir)

            local utilPath = moduleDir .. "util.lua"
            local f = io.open(utilPath, "w")
            f:write("return { getName = function() return 'Utility' end }")
            f:close()

            -- Create a custom require function
            local myRequire = function(name)
                return ModuleLoader.requireRelative(moduleDir, name)
            end

            local util = myRequire("util")

            assert.is_not_nil(util)
            assert.is_function(util.getName)
            assert.equals("Utility", util.getName())
        end)
    end)
end)
