-- Logger module for unified logging

---@class Logger
---@field DEBUG number Log level: DEBUG (1)
---@field INFO number Log level: INFO (2)
---@field WARN number Log level: WARN (3)
---@field ERROR number Log level: ERROR (4)
---@field level number Current log level (default: INFO)
---@field showAlerts boolean Enable/disable visual alerts
---@field global LoggerInstance Global logger instance
local Logger = {}

-- Log levels
Logger.DEBUG = 1
Logger.INFO = 2
Logger.WARN = 3
Logger.ERROR = 4

-- Default log level (INFO in production, DEBUG in development)
Logger.level = Logger.INFO

-- Track created logger instances
Logger.instances = {}

-- Alert display mode: "all" | "errors" | "none"
Logger.showAlerts = "all"

-- Internal log level names
local LEVEL_NAMES = {
    [Logger.DEBUG] = "DEBUG",
    [Logger.INFO] = "INFO",
    [Logger.WARN] = "WARN",
    [Logger.ERROR] = "ERROR"
}

---@class LoggerInstance
---@field debug fun(self: LoggerInstance, message: string, ...): nil Log debug message
---@field info fun(self: LoggerInstance, message: string, ...): nil Log info message
---@field warn fun(self: LoggerInstance, message: string, ...): nil Log warning message
---@field error fun(self: LoggerInstance, message: string, ...): nil Log error message
---@field alert fun(self: LoggerInstance, message: string, duration?: number): nil Show user alert

-- Internal log function
---@param level number Log level
---@param moduleName string|nil Module name
---@param message string Log message format
---@param ... any Format arguments
local function log(level, moduleName, message, ...)
    if level < Logger.level then
        return
    end

    local formattedMessage = string.format(message, ...)
    local levelName = LEVEL_NAMES[level] or "UNKNOWN"
    local prefix = moduleName and string.format("[%s:%s]", moduleName, levelName) or string.format("[%s]", levelName)

    hs.printf("%s %s", prefix, formattedMessage)
end

---@param moduleName string|nil Module name for logging context
---@return LoggerInstance instance Logger instance for the module
function Logger.new(moduleName)
    local instance = {}

    function instance:debug(message, ...)
        log(Logger.DEBUG, moduleName, message, ...)
    end

    function instance:info(message, ...)
        log(Logger.INFO, moduleName, message, ...)
    end

    function instance:warn(message, ...)
        log(Logger.WARN, moduleName, message, ...)
    end

    function instance:error(message, ...)
        log(Logger.ERROR, moduleName, message, ...)
    end

    -- Show user-facing alert for success/info messages
    function instance:alert(message, duration)
        if Logger.showAlerts == "all" or Logger.showAlerts == true then
            hs.alert.show(message, duration or 2)
        end
        log(Logger.INFO, moduleName, "ALERT: %s", message)
    end

    -- Show user-facing alert for error messages (always shown unless "none")
    function instance:alertError(message, duration)
        if Logger.showAlerts ~= "none" and Logger.showAlerts ~= false then
            hs.alert.show(message, duration or 2)
        end
        log(Logger.ERROR, moduleName, "ALERT: %s", message)
    end

    table.insert(Logger.instances, {
        name = moduleName,
        instance = instance
    })

    return instance
end

-- Global logger (no module name)
Logger.global = Logger.new(nil)

-- Convenience: Set log level by name
---@param levelName string Log level name ("debug", "info", "warn", "error")
function Logger.setLevel(levelName)
    Logger.setGlobalLevel(levelName)
end

-- Set global log level across all logger instances
---@param levelName string Log level name ("debug", "info", "warn", "error")
function Logger.setGlobalLevel(levelName)
    local levels = {
        debug = Logger.DEBUG,
        info = Logger.INFO,
        warn = Logger.WARN,
        error = Logger.ERROR
    }

    local level = levels[string.lower(levelName)]
    if level then
        Logger.level = level
        Logger.global:info("Global log level set to %s (%d instances)", levelName, #Logger.instances)
    else
        Logger.global:warn("Unknown log level: %s", levelName)
    end
end

return Logger
