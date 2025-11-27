--- Table utility functions
--- Provides deep copy and deep merge operations for tables
---@class TableUtils
local TableUtils = {}

--- Check if a table is an array (sequential numeric keys starting from 1)
--- @param tbl table Table to check
--- @return boolean isArray True if table is an array
local function isArray(tbl)
    if type(tbl) ~= "table" then
        return false
    end

    local count = 0
    local maxIndex = 0
    for key in pairs(tbl) do
        if type(key) ~= "number" or key <= 0 or key % 1 ~= 0 then
            return false
        end
        count = count + 1
        if key > maxIndex then
            maxIndex = key
        end
    end

    return count > 0 and maxIndex == count
end

--- Internal deep copy implementation with circular reference tracking
--- @param value any Value to copy
--- @param visited table|nil Table tracking visited objects to handle circular references
--- @return any copiedValue Deep copy of the value
local function deepCopyInternal(value, visited)
    if type(value) ~= "table" then
        return value
    end

    visited = visited or {}
    if visited[value] then
        return visited[value]
    end

    local copy = {}
    visited[value] = copy

    for k, v in pairs(value) do
        local copiedKey = deepCopyInternal(k, visited)
        copy[copiedKey] = deepCopyInternal(v, visited)
    end

    local mt = getmetatable(value)
    if mt then
        setmetatable(copy, deepCopyInternal(mt, visited))
    end

    return copy
end

--- Create a deep copy of a table
--- Handles nested tables, metatables, and circular references
--- @param tbl table Table to copy
--- @return table copiedTable Deep copy of the input table
function TableUtils.deepCopy(tbl)
    return deepCopyInternal(tbl, {})
end

--- Deep merge two tables, with user values overriding defaults
--- Arrays are replaced entirely, not merged element-wise
--- @param default table Default configuration table
--- @param user table User configuration table (overrides defaults)
--- @return table mergedTable Merged configuration table
function TableUtils.deepMerge(default, user)
    if type(user) ~= "table" then
        return user
    end

    local base
    if type(default) == "table" then
        base = TableUtils.deepCopy(default)
    else
        base = {}
    end

    for key, value in pairs(user) do
        if type(value) == "table" and type(base[key]) == "table" then
            if isArray(value) or isArray(base[key]) then
                base[key] = TableUtils.deepCopy(value)
            else
                base[key] = TableUtils.deepMerge(base[key], value)
            end
        elseif type(value) == "table" then
            base[key] = TableUtils.deepCopy(value)
        else
            base[key] = value
        end
    end

    return base
end

return TableUtils
