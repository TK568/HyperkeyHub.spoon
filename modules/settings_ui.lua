-- Settings UI module
local SettingsUI = {}

local moduleDir = debug.getinfo(1, "S").source:match("@(.*/)")
local function requireModule(name)
    local fullPath = moduleDir .. name .. ".lua"
    return dofile(fullPath)
end
local Logger = requireModule("logger")
local ConfigLoader = requireModule("config_loader")
local BackupManager = requireModule("config/backup_manager")
local FileUtils = requireModule("utils/file_utils")
local StringUtils = requireModule("utils/string_utils")
local log = Logger.new("SettingsUI")

local KEY_CODES = {
    ESC = 53
}

local SETTINGS_WINDOW = {
    WIDTH = 650,
    HEIGHT = 550
}

local DEFAULT_CONFIG = {
    HYPER_KEY_CODE = 80,  -- F19
    HYPER_KEY_NAME = "F19"
}

--- Start key detection mode for capturing hyper key in settings UI
--- Pauses the main EventTap and creates a temporary one for key detection
--- @param obj table HyperkeyHub instance
function SettingsUI.startKeyDetection(obj)
    if obj.keyDetectionTap then
        SettingsUI.stopKeyDetection(obj)
    end

    obj.isDetectingKey = true

    if obj.hyperTap then
        obj.hyperTap:stop()
    end

    obj.keyDetectionTap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
        -- Check if detection is still active (prevent race condition)
        if not obj.isDetectingKey then
            return false
        end
        local keyCode = event:getKeyCode()

        if keyCode == KEY_CODES.ESC then
            SettingsUI.stopKeyDetection(obj)
            return true
        end

        -- Exclude pure modifier keys (Shift, Cmd, Alt, Ctrl only)
        -- Do not exclude fn flag as it is also set for function keys
        local flags = event:getFlags()
        if flags.shift or flags.cmd or flags.alt or flags.ctrl then
            return false
        end

        local keyName = nil
        for name, code in pairs(hs.keycodes.map) do
            if code == keyCode then
                keyName = name
                break
            end
        end
        if not keyName then
            keyName = string.format("Key%d", keyCode)
        end

        if obj.settingsWindow then
            local safeKeyName = StringUtils.escapeJavaScript(keyName)
            local jsCode = string.format("if (window.setDetectedKey) { window.setDetectedKey(%d, '%s'); }", keyCode, safeKeyName)
            obj.settingsWindow:evaluateJavaScript(jsCode)
        end

        SettingsUI.stopKeyDetection(obj)
        return true
    end)

    obj.keyDetectionTap:start()
end

--- Stop key detection mode and resume main EventTap
--- @param obj table HyperkeyHub instance
function SettingsUI.stopKeyDetection(obj)
    -- Clear flag first to prevent race condition
    obj.isDetectingKey = false

    if obj.keyDetectionTap then
        obj.keyDetectionTap:stop()
        obj.keyDetectionTap = nil
    end

    if obj.hyperTap then
        obj.hyperTap:start()
    end
end

