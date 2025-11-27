-- AppLauncher module unit tests

describe("AppLauncher", function()
    local AppLauncher
    local launchSequence
    local launchCalls
    local timerCalls
    local successfulLaunches

    before_each(function()
        reset_mocks()
        package.loaded["app_launcher"] = nil
        package.loaded["logger"] = nil
        AppLauncher = require("app_launcher")

        launchSequence = {}
        launchCalls = {}
        timerCalls = {}
        successfulLaunches = 0

        _G.hs.application = {
            launchOrFocus = function(appName)
                table.insert(launchCalls, appName)
                local attempt = #launchCalls
                local result = launchSequence[attempt]
                if result == nil then
                    result = true
                end
                if result then
                    successfulLaunches = successfulLaunches + 1
                end
                return result
            end,
            get = function()
                return nil
            end
        }

        _G.hs.timer = {
            doAfter = function(delay, fn)
                table.insert(timerCalls, delay)
                fn()
            end
        }
    end)

    it("launchAppWithRetry succeeds on the first attempt", function()
        local result = AppLauncher:launchAppWithRetry("Safari")

        assert.is_true(result)
        assert.equals(1, successfulLaunches)
        assert.equals(1, #launchCalls)
        assert.equals(0, #timerCalls)
    end)

    it("launchAppWithRetry retries when launching fails", function()
        launchSequence[1] = false
        launchSequence[2] = false
        launchSequence[3] = true

        AppLauncher:launchAppWithRetry("Mail")

        assert.equals(1, successfulLaunches)
        assert.equals(3, #launchCalls)
        assert.equals(2, #timerCalls)
        for _, delay in ipairs(timerCalls) do
            assert.equals(AppLauncher.options.retryDelay, delay)
        end
    end)

    it("launchAppWithRetry stops after reaching the retry limit", function()
        launchSequence[1] = false
        launchSequence[2] = false
        launchSequence[3] = false

        local result = AppLauncher:launchAppWithRetry("GhostApp")

        assert.is_false(result)
        assert.equals(0, successfulLaunches)
        assert.equals(AppLauncher.options.maxRetries + 1, #launchCalls)
        assert.equals(1, #hammerspoon_mock.alert_calls)
        local lastLog = hammerspoon_mock.printf_calls[#hammerspoon_mock.printf_calls]
        assert.is_truthy(lastLog:match("Failed to launch GhostApp"))
    end)

    it("launchAppWithRetry retries immediately when hs.timer is unavailable", function()
        _G.hs.timer = nil
        launchSequence[1] = false
        launchSequence[2] = true

        AppLauncher:launchAppWithRetry("Preview")

        assert.equals(1, successfulLaunches)
        assert.equals(2, #launchCalls)
    end)

    it("toggleApp uses retry logic when the application is not running", function()
        local calledWith
        local original = AppLauncher.launchAppWithRetry
        AppLauncher.launchAppWithRetry = function(self, appName, retryCount)
            calledWith = { appName = appName, retryCount = retryCount }
            return true
        end

        _G.hs.application.get = function()
            return nil
        end

        AppLauncher:toggleApp("com.example.app", "Example")

        assert.is_not_nil(calledWith)
        assert.equals("Example", calledWith.appName)
        assert.equals(0, calledWith.retryCount)

        AppLauncher.launchAppWithRetry = original
    end)
end)
