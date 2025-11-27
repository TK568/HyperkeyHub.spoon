describe("FileUtils", function()
    local FileUtils
    local testDir
    local testFilePath
    local originalIoOpen

    before_each(function()
        -- Save and restore original io.open to prevent test interference
        originalIoOpen = _G.io.open

        package.loaded["utils.file_utils"] = nil
        FileUtils = require("utils.file_utils")

        testDir = "/tmp/hyperkeyhub_fileutils_test_" .. os.time() .. "/"
        testFilePath = testDir .. "test.txt"
        os.execute("mkdir -p " .. testDir)
    end)

    after_each(function()
        os.execute("rm -rf " .. testDir)
        -- Restore original io.open
        _G.io.open = originalIoOpen
    end)

    describe("readFile", function()
        it("reads existing file successfully", function()
            local content = "Hello, World!"
            local f = io.open(testFilePath, "w")
            f:write(content)
            f:close()

            local result, err = FileUtils.readFile(testFilePath)

            assert.is_nil(err)
            assert.equals(content, result)
        end)

        it("returns nil and error for non-existent file", function()
            local nonExistentPath = testDir .. "nonexistent.txt"

            local result, err = FileUtils.readFile(nonExistentPath)

            assert.is_nil(result)
            assert.is_not_nil(err)
        end)

        it("reads empty file successfully", function()
            local f = io.open(testFilePath, "w")
            f:close()

            local result, err = FileUtils.readFile(testFilePath)

            assert.is_nil(err)
            assert.equals("", result)
        end)

        it("reads file with multi-line content", function()
            local content = "Line 1\nLine 2\nLine 3"
            local f = io.open(testFilePath, "w")
            f:write(content)
            f:close()

            local result, err = FileUtils.readFile(testFilePath)

            assert.is_nil(err)
            assert.equals(content, result)
        end)

        it("reads file with special characters", function()
            local content = "Special chars: !@#$%^&*(){}[]<>?/\\"
            local f = io.open(testFilePath, "w")
            f:write(content)
            f:close()

            local result, err = FileUtils.readFile(testFilePath)

            assert.is_nil(err)
            assert.equals(content, result)
        end)

        it("reads file with UTF-8 content", function()
            local content = "日本語テキスト\nEnglish text\n中文文本"
            local f = io.open(testFilePath, "w")
            f:write(content)
            f:close()

            local result, err = FileUtils.readFile(testFilePath)

            assert.is_nil(err)
            assert.equals(content, result)
        end)

        it("reads large file successfully", function()
            local largeContent = string.rep("A", 10000)
            local f = io.open(testFilePath, "w")
            f:write(largeContent)
            f:close()

            local result, err = FileUtils.readFile(testFilePath)

            assert.is_nil(err)
            assert.equals(10000, #result)
            assert.equals(largeContent, result)
        end)
    end)

    describe("writeFile", function()
        it("writes to new file successfully", function()
            local content = "Test content"

            local success, err = FileUtils.writeFile(testFilePath, content)

            assert.is_true(success)
            assert.is_nil(err)

            local f = io.open(testFilePath, "r")
            local written = f:read("*a")
            f:close()

            assert.equals(content, written)
        end)

        it("overwrites existing file", function()
            local originalContent = "Original"
            local f = io.open(testFilePath, "w")
            f:write(originalContent)
            f:close()

            local newContent = "New content"
            local success, err = FileUtils.writeFile(testFilePath, newContent)

            assert.is_true(success)
            assert.is_nil(err)

            local f2 = io.open(testFilePath, "r")
            local written = f2:read("*a")
            f2:close()

            assert.equals(newContent, written)
        end)

        it("returns false for non-existent directory", function()
            local invalidPath = testDir .. "nonexistent_dir/test.txt"

            local success, err = FileUtils.writeFile(invalidPath, "content")

            assert.is_false(success)
            assert.is_not_nil(err)
        end)

        it("writes empty string successfully", function()
            local success, err = FileUtils.writeFile(testFilePath, "")

            assert.is_true(success)
            assert.is_nil(err)

            local f = io.open(testFilePath, "r")
            local written = f:read("*a")
            f:close()

            assert.equals("", written)
        end)

        it("writes multi-line content", function()
            local content = "Line 1\nLine 2\nLine 3"

            local success, err = FileUtils.writeFile(testFilePath, content)

            assert.is_true(success)
            assert.is_nil(err)

            local f = io.open(testFilePath, "r")
            local written = f:read("*a")
            f:close()

            assert.equals(content, written)
        end)

        it("writes special characters", function()
            local content = "Special chars: !@#$%^&*(){}[]<>?/\\"

            local success, err = FileUtils.writeFile(testFilePath, content)

            assert.is_true(success)
            assert.is_nil(err)

            local f = io.open(testFilePath, "r")
            local written = f:read("*a")
            f:close()

            assert.equals(content, written)
        end)

        it("writes UTF-8 content", function()
            local content = "日本語テキスト\nEnglish text\n中文文本"

            local success, err = FileUtils.writeFile(testFilePath, content)

            assert.is_true(success)
            assert.is_nil(err)

            local f = io.open(testFilePath, "r")
            local written = f:read("*a")
            f:close()

            assert.equals(content, written)
        end)

        it("writes large content successfully", function()
            local largeContent = string.rep("B", 10000)

            local success, err = FileUtils.writeFile(testFilePath, largeContent)

            assert.is_true(success)
            assert.is_nil(err)

            local f = io.open(testFilePath, "r")
            local written = f:read("*a")
            f:close()

            assert.equals(10000, #written)
            assert.equals(largeContent, written)
        end)
    end)

    describe("Integration Tests", function()
        it("writes and reads back the same content", function()
            local originalContent = "Integration test content"

            local writeSuccess, writeErr = FileUtils.writeFile(testFilePath, originalContent)
            assert.is_true(writeSuccess)
            assert.is_nil(writeErr)

            local readContent, readErr = FileUtils.readFile(testFilePath)
            assert.is_nil(readErr)
            assert.equals(originalContent, readContent)
        end)

        it("handles multiple write-read cycles", function()
            local contents = {"First", "Second", "Third"}

            for _, content in ipairs(contents) do
                local writeSuccess = FileUtils.writeFile(testFilePath, content)
                assert.is_true(writeSuccess)

                local readContent = FileUtils.readFile(testFilePath)
                assert.equals(content, readContent)
            end
        end)

        it("maintains content integrity with special characters", function()
            local specialContent = "Line 1\n\tTabbed\n\"Quoted\"\n'Single'\n\\Escaped\\"

            FileUtils.writeFile(testFilePath, specialContent)
            local readBack = FileUtils.readFile(testFilePath)

            assert.equals(specialContent, readBack)
        end)

        it("handles JSON-like content correctly", function()
            local jsonContent = '{"key": "value", "number": 123, "nested": {"inner": true}}'

            FileUtils.writeFile(testFilePath, jsonContent)
            local readBack = FileUtils.readFile(testFilePath)

            assert.equals(jsonContent, readBack)
        end)
    end)
end)
