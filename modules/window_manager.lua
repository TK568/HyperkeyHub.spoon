-- WindowManager module (independent, event-driven)

local moduleDir = debug.getinfo(1, "S").source:match("@(.*/)")
local function requireModule(name)
    local fullPath = moduleDir .. name .. ".lua"
    return dofile(fullPath)
end
local Logger = requireModule("logger")
local log = Logger.new("WindowManager")

local homeDir = os.getenv("HOME") or ""

local WindowManager = {
    options = {
        showAlerts = "all",  -- "all" | "errors" | "none"
        customMessages = {}
    },
    actions = {},
    savedPositions = {},
    positionsFilePath = homeDir .. "/.hammerspoon/window_positions.json"
}

--- Helper function for setting window frame with ratio-based positioning
--- @param win table Hammerspoon window object
--- @param xRatio number X position ratio (0.0-1.0)
--- @param yRatio number Y position ratio (0.0-1.0)
--- @param wRatio number Width ratio (0.0-1.0)
--- @param hRatio number Height ratio (0.0-1.0)
local function setWindowFrame(win, xRatio, yRatio, wRatio, hRatio)
    local frame = win:frame()
    local screen = win:screen()
    local screenFrame = screen:frame()

    frame.x = screenFrame.x + (screenFrame.w * xRatio)
    frame.y = screenFrame.y + (screenFrame.h * yRatio)
    frame.w = screenFrame.w * wRatio
    frame.h = screenFrame.h * hRatio

    win:setFrame(frame)
end

local function showActionAlert(actionKey, defaultMessage, isError)
    local showAlerts = WindowManager.options.showAlerts
    local shouldShow = (showAlerts == "all" or showAlerts == true) or
                       (isError and showAlerts == "errors")

    if not shouldShow then
        return
    end

    local customMessage = WindowManager.options.customMessages[actionKey]
    local message = customMessage or defaultMessage

    if hs and hs.alert and hs.alert.show then
        hs.alert.show(message, 2)
    end
    log:info("ALERT: %s", message)
end

local function showErrorAlert(message)
    local showAlerts = WindowManager.options.showAlerts
    if showAlerts == "none" or showAlerts == false then
        return
    end

    if hs and hs.alert and hs.alert.show then
        hs.alert.show(message, 2)
    end
    log:error("ALERT: %s", message)
end

WindowManager.actions = {
    saveWindowPosition = function(win)
        win = win or hs.window.focusedWindow()
        if not win then
            log:warn("No window to save position for")
            return
        end

        local app = win:application()
        if not app then
            log:warn("Unable to determine application for window")
            return
        end

        local bundleID = app:bundleID()
        if not bundleID then
            log:warn("Window application has no bundleID")
            return
        end

        local frame = win:frame()
        local screen = win:screen()
        WindowManager.savedPositions[bundleID] = {
            x = frame.x,
            y = frame.y,
            w = frame.w,
            h = frame.h,
            screenUUID = screen and screen:getUUID() or nil
        }

        local success = WindowManager:savePositions()
        if success then
            showActionAlert("saveWindowPosition", "Window position saved")
        end
    end,

    restoreWindowPosition = function(win)
        win = win or hs.window.focusedWindow()
        if not win then
            log:warn("No window to restore position for")
            return
        end

        local app = win:application()
        local bundleID = app and app:bundleID()
        if not bundleID then
            log:warn("Unable to determine bundleID for current window")
            return
        end

        local position = WindowManager.savedPositions[bundleID]
        if not position then
            log:warn("No saved position for bundleID: %s", bundleID)
            return
        end

        if position.screenUUID then
            local targetScreen = hs.screen.find(position.screenUUID)
            if targetScreen then
                win:moveToScreen(targetScreen)
            end
        end

        local frame = win:frame()
        frame.x = position.x
        frame.y = position.y
        frame.w = position.w
        frame.h = position.h
        win:setFrame(frame)

        showActionAlert("restoreWindowPosition", "Window position restored")
    end,

    moveToLeftHalf = function(win)
        setWindowFrame(win, 0, 0, 0.5, 1)
        showActionAlert("moveToLeftHalf", "Window moved to left half")
    end,

    moveToRightHalf = function(win)
        setWindowFrame(win, 0.5, 0, 0.5, 1)
        showActionAlert("moveToRightHalf", "Window moved to right half")
    end,

    maximize = function(win)
        win:maximize()
        showActionAlert("maximize", "Window maximized")
    end,

    centerOnScreen = function(win)
        win:centerOnScreen()
        showActionAlert("centerOnScreen", "Window centered")
    end,

    moveToLeftThird = function(win)
        setWindowFrame(win, 0, 0, 1/3, 1)
        showActionAlert("moveToLeftThird", "Window moved to left third")
    end,

    moveToCenterThird = function(win)
        setWindowFrame(win, 1/3, 0, 1/3, 1)
        showActionAlert("moveToCenterThird", "Window moved to center third")
    end,

    moveToRightThird = function(win)
        setWindowFrame(win, 2/3, 0, 1/3, 1)
        showActionAlert("moveToRightThird", "Window moved to right third")
    end,

    moveToLeftTwoThirds = function(win)
        setWindowFrame(win, 0, 0, 2/3, 1)
        showActionAlert("moveToLeftTwoThirds", "Window moved to left 2/3")
    end,

    moveToRightTwoThirds = function(win)
        setWindowFrame(win, 1/3, 0, 2/3, 1)
        showActionAlert("moveToRightTwoThirds", "Window moved to right 2/3")
    end,

    moveToTopHalf = function(win)
        setWindowFrame(win, 0, 0, 1, 0.5)
        showActionAlert("moveToTopHalf", "Window moved to top half")
    end,

    moveToBottomHalf = function(win)
        setWindowFrame(win, 0, 0.5, 1, 0.5)
        showActionAlert("moveToBottomHalf", "Window moved to bottom half")
    end,

    moveToTopLeftQuarter = function(win)
        setWindowFrame(win, 0, 0, 0.5, 0.5)
        showActionAlert("moveToTopLeftQuarter", "Window moved to top-left 1/4")
    end,

    moveToTopRightQuarter = function(win)
        setWindowFrame(win, 0.5, 0, 0.5, 0.5)
        showActionAlert("moveToTopRightQuarter", "Window moved to top-right 1/4")
    end,

    moveToBottomLeftQuarter = function(win)
        setWindowFrame(win, 0, 0.5, 0.5, 0.5)
        showActionAlert("moveToBottomLeftQuarter", "Window moved to bottom-left 1/4")
    end,

    moveToBottomRightQuarter = function(win)
        setWindowFrame(win, 0.5, 0.5, 0.5, 0.5)
        showActionAlert("moveToBottomRightQuarter", "Window moved to bottom-right 1/4")
    end
}

