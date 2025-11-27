local ModuleLoader = {}

---@param basePath string Base path for module loading
---@param moduleName string Module name (without .lua extension)
---@return any Module returned by dofile
function ModuleLoader.requireRelative(basePath, moduleName)
    local fullPath = basePath .. moduleName .. ".lua"
    return dofile(fullPath)
end

---@return function requireModule Function that loads modules relative to caller
function ModuleLoader.setupRequireHelper()
    local moduleDir = debug.getinfo(2, "S").source:match("@(.*/)")
    return function(name)
        return ModuleLoader.requireRelative(moduleDir, name)
    end
end

return ModuleLoader
