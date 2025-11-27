-- Event bus for loose coupling between modules

---@class EventBus
---@field listeners table<string, function[]> Event listeners map
local EventBus = {}
EventBus.__index = EventBus

local moduleDir = debug.getinfo(1, "S").source:match("@(.*/)")
local function requireModule(name)
    local fullPath = moduleDir .. name .. ".lua"
    return dofile(fullPath)
end
local Logger = requireModule("logger")
local log = Logger.new("EventBus")

---@return EventBus instance New EventBus instance
function EventBus.new()
    local self = setmetatable({}, EventBus)
    self.listeners = {}
    self.eventHistory = {}
    self.maxHistorySize = 100
    log:debug("EventBus instance created")
    return self
end

---@param event string Event name
---@param callback function Callback function to execute on event
function EventBus:on(event, callback)
    if not self.listeners[event] then
        self.listeners[event] = {}
    end
    table.insert(self.listeners[event], callback)
    log:debug("Registered listener for event: %s", event)
end

---@param event string Event name
---@param data any|nil Data to pass to listeners
function EventBus:emit(event, data)
    table.insert(self.eventHistory, {
        event = event,
        timestamp = os.time(),
        listenerCount = self.listeners[event] and #self.listeners[event] or 0
    })

    if #self.eventHistory > self.maxHistorySize then
        table.remove(self.eventHistory, 1)
    end

    if self.listeners[event] then
        log:debug("Emitting event: %s (listeners: %d)", event, #self.listeners[event])
        for _, callback in ipairs(self.listeners[event]) do
            local success, err = pcall(callback, data)
            if not success then
                log:error("Error in event '%s': %s", event, err)
            end
        end
    else
        log:debug("No listeners for event: %s", event)
    end
end

---@param event string Event name
function EventBus:off(event)
    self.listeners[event] = nil
    log:debug("Removed all listeners for event: %s", event)
end

function EventBus:clear()
    self.listeners = {}
    log:debug("Cleared all event listeners")
end

function EventBus:getHistory(limit)
    limit = limit or 10
    local history = {}
    local startIdx = math.max(1, #self.eventHistory - limit + 1)
    for i = startIdx, #self.eventHistory do
        table.insert(history, self.eventHistory[i])
    end
    return history
end

function EventBus:getListeners()
    local summary = {}
    for event, listeners in pairs(self.listeners) do
        summary[event] = #listeners
    end
    return summary
end

return EventBus
