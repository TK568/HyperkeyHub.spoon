--- Script Runner Module
--- Executes shell scripts, AppleScripts, and Lua scripts via keyboard shortcuts
--- @module ScriptRunner

local moduleDir = debug.getinfo(1, "S").source:match("@(.*/)")
local function requireModule(name)
    local fullPath = moduleDir .. name .. ".lua"
    return dofile(fullPath)
end
local Logger = requireModule("logger")
local log = Logger.new("ScriptRunner")

local ScriptRunner = {}

--- Expand special prefixes in file paths or resolve relative paths
--- Supports:
---   ~ - Home directory
---   Relative paths (not starting with / or ~) - Resolved relative to Spoon resources
--- @param path string Path that may contain special prefixes or be relative
--- @return string Expanded absolute path
local function expandPath(path)
    if not path then return nil end

    if path:sub(1, 1) == "~" then
        local home = os.getenv("HOME")
        return home .. path:sub(2)
    end

    if path:sub(1, 1) ~= "/" then
        local spoonDir = moduleDir:match("(.*/)modules/$")
        if not spoonDir then
            log:error("Failed to extract Spoon directory from: %s", moduleDir)
            return path
        end
        return spoonDir .. path
    end

    return path
end

--- Execute a shell script
--- @param scriptPath string|nil Path to shell script file
--- @param scriptInline string|nil Inline shell script code
--- @param args table|nil Arguments to pass to the script
--- @param name string Script name for logging
--- @return boolean success Whether execution was successful
local function executeShellScript(scriptPath, scriptInline, args, name)
    args = args or {}
    local taskArgs = {}

    if scriptPath then
        local expandedPath = expandPath(scriptPath)
        local file = io.open(expandedPath, "r")
        if not file then
            log:error("Shell script file not found: %s", expandedPath)
            log:alert(string.format("❌ Script file not found: %s", scriptPath))
            return false
        end
        file:close()

        table.insert(taskArgs, expandedPath)
        for _, arg in ipairs(args) do
            table.insert(taskArgs, arg)
        end
    elseif scriptInline then
        table.insert(taskArgs, "-c")
        table.insert(taskArgs, scriptInline)
        for _, arg in ipairs(args) do
            table.insert(taskArgs, arg)
        end
    else
        log:error("No script path or inline script provided for: %s", name)
        return false
    end

    log:debug("Executing shell script: %s", name)
    local task = hs.task.new("/bin/bash", nil, taskArgs)
    local exitCode = task:waitUntilExit()

    if exitCode == 0 then
        log:debug("Shell script succeeded: %s", name)
        return true
    else
        log:error("Shell script failed: %s (exit code: %s)", name, tostring(exitCode))
        log:alert(string.format("❌ Script failed: %s", name))
        return false
    end
end

--- Execute an AppleScript
--- @param scriptPath string|nil Path to AppleScript file
--- @param scriptInline string|nil Inline AppleScript code
--- @param args table|nil Arguments to pass to the script
--- @param name string Script name for logging
--- @return boolean success Whether execution was successful
local function executeAppleScript(scriptPath, scriptInline, args, name)
    args = args or {}
    local taskArgs = {}

    if scriptPath then
        local expandedPath = expandPath(scriptPath)
        local file = io.open(expandedPath, "r")
        if not file then
            log:error("AppleScript file not found: %s", expandedPath)
            log:alert(string.format("❌ Script file not found: %s", scriptPath))
            return false
        end
        file:close()

        table.insert(taskArgs, expandedPath)
        for _, arg in ipairs(args) do
            table.insert(taskArgs, arg)
        end
    elseif scriptInline then
        table.insert(taskArgs, "-e")
        table.insert(taskArgs, scriptInline)
        for _, arg in ipairs(args) do
            table.insert(taskArgs, arg)
        end
    else
        log:error("No script path or inline script provided for: %s", name)
        return false
    end

    log:debug("Executing AppleScript: %s", name)
    local task = hs.task.new("/usr/bin/osascript", nil, taskArgs)
    local exitCode = task:waitUntilExit()

    if exitCode == 0 then
        log:debug("AppleScript succeeded: %s", name)
        return true
    else
        log:error("AppleScript failed: %s (exit code: %s)", name, tostring(exitCode))
        log:alert(string.format("❌ Script failed: %s", name))
        return false
    end
