-- WindowManager module unit tests

describe("WindowManager", function()
    local WindowManager

    local function createWindowStub()
        local screen = {
            frame = function()
                return { x = 0, y = 0, w = 1440, h = 900 }
            end,
            getUUID = function()
                return "test-screen-uuid"
            end
        }

        local window = {
            lastFrame = nil,
            frame = function()
                return { x = 0, y = 0, w = 800, h = 600 }
            end,
            screen = function()
                return screen
            end,
            setFrame = function(self, frame)
                self.lastFrame = frame
            end,
            maximize = function(self)
                local screenFrame = screen.frame()
                self.lastFrame = {
                    x = screenFrame.x,
                    y = screenFrame.y,
                    w = screenFrame.w,
                    h = screenFrame.h
                }
            end,
            centerOnScreen = function(self)
                local currentFrame = self.frame()
                local screenFrame = screen.frame()
                self.lastFrame = {
                    x = screenFrame.x + (screenFrame.w - currentFrame.w) / 2,
                    y = screenFrame.y + (screenFrame.h - currentFrame.h) / 2,
                    w = currentFrame.w,
                    h = currentFrame.h
                }
            end
        }

        return window
    end

    before_each(function()
        reset_mocks()
        package.loaded["window_manager"] = nil
        package.loaded["logger"] = nil
        WindowManager = require("window_manager")
    end)

    it("configure disables alerts when showAlerts is false", function()
        local win = createWindowStub()
        WindowManager:configure({ showAlerts = false })

        WindowManager.actions.moveToLeftHalf(win)

        assert.equals(0, #hammerspoon_mock.alert_calls)
    end)

    it("configure re-enables alerts when showAlerts is true", function()
        local win = createWindowStub()
        WindowManager:configure({ showAlerts = false })
        WindowManager.actions.moveToLeftHalf(win)
        assert.equals(0, #hammerspoon_mock.alert_calls)

        WindowManager:configure({ showAlerts = true })
        WindowManager.actions.moveToLeftHalf(win)

        assert.equals(1, #hammerspoon_mock.alert_calls)
        assert.is_truthy(hammerspoon_mock.alert_calls[1].message:match("Window moved to left half"))
    end)

    it("configure applies custom messages for actions", function()
        local win = createWindowStub()
        WindowManager:configure({
            customMessages = {
                moveToLeftHalf = "Custom left side"
            }
        })

        WindowManager.actions.moveToLeftHalf(win)

        assert.equals(1, #hammerspoon_mock.alert_calls)
        assert.equals("Custom left side", hammerspoon_mock.alert_calls[1].message)
    end)

    it("configure merges custom messages without removing existing entries", function()
        local win = createWindowStub()
        WindowManager:configure({ customMessages = { moveToLeftHalf = "Custom left" } })
        WindowManager:configure({ customMessages = { moveToRightHalf = "Custom right" } })

        WindowManager.actions.moveToLeftHalf(win)
        WindowManager.actions.moveToRightHalf(win)

        assert.equals(2, #hammerspoon_mock.alert_calls)
        assert.equals("Custom left", hammerspoon_mock.alert_calls[1].message)
        assert.equals("Custom right", hammerspoon_mock.alert_calls[2].message)
    end)

    it("configure handles nil options by keeping defaults", function()
        local win = createWindowStub()
        WindowManager:configure()

        WindowManager.actions.maximize(win)

        assert.equals(1, #hammerspoon_mock.alert_calls)
        assert.is_truthy(hammerspoon_mock.alert_calls[1].message:match("Window maximized"))
    end)

    describe("Basic Layout Functions", function()
        it("moveToLeftHalf sets window to left half of screen", function()
            local win = createWindowStub()
            WindowManager:configure({ showAlerts = false })

            WindowManager.actions.moveToLeftHalf(win)

            assert.is_not_nil(win.lastFrame)
            assert.equals(0, win.lastFrame.x)
            assert.equals(0, win.lastFrame.y)
            assert.equals(720, win.lastFrame.w)
            assert.equals(900, win.lastFrame.h)
        end)

        it("moveToRightHalf sets window to right half of screen", function()
            local win = createWindowStub()
            WindowManager:configure({ showAlerts = false })

            WindowManager.actions.moveToRightHalf(win)

            assert.is_not_nil(win.lastFrame)
            assert.equals(720, win.lastFrame.x)
            assert.equals(0, win.lastFrame.y)
            assert.equals(720, win.lastFrame.w)
            assert.equals(900, win.lastFrame.h)
        end)

        it("maximize sets window to full screen", function()
            local win = createWindowStub()
            WindowManager:configure({ showAlerts = false })

            WindowManager.actions.maximize(win)

            assert.is_not_nil(win.lastFrame)
            assert.equals(0, win.lastFrame.x)
            assert.equals(0, win.lastFrame.y)
            assert.equals(1440, win.lastFrame.w)
            assert.equals(900, win.lastFrame.h)
        end)

        it("centerOnScreen sets window to center of screen", function()
            local win = createWindowStub()
            WindowManager:configure({ showAlerts = false })

            WindowManager.actions.centerOnScreen(win)

            assert.is_not_nil(win.lastFrame)
            assert.equals(320, win.lastFrame.x)
            assert.equals(150, win.lastFrame.y)
            assert.equals(800, win.lastFrame.w)
            assert.equals(600, win.lastFrame.h)
        end)
    end)

    describe("Third Layout Functions", function()
        it("moveToLeftThird sets window to left third of screen", function()
            local win = createWindowStub()
            WindowManager:configure({ showAlerts = false })

            WindowManager.actions.moveToLeftThird(win)

            assert.is_not_nil(win.lastFrame)
            assert.equals(0, win.lastFrame.x)
            assert.equals(0, win.lastFrame.y)
            assert.equals(480, win.lastFrame.w)
            assert.equals(900, win.lastFrame.h)
        end)

        it("moveToCenterThird sets window to center third of screen", function()
            local win = createWindowStub()
            WindowManager:configure({ showAlerts = false })

            WindowManager.actions.moveToCenterThird(win)

            assert.is_not_nil(win.lastFrame)
            assert.equals(480, win.lastFrame.x)
            assert.equals(0, win.lastFrame.y)
            assert.equals(480, win.lastFrame.w)
            assert.equals(900, win.lastFrame.h)
        end)

        it("moveToRightThird sets window to right third of screen", function()
            local win = createWindowStub()
            WindowManager:configure({ showAlerts = false })

            WindowManager.actions.moveToRightThird(win)

            assert.is_not_nil(win.lastFrame)
            assert.equals(960, win.lastFrame.x)
            assert.equals(0, win.lastFrame.y)
            assert.equals(480, win.lastFrame.w)
            assert.equals(900, win.lastFrame.h)
        end)
    end)

    describe("Two-Thirds Layout Functions", function()
        it("moveToLeftTwoThirds sets window to left two-thirds of screen", function()
            local win = createWindowStub()
            WindowManager:configure({ showAlerts = false })

            WindowManager.actions.moveToLeftTwoThirds(win)

            assert.is_not_nil(win.lastFrame)
            assert.equals(0, win.lastFrame.x)
            assert.equals(0, win.lastFrame.y)
            assert.equals(960, win.lastFrame.w)
            assert.equals(900, win.lastFrame.h)
        end)

        it("moveToRightTwoThirds sets window to right two-thirds of screen", function()
            local win = createWindowStub()
            WindowManager:configure({ showAlerts = false })

            WindowManager.actions.moveToRightTwoThirds(win)

            assert.is_not_nil(win.lastFrame)
            assert.equals(480, win.lastFrame.x)
            assert.equals(0, win.lastFrame.y)
            assert.equals(960, win.lastFrame.w)
            assert.equals(900, win.lastFrame.h)
        end)
    end)

    describe("Quarter Layout Functions", function()
        it("moveToTopLeftQuarter sets window to top-left quarter", function()
            local win = createWindowStub()
            WindowManager:configure({ showAlerts = false })

            WindowManager.actions.moveToTopLeftQuarter(win)

            assert.is_not_nil(win.lastFrame)
            assert.equals(0, win.lastFrame.x)
            assert.equals(0, win.lastFrame.y)
            assert.equals(720, win.lastFrame.w)
            assert.equals(450, win.lastFrame.h)
        end)

        it("moveToTopRightQuarter sets window to top-right quarter", function()
            local win = createWindowStub()
            WindowManager:configure({ showAlerts = false })

            WindowManager.actions.moveToTopRightQuarter(win)

            assert.is_not_nil(win.lastFrame)
            assert.equals(720, win.lastFrame.x)
            assert.equals(0, win.lastFrame.y)
            assert.equals(720, win.lastFrame.w)
            assert.equals(450, win.lastFrame.h)
        end)

        it("moveToBottomLeftQuarter sets window to bottom-left quarter", function()
            local win = createWindowStub()
            WindowManager:configure({ showAlerts = false })

            WindowManager.actions.moveToBottomLeftQuarter(win)

            assert.is_not_nil(win.lastFrame)
            assert.equals(0, win.lastFrame.x)
            assert.equals(450, win.lastFrame.y)
            assert.equals(720, win.lastFrame.w)
            assert.equals(450, win.lastFrame.h)
        end)

        it("moveToBottomRightQuarter sets window to bottom-right quarter", function()
            local win = createWindowStub()
            WindowManager:configure({ showAlerts = false })

            WindowManager.actions.moveToBottomRightQuarter(win)

            assert.is_not_nil(win.lastFrame)
            assert.equals(720, win.lastFrame.x)
            assert.equals(450, win.lastFrame.y)
            assert.equals(720, win.lastFrame.w)
            assert.equals(450, win.lastFrame.h)
        end)
    end)

    describe("Vertical Split Functions", function()
        it("moveToTopHalf sets window to top half of screen", function()
            local win = createWindowStub()
            WindowManager:configure({ showAlerts = false })

            WindowManager.actions.moveToTopHalf(win)

            assert.is_not_nil(win.lastFrame)
            assert.equals(0, win.lastFrame.x)
            assert.equals(0, win.lastFrame.y)
            assert.equals(1440, win.lastFrame.w)
            assert.equals(450, win.lastFrame.h)
        end)

        it("moveToBottomHalf sets window to bottom half of screen", function()
            local win = createWindowStub()
            WindowManager:configure({ showAlerts = false })

            WindowManager.actions.moveToBottomHalf(win)

            assert.is_not_nil(win.lastFrame)
            assert.equals(0, win.lastFrame.x)
            assert.equals(450, win.lastFrame.y)
            assert.equals(1440, win.lastFrame.w)
            assert.equals(450, win.lastFrame.h)
        end)
    end)

    describe("Position Save/Restore Functions", function()
        local tempPositionsFile

        before_each(function()
            tempPositionsFile = os.tmpname()
            _G.hs.configdir = "/tmp"
        end)

        after_each(function()
            if tempPositionsFile then
                os.remove(tempPositionsFile)
            end
        end)

        it("saveWindowPosition saves window position with bundleID", function()
            local app = {
                bundleID = function() return "com.apple.Safari" end
            }
            local win = createWindowStub()
            win.application = function() return app end

            WindowManager.actions.saveWindowPosition(win)

            assert.is_not_nil(WindowManager.savedPositions["com.apple.Safari"])
        end)

        it("restoreWindowPosition restores saved position", function()
            local app = {
                bundleID = function() return "com.apple.Safari" end
            }
            local win = createWindowStub()
            win.application = function() return app end
            win.moveToScreen = function() end

            WindowManager.actions.saveWindowPosition(win)

            win.lastFrame = nil
            WindowManager.actions.restoreWindowPosition(win)

            assert.is_not_nil(win.lastFrame)
            assert.equals(0, win.lastFrame.x)
            assert.equals(0, win.lastFrame.y)
            assert.equals(800, win.lastFrame.w)
            assert.equals(600, win.lastFrame.h)
        end)

        it("restoreWindowPosition does nothing when no position saved", function()
            local app = {
                bundleID = function() return "com.apple.Terminal" end
            }
            local win = createWindowStub()
            win.application = function() return app end

            WindowManager.actions.restoreWindowPosition(win)

            assert.is_nil(win.lastFrame)
        end)
    end)


    describe("EventBus Integration", function()
        it("registers event listeners on init", function()
            local registeredEvents = {}
            local testEventBus = {
                on = function(self, event, callback)
                    table.insert(registeredEvents, event)
                end
            }

            WindowManager:init(testEventBus)

            assert.is_true(#registeredEvents >= 10)
        end)
    end)

    describe("Multi-Monitor Support", function()
        it("calculates position relative to current screen", function()
            local customScreen = {
                frame = function()
                    return { x = 1920, y = 0, w = 1920, h = 1080 }
                end
            }

            local win = {
                lastFrame = nil,
                frame = function()
                    return { x = 1920, y = 0, w = 800, h = 600 }
                end,
                screen = function()
                    return customScreen
                end,
                setFrame = function(self, frame)
                    self.lastFrame = frame
                end
            }

            WindowManager:configure({ showAlerts = false })
            WindowManager.actions.moveToLeftHalf(win)

            assert.is_not_nil(win.lastFrame)
            assert.equals(1920, win.lastFrame.x)
            assert.equals(0, win.lastFrame.y)
            assert.equals(960, win.lastFrame.w)
            assert.equals(1080, win.lastFrame.h)
        end)

        it("handles different screen resolutions", function()
            local smallScreen = {
                frame = function()
                    return { x = 0, y = 0, w = 800, h = 600 }
                end
            }

            local win = {
                lastFrame = nil,
                frame = function()
                    return { x = 0, y = 0, w = 400, h = 300 }
                end,
                screen = function()
                    return smallScreen
                end,
                setFrame = function(self, frame)
                    self.lastFrame = frame
                end,
                maximize = function(self)
                    local screenFrame = smallScreen.frame()
                    self.lastFrame = {
                        x = screenFrame.x,
                        y = screenFrame.y,
                        w = screenFrame.w,
                        h = screenFrame.h
                    }
                end
            }

            WindowManager:configure({ showAlerts = false })
            WindowManager.actions.maximize(win)

            assert.is_not_nil(win.lastFrame)
            assert.equals(0, win.lastFrame.x)
            assert.equals(0, win.lastFrame.y)
            assert.equals(800, win.lastFrame.w)
            assert.equals(600, win.lastFrame.h)
        end)
    end)
end)
