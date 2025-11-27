local args = {...}
local action = args[1]

local function showErrorAlert(msg, duration)
    local showAlerts = spoon.HyperkeyHub and spoon.HyperkeyHub.showAlerts or "all"
    if showAlerts ~= "none" and showAlerts ~= false then
        hs.alert.show(msg, duration or 2)
    end
end

if action == "save" then
    spoon.HyperkeyHub.EventBus:emit("window:savePosition", {
        window = hs.window.focusedWindow()
    })
elseif action == "restore" then
    spoon.HyperkeyHub.EventBus:emit("window:restorePosition", {
        window = hs.window.focusedWindow()
    })
else
    showErrorAlert("❌ Unknown action: " .. tostring(action))
end
