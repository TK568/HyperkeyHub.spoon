local FileUtils = {}

---@param filepath string Path to the file to read
---@return string|nil content File content, or nil on failure
---@return string|nil error Error message if reading failed
function FileUtils.readFile(filepath)
    local file, err = io.open(filepath, "r")
    if not file then
        return nil, err
    end

    local content
    local success, readErr = pcall(function()
        content = file:read("*a")
    end)

    file:close()

    if not success then
        return nil, readErr
    end
    return content
end

---@param filepath string Path to the file to write
---@param content string Content to write
---@return boolean success True if write succeeded
---@return string|nil error Error message if writing failed
function FileUtils.writeFile(filepath, content)
    local file, err = io.open(filepath, "w")
    if not file then
        return false, err
    end

    local success, writeErr = pcall(function()
        file:write(content)
        file:flush()
    end)

    file:close()

    return success, writeErr
end

return FileUtils
