describe("StringUtils", function()
    local StringUtils

    before_each(function()
        reset_mocks()
        package.loaded["utils.string_utils"] = nil
        StringUtils = require("utils.string_utils")
    end)

    describe("escapeShellArg", function()
        it("returns simple strings unchanged", function()
            assert.equals("hello", StringUtils.escapeShellArg("hello"))
            assert.equals("test123", StringUtils.escapeShellArg("test123"))
        end)

        it("escapes single quotes correctly", function()
            assert.equals("it'\\''s", StringUtils.escapeShellArg("it's"))
            assert.equals("O'\\''Reilly", StringUtils.escapeShellArg("O'Reilly"))
        end)

        it("escapes multiple single quotes", function()
            assert.equals("'\\''test'\\'''\\'''\\''value'\\''", StringUtils.escapeShellArg("'test'''value'"))
        end)

        it("handles empty string", function()
            assert.equals("", StringUtils.escapeShellArg(""))
        end)

        it("converts numbers to strings", function()
            assert.equals("42", StringUtils.escapeShellArg(42))
            assert.equals("3.14", StringUtils.escapeShellArg(3.14))
        end)

        it("converts nil to string", function()
            assert.equals("nil", StringUtils.escapeShellArg(nil))
        end)

        it("handles strings with spaces", function()
            assert.equals("hello world", StringUtils.escapeShellArg("hello world"))
        end)

        it("handles special shell characters without quotes", function()
            assert.equals("test;command", StringUtils.escapeShellArg("test;command"))
            assert.equals("test|pipe", StringUtils.escapeShellArg("test|pipe"))
            assert.equals("test&background", StringUtils.escapeShellArg("test&background"))
            assert.equals("test$var", StringUtils.escapeShellArg("test$var"))
            assert.equals("test`backtick`", StringUtils.escapeShellArg("test`backtick`"))
        end)

        it("prevents shell injection with semicolon", function()
            local malicious = "'; rm -rf /"
            local escaped = StringUtils.escapeShellArg(malicious)
            assert.equals("'\\''; rm -rf /", escaped)
        end)

        it("prevents shell injection with command substitution", function()
            local malicious = "$(rm -rf /)"
            local escaped = StringUtils.escapeShellArg(malicious)
            assert.equals("$(rm -rf /)", escaped)
        end)

        it("prevents shell injection with backticks", function()
            local malicious = "`whoami`"
            local escaped = StringUtils.escapeShellArg(malicious)
            assert.equals("`whoami`", escaped)
        end)

        it("prevents shell injection with pipe", function()
            local malicious = "file | cat /etc/passwd"
            local escaped = StringUtils.escapeShellArg(malicious)
            assert.equals("file | cat /etc/passwd", escaped)
        end)
    end)

    describe("escapeJavaScript", function()
        it("returns simple strings unchanged", function()
            assert.equals("hello", StringUtils.escapeJavaScript("hello"))
            assert.equals("test123", StringUtils.escapeJavaScript("test123"))
        end)

        it("escapes backslashes", function()
            assert.equals("path\\\\to\\\\file", StringUtils.escapeJavaScript("path\\to\\file"))
        end)

        it("escapes single quotes", function()
            assert.equals("it\\'s", StringUtils.escapeJavaScript("it's"))
        end)

        it("escapes double quotes", function()
            assert.equals("say \\\"hello\\\"", StringUtils.escapeJavaScript('say "hello"'))
        end)

        it("escapes newline characters", function()
            assert.equals("line1\\nline2", StringUtils.escapeJavaScript("line1\nline2"))
        end)

        it("escapes carriage return characters", function()
            assert.equals("text\\rreturn", StringUtils.escapeJavaScript("text\rreturn"))
        end)

        it("escapes tab characters", function()
            assert.equals("col1\\tcol2", StringUtils.escapeJavaScript("col1\tcol2"))
        end)

        it("escapes multiple special characters", function()
            local input = "line1\nline2\ttab'quote\"double\\backslash"
            local expected = "line1\\nline2\\ttab\\'quote\\\"double\\\\backslash"
            assert.equals(expected, StringUtils.escapeJavaScript(input))
        end)

        it("handles empty string", function()
            assert.equals("", StringUtils.escapeJavaScript(""))
        end)

        it("returns empty string for nil", function()
            assert.equals("", StringUtils.escapeJavaScript(nil))
        end)

        it("prevents XSS with script tags", function()
            local malicious = "<script>alert('XSS')</script>"
            local escaped = StringUtils.escapeJavaScript(malicious)
            assert.equals("<script>alert(\\'XSS\\')</script>", escaped)
        end)

        it("prevents XSS with event handlers", function()
            local malicious = 'onclick="alert(\'XSS\')"'
            local escaped = StringUtils.escapeJavaScript(malicious)
            assert.equals("onclick=\\\"alert(\\'XSS\\')\\\"", escaped)
        end)

        it("escapes newlines in JavaScript strings to prevent injection", function()
            local malicious = "'; alert('XSS');\n//"
            local escaped = StringUtils.escapeJavaScript(malicious)
            assert.equals("\\'; alert(\\'XSS\\');\\n//", escaped)
        end)

        it("escapes backslashes before quotes correctly", function()
            local input = "test\\'quote"
            local escaped = StringUtils.escapeJavaScript(input)
            assert.equals("test\\\\\\'quote", escaped)
        end)

        it("handles unicode and special characters", function()
            local input = "テスト\n日本語"
            local escaped = StringUtils.escapeJavaScript(input)
            assert.equals("テスト\\n日本語", escaped)
        end)
    end)
end)
