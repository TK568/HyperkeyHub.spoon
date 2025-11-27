-- Hammerspoon API mock for testing
-- This mock provides minimal implementations of Hammerspoon APIs
-- required for unit testing without the actual Hammerspoon runtime

local M = {}

M.printf_calls = {}
M.alert_calls = {}
M.window = {
    animationDuration = 0.2
}

function M.reset()
    for i = #M.printf_calls, 1, -1 do
        M.printf_calls[i] = nil
    end
    for i = #M.alert_calls, 1, -1 do
        M.alert_calls[i] = nil
    end
    M.window.animationDuration = 0.2
end

function M.printf(format, ...)
    local message = string.format(format, ...)
    table.insert(M.printf_calls, message)
end

M.alert = {
    show = function(message, duration)
        table.insert(M.alert_calls, {
            message = message,
            duration = duration or 2
        })
    end
}

M.json = {
    encode = function(obj, pretty)
        if type(obj) == "table" then
            local isArray = #obj > 0
            local result = {}

            if isArray then
                for i, v in ipairs(obj) do
                    table.insert(result, M.json.encode(v))
                end
                return "[" .. table.concat(result, ",") .. "]"
            else
                for k, v in pairs(obj) do
                    local key = string.format('"%s"', k)
                    local value = M.json.encode(v)
                    table.insert(result, key .. ":" .. value)
                end
                return "{" .. table.concat(result, ",") .. "}"
            end
        elseif type(obj) == "string" then
            return string.format('"%s"', obj)
        elseif type(obj) == "number" or type(obj) == "boolean" then
            return tostring(obj)
        elseif obj == nil then
            return "null"
        else
            error("Unsupported type: " .. type(obj))
        end
    end,

    decode = function(jsonString)
        local dkjson = require("dkjson")
        return dkjson.decode(jsonString)
    end
}

M.fs = {
    attributes = function(filepath, aname)
        local file = io.open(filepath, "r")
        if file then
            file:close()

            local size = 0
            local f = io.open(filepath, "r")
            if f and type(f.seek) == "function" then
                local ok, result = pcall(function() return f:seek("end") end)
                if ok then
                    size = result
                end
                f:close()
            elseif f then
                f:close()
            end

            local handle = io.popen("stat -f '%m' " .. filepath .. " 2>/dev/null || stat -c '%Y' " .. filepath .. " 2>/dev/null")
            local modTime = 0
            if handle then
                local result = handle:read("*a")
                handle:close()
                modTime = tonumber(result) or os.time()
            end

            if aname == "mode" then
                return "file"
            elseif aname == "size" then
                return size
            elseif aname == "modification" then
                return modTime
            else
                return {
                    mode = "file",
                    size = size,
                    modification = modTime
                }
            end
        end
        return nil
    end,

    dir = function(path)
        local files = {}
        local index = 0

        local handle = io.popen("ls -1 " .. path .. " 2>/dev/null")
        if handle then
            for file in handle:lines() do
                table.insert(files, file)
            end
            handle:close()
        end

        return function()
            index = index + 1
            return files[index]
        end
    end,

    mkdir = function(dirPath)
        return true, nil
    end
}

M.spoons = {
    resourcePath = function(path)
        return "/tmp/mock_resources/" .. (path or "")
    end
}

M.screen = {
    find = function(uuid)
        return nil
    end
}

function M.setup()
    _G.hs = {
        printf = M.printf,
        alert = M.alert,
        json = M.json,
        fs = M.fs,
        spoons = M.spoons,
        screen = M.screen
    }
    _G.hs.window = M.window
end

return M
