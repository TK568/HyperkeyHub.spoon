-- AppLauncher module (independent, event-driven)

local moduleDir = debug.getinfo(1, "S").source:match("@(.*/)")
local function requireModule(name)
    local fullPath = moduleDir .. name .. ".lua"
    return dofile(fullPath)
end
local Logger = requireModule("logger")
local log = Logger.new("AppLauncher")

local AppLauncher = {
    options = {
        maxRetries = 2,
        retryDelay = 0.5
    }
}

--- Launch an application with retry attempts
--- @param self table AppLauncher instance
--- @param appName string Application name for launch/focus
--- @param retryCount number Current retry count
function AppLauncher:launchAppWithRetry(appName, retryCount)
    retryCount = retryCount or 0
    local totalAttempts = self.options.maxRetries + 1
    local success = hs.application.launchOrFocus(appName)

    if success then
        log:debug("Successfully launched: %s", appName)
        return true
    end

    if retryCount < self.options.maxRetries then
        log:warn(
            "Failed to launch %s (attempt %d/%d), retrying...",
            appName,
            retryCount + 1,
            totalAttempts
        )

        local timerDoAfter = hs.timer and hs.timer.doAfter
        if timerDoAfter then
            timerDoAfter(self.options.retryDelay, function()
                self:launchAppWithRetry(appName, retryCount + 1)
            end)
        else
            self:launchAppWithRetry(appName, retryCount + 1)
        end
    else
        log:error("Failed to launch %s after %d attempts", appName, totalAttempts)
        log:alert(string.format("❌ Failed to launch %s", appName), 3)
    end

    return false
end

--- Toggle application (launch/focus or hide)
--- @param self table AppLauncher instance
--- @param bundleID string Application bundle identifier
--- @param appName string Application name for launch/focus
function AppLauncher:toggleApp(bundleID, appName)
    log:debug("Toggle app: %s (%s)", appName, bundleID)
    local app = hs.application.get(bundleID)

    if app then
        local isFrontmost = app:isFrontmost()

        if isFrontmost then
            log:debug("App is frontmost, hiding: %s", appName)
            local success = app:hide()

            if not success then
                -- If hide() fails (e.g., Electron apps)
                -- Select "Hide [App Name]" from menu item
                log:debug("hide() failed, using menu item for: %s", appName)
                local appName = app:name()
                if appName then
                    app:selectMenuItem({appName, "Hide " .. appName})
                end
            end
        else
            log:debug("App is not frontmost, focusing: %s", appName)
            hs.application.launchOrFocus(appName)
        end
    else
        log:debug("App not running, launching: %s", appName)
        self:launchAppWithRetry(appName, 0)
    end
end

--- Initialize AppLauncher with event bus
--- @param self table AppLauncher instance
--- @param eventBus table EventBus instance for registering listeners
--- @return table self AppLauncher instance
function AppLauncher:init(eventBus)
    self.eventBus = eventBus
    log:info("AppLauncher initialized")

    eventBus:on("app:toggle", function(data)
        self:toggleApp(data.bundleID, data.appName)
    end)

    return self
end

function AppLauncher:cleanup()
    self.eventBus = nil
    log:debug("AppLauncher cleaned up")
end

return AppLauncher