end

--- Check if a table is an array (sequential integer keys starting from 1)
--- @param t table Table to check
--- @return boolean isArray True if table is an array
local function isArray(t)
    if type(t) ~= "table" then return false end
    if next(t) == nil then return true end
    local hasStringKey = false
    local hasNumericKey = false
    for k, _ in pairs(t) do
        if type(k) == "string" then
            hasStringKey = true
        elseif type(k) == "number" then
            hasNumericKey = true
        end
    end
    return hasNumericKey and not hasStringKey
end

--- Execute a Lua script
--- @param scriptPath string|nil Path to Lua script file
--- @param scriptInline string|nil Inline Lua script code
--- @param args table|nil Arguments to pass to the script (array or named table)
--- @param name string Script name for logging
--- @return boolean success Whether execution was successful
local function executeLuaScript(scriptPath, scriptInline, args, name)
    args = args or {}

    local function callChunk(chunk)
        if isArray(args) then
            return pcall(chunk, table.unpack(args))
        else
            return pcall(chunk, args)
        end
    end

    if scriptPath then
        local expandedPath = expandPath(scriptPath)
        local file = io.open(expandedPath, "r")
        if not file then
            log:error("Lua script file not found: %s", expandedPath)
            log:alert(string.format("❌ Script file not found: %s", scriptPath))
            return false
        end
        file:close()

        log:debug("Executing Lua script: %s", name)
        log:debug("Script path: %s", expandedPath)
        log:debug("Arguments: %s", hs.inspect(args))

        local chunk, loadErr = loadfile(expandedPath)
        if not chunk then
            log:error("Failed to load Lua script: %s\nError: %s", name, loadErr)
            log:alert(string.format("❌ Script load error: %s", name))
            return false
        end

        local success, execErr = callChunk(chunk)
        if not success then
            log:error("Lua script execution failed: %s\nError: %s", name, tostring(execErr))
            log:alert(string.format("❌ Script failed: %s", name))
            return false
        end

        log:debug("Lua script succeeded: %s", name)
        return true
    elseif scriptInline then
        log:debug("Executing inline Lua script: %s", name)
        log:debug("Arguments: %s", hs.inspect(args))

        local chunk, loadErr = load(scriptInline)
        if not chunk then
            log:error("Failed to load inline Lua script: %s\nError: %s", name, loadErr)
            log:alert(string.format("❌ Script load error: %s", name))
            return false
        end

        local success, execErr = callChunk(chunk)
        if not success then
            log:error("Inline Lua script execution failed: %s\nError: %s", name, tostring(execErr))
            log:alert(string.format("❌ Script failed: %s", name))
            return false
        end

        log:debug("Inline Lua script succeeded: %s", name)
        return true
    else
        log:error("No script path or inline script provided for: %s", name)
        return false
    end
end

--- Initialize ScriptRunner with event bus
--- @param self table ScriptRunner instance
--- @param eventBus table EventBus instance for registering listeners
--- @return table self ScriptRunner instance
function ScriptRunner:init(eventBus)
    self.eventBus = eventBus
    log:info("ScriptRunner initialized")

    eventBus:on("script:execute", function(data)
        log:debug("script:execute event received")
        local scriptType = data.type or "shell"
        local scriptPath = data.script_path
        local scriptInline = data.script_inline
        local args = data.args
        local name = data.name or "Unknown Script"

        log:debug("Script type: %s, name: %s", scriptType, name)

        if scriptType == "shell" then
            log:debug("Executing shell script...")
            executeShellScript(scriptPath, scriptInline, args, name)
        elseif scriptType == "applescript" then
            log:debug("Executing AppleScript...")
            executeAppleScript(scriptPath, scriptInline, args, name)
        elseif scriptType == "lua" then
            log:debug("Executing Lua script...")
            executeLuaScript(scriptPath, scriptInline, args, name)
        else
            log:error("Unknown script type: %s", scriptType)
            log:alert(string.format("❌ Unknown script type: %s", scriptType))
        end
        log:debug("script:execute event handler completed")
    end)

    return self
end

function ScriptRunner:cleanup()
    self.eventBus = nil
    log:debug("ScriptRunner cleaned up")
end

return ScriptRunner
