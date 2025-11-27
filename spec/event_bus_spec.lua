-- EventBus module unit tests

describe("EventBus", function()
    local EventBus

    before_each(function()
        -- Reset mocks
        reset_mocks()

        -- Reload EventBus module for each test
        package.loaded["event_bus"] = nil
        package.loaded["logger"] = nil
        EventBus = require("event_bus")
    end)

    describe("EventBus.new()", function()
        it("should create a new EventBus instance", function()
            local bus = EventBus.new()
            assert.is_not_nil(bus)
            assert.is_table(bus.listeners)
        end)

        it("should create independent instances", function()
            local bus1 = EventBus.new()
            local bus2 = EventBus.new()

            -- Each instance should have its own listeners table
            assert.are_not.equal(bus1.listeners, bus2.listeners)

            -- Modifying one should not affect the other
            bus1.listeners["test"] = {"listener1"}
            assert.is_nil(bus2.listeners["test"])
        end)
    end)

    describe("EventBus:on()", function()
        it("should register an event listener", function()
            local bus = EventBus.new()
            local callback = function() end

            bus:on("test_event", callback)

            assert.is_not_nil(bus.listeners["test_event"])
            assert.equals(1, #bus.listeners["test_event"])
            assert.equals(callback, bus.listeners["test_event"][1])
        end)

        it("should register multiple listeners for the same event", function()
            local bus = EventBus.new()
            local callback1 = function() end
            local callback2 = function() end

            bus:on("test_event", callback1)
            bus:on("test_event", callback2)

            assert.equals(2, #bus.listeners["test_event"])
            assert.equals(callback1, bus.listeners["test_event"][1])
            assert.equals(callback2, bus.listeners["test_event"][2])
        end)

        it("should register listeners for different events independently", function()
            local bus = EventBus.new()
            local callback1 = function() end
            local callback2 = function() end

            bus:on("event1", callback1)
            bus:on("event2", callback2)

            assert.equals(1, #bus.listeners["event1"])
            assert.equals(1, #bus.listeners["event2"])
        end)
    end)

    describe("EventBus:emit()", function()
        it("should call registered listeners when event is emitted", function()
            local bus = EventBus.new()
            local called = false

            bus:on("test_event", function()
                called = true
            end)

            bus:emit("test_event")

            assert.is_true(called)
        end)

        it("should pass data to listeners", function()
            local bus = EventBus.new()
            local receivedData = nil

            bus:on("test_event", function(data)
                receivedData = data
            end)

            local testData = { value = 42, text = "hello" }
            bus:emit("test_event", testData)

            assert.equals(testData, receivedData)
        end)

        it("should call all registered listeners in order", function()
            local bus = EventBus.new()
            local callOrder = {}

            bus:on("test_event", function()
                table.insert(callOrder, 1)
            end)
            bus:on("test_event", function()
                table.insert(callOrder, 2)
            end)
            bus:on("test_event", function()
                table.insert(callOrder, 3)
            end)

            bus:emit("test_event")

            assert.same({1, 2, 3}, callOrder)
        end)

        it("should not fail when emitting event with no listeners", function()
            local bus = EventBus.new()

            -- Should not throw error
            assert.has_no.errors(function()
                bus:emit("non_existent_event")
            end)
        end)

        it("should handle listener errors gracefully", function()
            local bus = EventBus.new()
            local errorListenerCalled = false
            local successListenerCalled = false

            bus:on("test_event", function()
                errorListenerCalled = true
                error("Intentional error")
            end)

            bus:on("test_event", function()
                successListenerCalled = true
            end)

            -- Should not throw error
            assert.has_no.errors(function()
                bus:emit("test_event")
            end)

            -- Both listeners should be called despite error
            assert.is_true(errorListenerCalled)
            assert.is_true(successListenerCalled)
        end)
    end)

    describe("EventBus:off()", function()
        it("should remove all listeners for an event", function()
            local bus = EventBus.new()
            local callback = function() end

            bus:on("test_event", callback)
            assert.is_not_nil(bus.listeners["test_event"])

            bus:off("test_event")
            assert.is_nil(bus.listeners["test_event"])
        end)

        it("should not affect listeners for other events", function()
            local bus = EventBus.new()
            local callback1 = function() end
            local callback2 = function() end

            bus:on("event1", callback1)
            bus:on("event2", callback2)

            bus:off("event1")

            assert.is_nil(bus.listeners["event1"])
            assert.is_not_nil(bus.listeners["event2"])
        end)

        it("should not fail when removing non-existent event", function()
            local bus = EventBus.new()

            assert.has_no.errors(function()
                bus:off("non_existent_event")
            end)
        end)
    end)

    describe("EventBus:clear()", function()
        it("should remove all listeners for all events", function()
            local bus = EventBus.new()

            bus:on("event1", function() end)
            bus:on("event2", function() end)
            bus:on("event3", function() end)

            bus:clear()

            assert.is_nil(next(bus.listeners))
        end)

        it("should allow registering new listeners after clear", function()
            local bus = EventBus.new()
            local called = false

            bus:on("event1", function() end)
            bus:clear()

            bus:on("event2", function()
                called = true
            end)
            bus:emit("event2")

            assert.is_true(called)
        end)
    end)

    describe("Event history", function()
        it("records emitted events with timestamps", function()
            local bus = EventBus.new()
            bus:emit("startup")

            assert.equals(1, #bus.eventHistory)
            local record = bus.eventHistory[1]
            assert.equals("startup", record.event)
            assert.equals(0, record.listenerCount)
            assert.is_number(record.timestamp)
        end)

        it("captures listener counts for each event", function()
            local bus = EventBus.new()
            bus:on("update", function() end)
            bus:on("update", function() end)

            bus:emit("update")

            local lastRecord = bus.eventHistory[#bus.eventHistory]
            assert.equals(2, lastRecord.listenerCount)
        end)

        it("supports limited history retrieval", function()
            local bus = EventBus.new()
            for i = 1, 5 do
                bus:emit("event_" .. i)
            end

            local history = bus:getHistory(3)
            assert.equals(3, #history)
            assert.equals("event_3", history[1].event)
            assert.equals("event_5", history[3].event)
        end)

        it("summarizes registered listeners per event", function()
            local bus = EventBus.new()
            bus:on("alpha", function() end)
            bus:on("alpha", function() end)
            bus:on("beta", function() end)

            local summary = bus:getListeners()
            assert.equals(2, summary.alpha)
            assert.equals(1, summary.beta)
        end)

        it("limits history size to maxHistorySize", function()
            local bus = EventBus.new()
            bus.maxHistorySize = 3

            for i = 1, 5 do
                bus:emit("event" .. i)
            end

            assert.equals(3, #bus.eventHistory)
            assert.equals("event3", bus.eventHistory[1].event)
            assert.equals("event5", bus.eventHistory[#bus.eventHistory].event)
        end)
    end)

    describe("EventBus integration", function()
        it("should support complete event lifecycle", function()
            local bus = EventBus.new()
            local configChangeCount = 0
            local windowMoveCount = 0

            -- Register multiple listeners
            bus:on("config_changed", function()
                configChangeCount = configChangeCount + 1
            end)

            bus:on("window_moved", function(data)
                windowMoveCount = windowMoveCount + 1
                assert.equals("left", data.direction)
            end)

            -- Emit events
            bus:emit("config_changed")
            bus:emit("config_changed")
            bus:emit("window_moved", { direction = "left" })

            assert.equals(2, configChangeCount)
            assert.equals(1, windowMoveCount)

            -- Remove one event
            bus:off("config_changed")
            bus:emit("config_changed")

            -- Should not increment
            assert.equals(2, configChangeCount)

            -- Clear all
            bus:clear()
            bus:emit("window_moved", { direction = "left" })

            -- Should not increment
            assert.equals(1, windowMoveCount)
        end)
    end)
end)
