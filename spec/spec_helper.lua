-- Spec helper: Setup test environment
-- This file is automatically loaded before all tests

-- Load Hammerspoon mock
local mock = require("spec.helpers.hammerspoon_mock")

-- Setup global hs namespace
mock.setup()

-- Export reset function for tests to call in their before_each
_G.reset_mocks = function()
    mock.reset()
end

-- Helper: Get the project root directory
local function getProjectRoot()
    local info = debug.getinfo(1, "S")
    local scriptPath = info.source:match("@(.*/)")
    -- Remove 'spec/' from the end to get project root
    return scriptPath:gsub("spec/$", "")
end

-- Add project root to package.path for module loading
local projectRoot = getProjectRoot()
package.path = projectRoot .. "modules/?.lua;" .. package.path

-- Export mock for test assertions
_G.hammerspoon_mock = mock

-- Print test environment info
print("=== Test Environment ===")
print("Project root: " .. projectRoot)
print("Package path: " .. package.path)
print("========================\n")
