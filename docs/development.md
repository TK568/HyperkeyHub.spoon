# Development Guide

Guide for contributing to HyperkeyHub development.

## Getting Started

### Prerequisites

- macOS
- [Hammerspoon](https://www.hammerspoon.org/) 0.9.97 or later
- Git
- Lua 5.4+ (for running tests)
- LuaRocks (for test dependencies)
- [Busted](https://olivinelabs.com/busted/) testing framework

### Setup Development Environment

```bash
# Install Hammerspoon
brew install --cask hammerspoon

# Install Lua and LuaRocks
brew install lua luarocks

# Install Busted
luarocks install busted

# Clone repository
cd ~/.hammerspoon/Spoons
git clone https://github.com/TK568/HyperkeyHub.spoon.git
cd HyperkeyHub.spoon
```

### Load Development Version

In `~/.hammerspoon/init.lua`:

```lua
hs.loadSpoon("HyperkeyHub")
spoon.HyperkeyHub:start()
```

## Project Structure

```
HyperkeyHub.spoon/
├── init.lua                    # Main entry point
├── modules/
│   ├── config/
│   │   ├── defaults.lua       # Default configuration
│   │   ├── validator.lua      # Config validation
│   │   ├── backup_manager.lua # Backup management
│   │   └── migrations.lua     # Schema migrations
│   ├── bootstrap.lua          # Module initialization and dependency injection
│   ├── config_loader.lua      # Configuration loader
│   ├── logger.lua             # Logging system
│   ├── event_bus.lua          # Event-driven architecture
│   ├── hyper_key.lua          # Hyper key handling
│   ├── app_launcher.lua       # Application launcher
│   ├── window_manager.lua     # Window management
│   ├── script_runner.lua      # Script execution
│   ├── system_actions.lua     # System actions
│   ├── settings_ui.lua        # Settings GUI (Lua)
│   └── utils/
│       └── table_utils.lua    # Table utilities
├── resources/
│   └── settings.html          # Settings GUI (HTML/CSS/JS)
├── spec/                      # Test suite
│   ├── helpers/
│   │   ├── hammerspoon_mock.lua  # Mock Hammerspoon APIs
│   │   └── integration_helpers.lua # Integration test helpers
│   ├── integration/           # Integration tests
│   │   ├── init_and_setup_integration_spec.lua
│   │   ├── app_and_window_integration_spec.lua
│   │   └── error_handling_integration_spec.lua
│   ├── spec_helper.lua        # Test setup
│   ├── event_bus_spec.lua     # EventBus tests
│   ├── config_loader_spec.lua # ConfigLoader tests
│   ├── migrations_spec.lua    # Migration tests
│   └── ...                    # Other unit tests
├── docs/                      # Documentation
│   ├── installation.md
│   ├── configuration.md
│   ├── usage.md
│   ├── troubleshooting.md
│   └── development.md (this file)
├── README.md                  # English README
├── README.ja.md               # Japanese README
└── LICENSE                    # MIT License
```

## Architecture

### Core Principles

1. **Event-Driven Architecture**: Uses EventBus for loose coupling between modules
2. **Dependency Injection**: SettingsUI uses callbacks instead of direct references
3. **Configuration Priority**: Defaults < JSON < Code-based
4. **Test-Driven**: All core modules have comprehensive unit tests
5. **Migration Support**: Schema versioning for config format changes

### Module Dependencies

```
init.lua
  ├─> config_loader (loads configuration)
  ├─> event_bus (inter-module communication)
  ├─> logger (logging)
  ├─> hyper_key (key handling)
  ├─> app_launcher (app management)
  ├─> window_manager (window management)
  ├─> system_actions (system commands)
  └─> settings_ui (GUI)
```

### Event Bus

The EventBus enables loose coupling:

```lua
-- Publishing events
eventBus:emit("config:loaded", config)
eventBus:emit("app:launched", appName)

-- Subscribing to events
eventBus:on("config:changed", function(newConfig)
    -- Handle config change
end)
```

**Available Events:**
- `config:loaded` - Configuration loaded
- `config:changed` - Configuration updated
- `config:saved` - Configuration saved to file
- `app:launched` - Application launched
- `app:hidden` - Application hidden
- `window:moved` - Window position changed
- `debug:toggled` - Debug mode toggled

## Running Tests

### Lua Unit Tests

#### Run All Tests

```bash
cd ~/.hammerspoon/Spoons/HyperkeyHub.spoon
busted
```

#### Run Specific Test File

```bash
busted spec/event_bus_spec.lua
busted spec/config_loader_spec.lua
busted spec/migrations_spec.lua
```

#### Run with Verbose Output

```bash
busted --verbose
```

#### Run Integration Tests Only

```bash
busted spec/integration/
```

Integration tests verify module interactions:
- `init_and_setup_integration_spec.lua` - Initialization and setup flow
- `app_and_window_integration_spec.lua` - App launcher and window manager interaction
- `error_handling_integration_spec.lua` - Error handling across modules

#### Test Coverage

Covered modules:
- ✅ EventBus (100% coverage)
- ✅ ConfigLoader (100% coverage)
- ✅ Migrations (100% coverage)
- ✅ Validator (95% coverage)
- ✅ BackupManager (90% coverage)
- ✅ Bootstrap (100% coverage)
- ✅ Integration Tests (comprehensive coverage)

### JavaScript Static Analysis (ESLint)

Performs static analysis on JavaScript code in settings.html to detect undefined variables and code style issues.

#### Initial Setup

```bash
cd ~/.hammerspoon/Spoons/HyperkeyHub.spoon
npm install
```

#### Running Static Analysis

```bash
# Check code
npm run lint

# Auto-fix fixable issues
npm run lint:fix
```

#### Detected Issues

- **Error**: Undefined variables, syntax errors (must fix)
- **Warning**: Code style, unused variables (recommended to fix)

**Example:**
```
/resources/settings.html
  1016:34  error    'defaultWindowActions' is not defined      no-undef
  1017:33  error    'getEffectiveWindowBinding' is not defined no-undef

✖ 2 problems (2 errors, 0 warnings)
```

#### Pre-commit Checklist

- [ ] `npm run lint` shows 0 errors
- [ ] `busted` passes all Lua tests
- [ ] Settings window displays correctly

## Writing Tests

### Test Structure

```lua
describe("ModuleName", function()
    local module

    before_each(function()
        -- Setup before each test
        module = require("modules.module_name")
    end)

    after_each(function()
        -- Cleanup after each test
        module = nil
    end)

    describe("functionName", function()
        it("should do something", function()
            local result = module.functionName(arg)
            assert.are.equal(expected, result)
        end)

        it("should handle errors", function()
            assert.has_error(function()
                module.functionName(invalidArg)
            end)
        end)
    end)
end)
```

### Using Hammerspoon Mocks

```lua
local helpers = require("spec.helpers.hammerspoon_mock")

describe("Module with hs dependencies", function()
    before_each(function()
        helpers.setup()
    end)

    after_each(function()
        helpers.teardown()
    end)

    it("uses mocked hs API", function()
        -- hs.* functions are mocked
        local result = hs.application.find("Safari")
        assert.is_not_nil(result)
    end)
end)
```

## Code Style

### Lua Conventions

```lua
-- Module structure
local M = {}

-- Private functions (local)
local function privateFunction()
    -- Implementation
end

-- Public functions
function M.publicFunction()
    -- Implementation
end

-- Constants (UPPERCASE)
local DEFAULT_TIMEOUT = 5

-- Variables (camelCase)
local isEnabled = true
local windowFrame = {x = 0, y = 0, w = 100, h = 100}

return M
```

### LuaDoc Comments

All public functions should have LuaDoc comments:

```lua
--- Brief description of function
---
--- Detailed description if needed
---
--- @param paramName string Description of parameter
--- @param optionalParam? number Optional parameter
--- @return boolean True if successful, false otherwise
--- @return string? Error message if failed
---
--- @usage
--- local success, err = module.functionName("value", 42)
--- if not success then
---     print("Error:", err)
--- end
function M.functionName(paramName, optionalParam)
    -- Implementation
end
```

### Naming Conventions

- **Modules**: lowercase with underscores (`config_loader.lua`)
- **Functions**: camelCase (`loadConfig()`)
- **Classes/Objects**: PascalCase (`EventBus`)
- **Constants**: UPPERCASE with underscores (`DEFAULT_CONFIG`)
- **Private functions**: prefix with underscore (`_internalHelper()`)

## Contributing

### Workflow

1. **Fork the repository**
   ```bash
   # On GitHub, click "Fork"
   git clone https://github.com/YOUR_USERNAME/HyperkeyHub.spoon.git
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/my-new-feature
   ```

3. **Make changes**
   - Write code
   - Add tests
   - Update documentation

4. **Run tests**
   ```bash
   busted
   ```

5. **Commit changes**
   ```bash
   git add .
   git commit -m "Add: Brief description of changes"
   ```

6. **Push to GitHub**
   ```bash
   git push origin feature/my-new-feature
   ```

7. **Create Pull Request**
   - Go to GitHub repository
   - Click "New Pull Request"
   - Select your feature branch
   - Fill in PR template

### Commit Message Convention

Use conventional commit format:

```
Type: Brief description

Detailed explanation if needed

- Bullet points for specific changes
- Another change
```

**Types:**
- `Add:` New feature
- `Fix:` Bug fix
- `Update:` Enhancement to existing feature
- `Refactor:` Code restructuring
- `Test:` Adding or updating tests
- `Docs:` Documentation changes
- `Chore:` Maintenance tasks

**Examples:**
```
Add: Window position memory feature

Implement save/restore window positions across sessions.

- Add window_positions.json storage
- Add Hyper+Shift+S to save positions
- Add Hyper+Shift+W to restore positions

Fix: Electron app hiding on macOS 14+

The previous method using AXPress doesn't work reliably on
Sonoma. Switch to menu bar click method.

Update: Improve Settings UI validation

Add real-time validation for duplicate key combinations.
```

### Pull Request Guidelines

**Before submitting:**
- [ ] All tests pass (`busted`)
- [ ] New features have tests
- [ ] Documentation updated (if applicable)
- [ ] Code follows style guide
- [ ] Commit messages follow convention
- [ ] No merge conflicts with main branch

**PR Template:**

```markdown
## Description
Brief description of changes

## Motivation
Why is this change needed?

## Changes
- List of specific changes
- Another change

## Testing
How to test these changes:
1. Step 1
2. Step 2

## Screenshots (if applicable)
[Add screenshots]

## Checklist
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] All tests passing
- [ ] Follows code style
```

## Debugging

### Enable Debug Logging

```lua
-- In init.lua
spoon.HyperkeyHub.logger:setLogLevel("debug")

-- Or press Hyper + Shift + D
```

### Console Output

```lua
-- View in Hammerspoon Console (Hyper + Shift + H)
print("Debug message:", hs.inspect(variable))

-- Using logger
spoon.HyperkeyHub.logger:d("Debug message")
spoon.HyperkeyHub.logger:i("Info message")
spoon.HyperkeyHub.logger:w("Warning message")
spoon.HyperkeyHub.logger:e("Error message")
```

### Event Bus Debugging

```lua
-- Subscribe to all events
spoon.HyperkeyHub.eventBus:on("*", function(event, ...)
    print("Event:", event, "Args:", hs.inspect({...}))
end)
```

### Reload Development Changes

```lua
-- Quick reload: Hyper + Shift + R
-- Or in console:
hs.reload()
```

## Adding Features

### Adding a New System Action

1. **Define action in system_actions.lua:**
```lua
M.actions.myAction = {
    key = "m",
    modifiers = {"shift"},
    action = function()
        -- Implementation
    end,
    name = "My Action"
}
```

2. **Add to default config (modules/config/defaults.lua):**
```lua
system_shortcuts = {
    myAction = {
        key = "m",
        modifiers = {"shift"}
    }
}
```

3. **Add test (spec/system_actions_spec.lua):**
```lua
it("should execute myAction", function()
    local executed = false
    M.actions.myAction.action = function() executed = true end
    M.actions.myAction.action()
    assert.is_true(executed)
end)
```

4. **Update documentation (docs/usage.md)**

### Adding a New Window Layout

1. **Define in window_manager.lua:**
```lua
layouts.myLayout = {
    name = "My Layout",
    apply = function(window)
        local screen = window:screen():frame()
        window:setFrame({
            x = screen.x,
            y = screen.y,
            w = screen.w * 0.5,
            h = screen.h * 0.5
        })
    end
}
```

2. **Add to defaults:**
```lua
window_management = {
    myLayout = {
        key = "l",
        modifiers = {"cmd"}
    }
}
```

3. **Test and document**

### Schema Migrations

When changing config file structure:

1. **Update schema_version in defaults.lua**
2. **Add migration in modules/config/migrations.lua:**
```lua
-- Migration from v1 to v2
[2] = function(config)
    -- Transform config structure
    config.newField = config.oldField
    config.oldField = nil
    return config
end
```

3. **Add migration tests (spec/migrations_spec.lua)**

## Release Process

1. **Update version** in docs and metadata
2. **Run all tests**: `busted`
3. **Create git tag**: `git tag -a v1.0.0 -m "Release 1.0.0"`
4. **Push tag**: `git push origin v1.0.0`
5. **Create GitHub release** with release notes
6. **Build release package**: `zip -r HyperkeyHub.spoon.zip HyperkeyHub.spoon`

## Resources

### Documentation
- [Hammerspoon API](http://www.hammerspoon.org/docs/)
- [Lua 5.4 Reference](https://www.lua.org/manual/5.4/)
- [Busted Testing](https://olivinelabs.com/busted/)

### Community
- [Hammerspoon GitHub](https://github.com/Hammerspoon/hammerspoon)
- [Hammerspoon Discussions](https://github.com/Hammerspoon/hammerspoon/discussions)

### Related Projects
- [Spoons Repository](https://www.hammerspoon.org/Spoons/)
- [Karabiner-Elements](https://karabiner-elements.pqrs.org/)

## Getting Help

- **Issues**: [GitHub Issues](https://github.com/TK568/HyperkeyHub.spoon/issues)
- **Discussions**: Create discussion for questions
- **Pull Requests**: For code contributions

## License

MIT License - See [LICENSE](../LICENSE) for details

## Credits

- Electron app hide solution: [Hammerspoon Issue #3580](https://github.com/Hammerspoon/hammerspoon/issues/3580)
- Modal key approach: [Evan Travers](https://evantravers.com/articles/2020/06/08/hammerspoon-a-better-better-hyper-key/)

## Next Steps

- Read [Usage Guide](usage.md) to understand features
- Check [Configuration Guide](configuration.md) for config details
- Review [Troubleshooting](troubleshooting.md) for common issues