--- Show settings window for configuring HyperkeyHub
--- Uses dependency injection: accepts callbacks instead of direct ConfigLoader dependency
--- @param obj table HyperkeyHub instance
--- @param saveCallback function Callback function for saving settings (config -> success, error)
--- @param onSaveSuccess function Callback function called after successful save (obj -> void)
function SettingsUI.showSettings(obj, saveCallback, onSaveSuccess)
    if obj.settingsWindow then
        obj.settingsWindow:show()
        obj.settingsWindow:focus()
        return
    end

    local spoonPath = nil

    local success, result = pcall(function()
        return hs.spoons.resourcePath(obj.name)
    end)
    if success and result then
        spoonPath = result
    end

    -- Method 2: Direct path specification
    if not spoonPath then
        spoonPath = hs.configdir .. "/Spoons/" .. obj.name .. ".spoon"
    end

    if not spoonPath:match("/$") then
        spoonPath = spoonPath .. "/"
    end

    local htmlPath = spoonPath .. "resources/settings.html"
    local htmlContent, err = FileUtils.readFile(htmlPath)
    if not htmlContent then
        log:alert("❌ Settings HTML file not found or unreadable: " .. htmlPath)
        return
    end

    local mainScreen = hs.screen.mainScreen()
    local screenFrame = mainScreen:frame()
    local windowRect = {
        x = (screenFrame.w - SETTINGS_WINDOW.WIDTH) / 2 + screenFrame.x,
        y = (screenFrame.h - SETTINGS_WINDOW.HEIGHT) / 2 + screenFrame.y,
        w = SETTINGS_WINDOW.WIDTH,
        h = SETTINGS_WINDOW.HEIGHT
    }

    local messageHandler = hs.webview.usercontent.new("settingsMessage")
    messageHandler:setCallback(function(message)
        local data = message.body

        if type(data) == "string" then
            local success, decoded = pcall(hs.json.decode, data)
            if success then
                data = decoded
            end
        end

        if type(data) == "table" and data.action == "save" then
            local success = saveCallback(data.config)
            if success and onSaveSuccess then
                onSaveSuccess(obj)
            end
        elseif type(data) == "table" and data.action == "cancel" then
            if obj.settingsWindow then
                obj.settingsWindow:delete()
                obj.settingsWindow = nil
            end
        elseif type(data) == "table" and data.action == "startKeyDetection" then
            SettingsUI.startKeyDetection(obj)
        elseif type(data) == "table" and data.action == "stopKeyDetection" then
            SettingsUI.stopKeyDetection(obj)
        elseif type(data) == "table" and data.action == "restoreBackup" then
            local backupName = data.backupName
            BackupManager.restoreFromBackup(backupName)
        end
    end)

    obj.settingsWindow = hs.webview.new(windowRect, {}, messageHandler)
    obj.settingsWindow:windowStyle({"titled", "closable", "miniaturizable"})
    obj.settingsWindow:windowTitle("HyperkeyHub Settings")
    obj.settingsWindow:allowTextEntry(true)
    obj.settingsWindow:level(hs.drawing.windowLevels.floating)

    obj.settingsWindow:url("file://" .. htmlPath)

    obj.settingsWindow:navigationCallback(function(action, webView, navID, error)
        if action == "didFinishNavigation" then
            local runningApps = {}

            local excludedBundleIDs = {
                "com.apple.dock",
                "com.apple.WindowManager",
                "com.apple.controlcenter",
                "com.apple.notificationcenterui",
                "com.apple.systemuiserver"
            }

            for _, app in ipairs(hs.application.runningApplications()) do
                local bundleID = app:bundleID()
                local name = app:name()

                if bundleID and name and bundleID ~= "" and name ~= "" then
                    local shouldExclude = false
                    for _, excludedID in ipairs(excludedBundleIDs) do
                        if bundleID == excludedID then
                            shouldExclude = true
                            break
                        end
                    end

                    if not shouldExclude and not name:match("^com%.") then
                        table.insert(runningApps, {
                            name = name,
                            bundle = bundleID
                        })
                    end
                end
            end

            table.sort(runningApps, function(a, b)
                return a.name < b.name
            end)

            if obj.configPath then
                ConfigLoader._customConfigPath = obj.configPath
            end

            local configPath = ConfigLoader.getConfigPath()
            local savedApplications = {}
            local savedHyperKeyCode = DEFAULT_CONFIG.HYPER_KEY_CODE
            local savedHyperKeyName = DEFAULT_CONFIG.HYPER_KEY_NAME
            local savedSystemShortcuts = {}
            local savedScriptShortcuts = {}
            local savedShowAlerts = "all"
            local configLoadError = nil

            local content, err = FileUtils.readFile(configPath)
            if not content then
                configLoadError = string.format("Failed to read config file (%s): %s", configPath, err or "unknown error")
                log:error(configLoadError)
            else
                local success, savedConfig = pcall(hs.json.decode, content)
                if not success then
                    configLoadError = string.format("Failed to parse config JSON: %s", savedConfig)
                    log:error(configLoadError)
                elseif savedConfig then
                    savedApplications = savedConfig.applications or {}
                    savedHyperKeyCode = savedConfig.hyperKeyCode or DEFAULT_CONFIG.HYPER_KEY_CODE
                    savedHyperKeyName = savedConfig.hyperKeyName or DEFAULT_CONFIG.HYPER_KEY_NAME
                    savedSystemShortcuts = savedConfig.system_shortcuts or {}
                    savedScriptShortcuts = savedConfig.script_shortcuts or {}
                    if savedConfig.showAlerts ~= nil then
                        savedShowAlerts = savedConfig.showAlerts
                    end
                    if type(savedSystemShortcuts) ~= "table" then
                        savedSystemShortcuts = {}
                    end
                    if type(savedScriptShortcuts) ~= "table" then
                        savedScriptShortcuts = {}
                    end
                end
            end

            local currentConfig = {
                applications = savedApplications,
                runningApps = runningApps,
                hyperKeyCode = savedHyperKeyCode,
                hyperKeyName = savedHyperKeyName,
                systemShortcuts = savedSystemShortcuts,
                scriptShortcuts = savedScriptShortcuts,
                showAlerts = savedShowAlerts,
                backups = BackupManager.listBackups(configPath),
                configLoadError = configLoadError,
                configPath = configPath
            }

            local configJson = hs.json.encode(currentConfig)
            if not configJson then
                log:error("Failed to encode config to JSON")
                return
            end

            local jsCode = string.format("if (window.loadSettings) { window.loadSettings(%s); }", configJson)
            webView:evaluateJavaScript(jsCode)
        end
    end)

    obj.settingsWindow:show()
end

return SettingsUI
