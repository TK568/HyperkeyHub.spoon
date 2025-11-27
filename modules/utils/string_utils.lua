local StringUtils = {}

---@param arg any Argument to escape for shell execution
---@return string Escaped shell argument
function StringUtils.escapeShellArg(arg)
    return tostring(arg):gsub("'", "'\\''")
end

---@param str string String to escape for JavaScript evaluation
---@return string Escaped JavaScript string
function StringUtils.escapeJavaScript(str)
    if not str then return "" end
    return str:gsub("\\", "\\\\")
              :gsub("'", "\\'")
              :gsub('"', '\\"')
              :gsub("\n", "\\n")
              :gsub("\r", "\\r")
              :gsub("\t", "\\t")
end

return StringUtils