--- Update WindowManager options
--- @param self table WindowManager instance
--- @param options table Options for alerts and messages
function WindowManager:configure(options)
    options = options or {}

    if options.showAlerts ~= nil then
        self.options.showAlerts = options.showAlerts
    end

    if options.customMessages then
        for key, value in pairs(options.customMessages) do
            self.options.customMessages[key] = value
        end
    end

    local customCount = 0
    for _ in pairs(self.options.customMessages) do
        customCount = customCount + 1
    end

    log:debug(
        "WindowManager configured: showAlerts=%s, customMessages=%d",
        tostring(self.options.showAlerts),
        customCount
    )
end

local function countTableEntries(tbl)
    local count = 0
    for _ in pairs(tbl or {}) do
        count = count + 1
    end
    return count
end

function WindowManager:loadPositions()
    local file = io.open(self.positionsFilePath, "r")
    if not file then
        log:debug("No existing window positions file at %s", self.positionsFilePath)
        self.savedPositions = {}
        return
    end

    local ok, contents = pcall(function()
        return file:read("*a")
    end)
    file:close()

    if not ok or not contents or contents == "" then
        log:warn("Failed to read window positions file: %s", self.positionsFilePath)
        self.savedPositions = {}
        return
    end

    local decoded = hs.json.decode(contents)
    if type(decoded) ~= "table" then
        log:warn("Invalid JSON structure in window positions file")
        self.savedPositions = {}
        return
    end

    self.savedPositions = decoded
    log:debug("Loaded %d window positions from disk", countTableEntries(self.savedPositions))
end

function WindowManager:savePositions()
    local json = hs.json.encode(self.savedPositions, true)
    if not json then
        log:error("Failed to encode window positions table")
        return false
    end

    local dirPath = homeDir .. "/.hammerspoon"
    if dirPath ~= "" and not hs.fs.attributes(dirPath) then
        local ok, err = hs.fs.mkdir(dirPath)
        if not ok then
            log:error("Failed to create directory %s: %s", dirPath, err or "unknown")
            return false
        end
    end

    local file, err = io.open(self.positionsFilePath, "w")
    if not file then
        log:error("Failed to open %s for writing: %s", self.positionsFilePath, err or "unknown")
        return false
    end

    local ok, writeErr = pcall(function()
        file:write(json)
        file:flush()
    end)
    file:close()

    if not ok then
        log:error("Failed to write positions file: %s", writeErr or "unknown")
        return false
    end

    log:debug("Saved %d window positions to disk", countTableEntries(self.savedPositions))
    return true
end

--- Initialize WindowManager with event bus
--- @param self table WindowManager instance
--- @param eventBus table EventBus instance for registering listeners
--- @return table self WindowManager instance
function WindowManager:init(eventBus)
    self.eventBus = eventBus
    self:loadPositions()

    local eventActionMap = {
        ["window:savePosition"] = "saveWindowPosition",
        ["window:restorePosition"] = "restoreWindowPosition",
        ["window:moveLeft"] = "moveToLeftHalf",
        ["window:moveRight"] = "moveToRightHalf",
        ["window:maximize"] = "maximize",
        ["window:center"] = "centerOnScreen",
        ["window:moveTopHalf"] = "moveToTopHalf",
        ["window:moveBottomHalf"] = "moveToBottomHalf",
        ["window:moveLeftThird"] = "moveToLeftThird",
        ["window:moveCenterThird"] = "moveToCenterThird",
        ["window:moveRightThird"] = "moveToRightThird",
        ["window:moveLeftTwoThirds"] = "moveToLeftTwoThirds",
        ["window:moveRightTwoThirds"] = "moveToRightTwoThirds",
        ["window:moveTopLeftQuarter"] = "moveToTopLeftQuarter",
        ["window:moveTopRightQuarter"] = "moveToTopRightQuarter",
        ["window:moveBottomLeftQuarter"] = "moveToBottomLeftQuarter",
        ["window:moveBottomRightQuarter"] = "moveToBottomRightQuarter"
    }

    for eventName, actionName in pairs(eventActionMap) do
        eventBus:on(eventName, function(data)
            local win = (data and data.window) or hs.window.focusedWindow()
            if win then self.actions[actionName](win) end
        end)
    end

    return self
end

function WindowManager:cleanup()
    self.eventBus = nil
    log:debug("WindowManager cleaned up")
end

return WindowManager
