describe("TableUtils", function()
    local TableUtils

    before_each(function()
        reset_mocks()
        package.loaded["utils.table_utils"] = nil
        TableUtils = require("utils.table_utils")
    end)

    describe("deepCopy", function()
        it("returns non-table values as-is", function()
            assert.equals(42, TableUtils.deepCopy(42))
            assert.equals("text", TableUtils.deepCopy("text"))
            assert.is_nil(TableUtils.deepCopy(nil))
        end)

        it("creates a new table instance for shallow copies", function()
            local original = { a = 1, b = 2 }
            local copy = TableUtils.deepCopy(original)

            assert.are_not.equal(original, copy)
            copy.a = 99
            assert.equals(1, original.a)
        end)

        it("recursively copies nested tables", function()
            local original = { level1 = { level2 = { value = "test" } } }
            local copy = TableUtils.deepCopy(original)

            assert.are_not.equal(original.level1, copy.level1)
            assert.are_not.equal(original.level1.level2, copy.level1.level2)
            copy.level1.level2.value = "changed"
            assert.equals("test", original.level1.level2.value)
        end)

        it("handles array-style tables", function()
            local original = { 1, 2, 3, nested = { 10, 20 } }
            local copy = TableUtils.deepCopy(original)

            assert.are.same(original, copy)
            copy[1] = 9
            copy.nested[1] = 99
            assert.equals(1, original[1])
            assert.equals(10, original.nested[1])
        end)

        it("preserves cyclic references", function()
            local original = {}
            original.self = original

            local copy = TableUtils.deepCopy(original)
            assert.are_not.equal(original, copy)
            assert.are.equal(copy, copy.self)
        end)

        it("copies metatables", function()
            local mt = { __tag = "meta" }
            local original = setmetatable({ value = 1 }, mt)

            local copy = TableUtils.deepCopy(original)
            local copyMetatable = getmetatable(copy)

            assert.are_not.equal(getmetatable(original), copyMetatable)
            assert.equals("meta", copyMetatable.__tag)
        end)
    end)

    describe("deepMerge", function()
        it("returns non-table user values directly", function()
            assert.equals(5, TableUtils.deepMerge({ a = 1 }, 5))
            assert.is_nil(TableUtils.deepMerge({ a = 1 }, nil))
        end)

        it("merges nested tables recursively", function()
            local defaults = {
                app = { key = "A", modifiers = { "cmd" }, metadata = { enabled = true } }
            }
            local overrides = {
                app = { modifiers = { "cmd", "shift" }, metadata = { enabled = false } }
            }

            local merged = TableUtils.deepMerge(defaults, overrides)

            assert.are.same({ "cmd", "shift" }, merged.app.modifiers)
            assert.is_false(merged.app.metadata.enabled)
            assert.equals("A", merged.app.key)
        end)

        it("adds keys that exist only in overrides", function()
            local defaults = { window = { key = "H" } }
            local overrides = { window = { name = "Hide" }, system = { enabled = true } }

            local merged = TableUtils.deepMerge(defaults, overrides)

            assert.equals("H", merged.window.key)
            assert.equals("Hide", merged.window.name)
            assert.is_true(merged.system.enabled)
        end)

        it("does not mutate the original tables", function()
            local defaults = { window = { key = "A" } }
            local overrides = { window = { key = "B" } }

            local merged = TableUtils.deepMerge(defaults, overrides)
            merged.window.key = "C"

            assert.equals("A", defaults.window.key)
            assert.equals("B", overrides.window.key)
        end)

        it("replaces list values with copies", function()
            local defaults = { apps = { "A", "B" } }
            local overrides = { apps = { "C" } }

            local merged = TableUtils.deepMerge(defaults, overrides)

            assert.are.same({ "C" }, merged.apps)
            merged.apps[1] = "X"
            assert.are.same({ "A", "B" }, defaults.apps)
            assert.are.same({ "C" }, overrides.apps)
        end)

        it("handles nil defaults by cloning overrides", function()
            local overrides = { bindings = { a = 1 } }
            local merged = TableUtils.deepMerge(nil, overrides)

            assert.are.same({ a = 1 }, merged.bindings)
            assert.are_not.equal(overrides.bindings, merged.bindings)
        end)
    end)
end)
