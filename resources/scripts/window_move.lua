local args = ...
local action = args.action
local x = tonumber(args.x) or 0
local y = tonumber(args.y) or 0
local w = tonumber(args.w) or 1
local h = tonumber(args.h) or 1
local message = args.message or "Window moved"
local gap = tonumber(args.gap) or 0

local function showAlert(msg, duration)
    local showAlerts = spoon.HyperkeyHub and spoon.HyperkeyHub.showAlerts or "all"
    if showAlerts == "all" or showAlerts == true then
        hs.alert.show(msg, duration or 2)
    end
end

local function showErrorAlert(msg, duration)
    local showAlerts = spoon.HyperkeyHub and spoon.HyperkeyHub.showAlerts or "all"
    if showAlerts ~= "none" and showAlerts ~= false then
        hs.alert.show(msg, duration or 2)
    end
end

local animationDuration = 0.2
hs.window.animationDuration = animationDuration

local win = hs.window.focusedWindow()
if not win then
    showErrorAlert("❌ No focused window")
    return
end

if action == "move" then
    local frame = win:frame()
    local screen = win:screen()
    local screenFrame = screen:frame()

    local halfGap = gap / 2

    frame.x = screenFrame.x + (screenFrame.w * x) + halfGap
    frame.y = screenFrame.y + (screenFrame.h * y) + halfGap
    frame.w = (screenFrame.w * w) - gap
    frame.h = (screenFrame.h * h) - gap

    win:setFrame(frame)
    showAlert(message, 2)
elseif action == "maximize" then
    if gap > 0 then
        local screen = win:screen()
        local screenFrame = screen:frame()
        local frame = win:frame()
        local halfGap = gap / 2
        frame.x = screenFrame.x + halfGap
        frame.y = screenFrame.y + halfGap
        frame.w = screenFrame.w - gap
        frame.h = screenFrame.h - gap
        win:setFrame(frame)
    else
        win:maximize()
    end
    showAlert(message, 2)
elseif action == "center" then
    win:centerOnScreen()
    showAlert(message, 2)
else
    showErrorAlert("❌ Unknown action: " .. tostring(action))
end
