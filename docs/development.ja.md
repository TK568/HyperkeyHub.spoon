# 開発ガイド

HyperkeyHubの開発に貢献するためのガイドです。

## はじめに

### 前提条件

- macOS
- [Hammerspoon](https://www.hammerspoon.org/) 0.9.97以降
- Git
- Lua 5.4+（テスト実行用）
- LuaRocks（テスト依存関係用）
- [Busted](https://olivinelabs.com/busted/)テストフレームワーク

### 開発環境のセットアップ

```bash
# Hammerspoonをインストール
brew install --cask hammerspoon

# LuaとLuaRocksをインストール
brew install lua luarocks

# Bustedをインストール
luarocks install busted

# リポジトリをクローン
cd ~/.hammerspoon/Spoons
git clone https://github.com/TK568/HyperkeyHub.spoon.git
cd HyperkeyHub.spoon
```

### 開発版を読み込む

`~/.hammerspoon/init.lua`内：

```lua
hs.loadSpoon("HyperkeyHub")
spoon.HyperkeyHub:start()
```

## プロジェクト構造

```
HyperkeyHub.spoon/
├── init.lua                    # メインエントリポイント
├── modules/
│   ├── config/
│   │   ├── defaults.lua       # デフォルト設定
│   │   ├── validator.lua      # 設定バリデーション
│   │   ├── backup_manager.lua # バックアップ管理
│   │   └── migrations.lua     # スキーママイグレーション
│   ├── bootstrap.lua          # モジュール初期化と依存性注入
│   ├── config_loader.lua      # 設定ローダー
│   ├── logger.lua             # ロギングシステム
│   ├── event_bus.lua          # イベント駆動アーキテクチャ
│   ├── hyper_key.lua          # Hyperキー処理
│   ├── app_launcher.lua       # アプリケーションランチャー
│   ├── window_manager.lua     # ウィンドウ管理
│   ├── script_runner.lua      # スクリプト実行
│   ├── system_actions.lua     # システムアクション
│   ├── settings_ui.lua        # 設定GUI（Lua側）
│   └── utils/
│       └── table_utils.lua    # テーブルユーティリティ
├── resources/
│   └── settings.html          # 設定GUI（HTML/CSS/JS）
├── spec/                      # テストスイート
│   ├── helpers/
│   │   ├── hammerspoon_mock.lua  # Hammerspoon APIのモック
│   │   └── integration_helpers.lua # 統合テストヘルパー
│   ├── integration/           # 統合テスト
│   │   ├── init_and_setup_integration_spec.lua
│   │   ├── app_and_window_integration_spec.lua
│   │   └── error_handling_integration_spec.lua
│   ├── spec_helper.lua        # テストセットアップ
│   ├── event_bus_spec.lua     # EventBusテスト
│   ├── config_loader_spec.lua # ConfigLoaderテスト
│   ├── migrations_spec.lua    # マイグレーションテスト
│   └── ...                    # その他のユニットテスト
├── docs/                      # ドキュメント
│   ├── installation.ja.md
│   ├── configuration.ja.md
│   ├── usage.ja.md
│   ├── troubleshooting.ja.md
│   └── development.ja.md（このファイル）
├── README.md                  # 英語版README
├── README.ja.md               # 日本語版README
└── LICENSE                    # MITライセンス
```

## アーキテクチャ

### 核となる原則

1. **イベント駆動アーキテクチャ**: EventBusを使用してモジュール間を疎結合に
2. **依存性注入**: SettingsUIは直接参照の代わりにコールバックを使用
3. **設定の優先順位**: デフォルト < JSON < コードベース
4. **テスト駆動**: すべてのコアモジュールに包括的な単体テストあり
5. **マイグレーションサポート**: 設定フォーマット変更用のスキーマバージョニング

### モジュール依存関係

```
init.lua
  ├─> config_loader（設定を読み込む）
  ├─> event_bus（モジュール間通信）
  ├─> logger（ロギング）
  ├─> hyper_key（キー処理）
  ├─> app_launcher（アプリ管理）
  ├─> window_manager（ウィンドウ管理）
  ├─> system_actions（システムコマンド）
  └─> settings_ui（GUI）
```

### EventBus

EventBusは疎結合を実現します：

```lua
-- イベントの発行
eventBus:emit("config:loaded", config)
eventBus:emit("app:launched", appName)

-- イベントの購読
eventBus:on("config:changed", function(newConfig)
    -- 設定変更を処理
end)
```

**利用可能なイベント:**
- `config:loaded` - 設定が読み込まれた
- `config:changed` - 設定が更新された
- `config:saved` - 設定がファイルに保存された
- `app:launched` - アプリケーションが起動された
- `app:hidden` - アプリケーションが非表示になった
- `window:moved` - ウィンドウ位置が変更された
- `debug:toggled` - デバッグモードが切り替えられた

## テストの実行

### Luaユニットテスト

#### すべてのテストを実行

```bash
cd ~/.hammerspoon/Spoons/HyperkeyHub.spoon
busted
```

#### 特定のテストファイルを実行

```bash
busted spec/event_bus_spec.lua
busted spec/config_loader_spec.lua
busted spec/migrations_spec.lua
```

#### 詳細出力で実行

```bash
busted --verbose
```

#### 統合テストのみ実行

```bash
busted spec/integration/
```

統合テストはモジュール間の連携を検証します：
- `init_and_setup_integration_spec.lua` - 初期化とセットアップフロー
- `app_and_window_integration_spec.lua` - アプリランチャーとウィンドウマネージャーの連携
- `error_handling_integration_spec.lua` - モジュール間のエラーハンドリング

#### テストカバレッジ

カバーされているモジュール:
- ✅ EventBus（100%カバレッジ）
- ✅ ConfigLoader（100%カバレッジ）
- ✅ Migrations（100%カバレッジ）
- ✅ Validator（95%カバレッジ）
- ✅ BackupManager（90%カバレッジ）
- ✅ Bootstrap（100%カバレッジ）
- ✅ 統合テスト（包括的カバレッジ）

### JavaScriptの静的解析（ESLint）

settings.htmlのJavaScriptコードを静的解析します。未定義変数やコードスタイルの問題を検出します。

#### 初回セットアップ

```bash
cd ~/.hammerspoon/Spoons/HyperkeyHub.spoon
npm install
```

#### 静的解析の実行

```bash
# コードチェック
npm run lint

# 自動修正可能な問題を修正
npm run lint:fix
```

#### 検出される問題

- **エラー（Error）**: 未定義変数、構文エラー（必須修正）
- **警告（Warning）**: コードスタイル、未使用変数（推奨修正）

**例:**
```
/resources/settings.html
  1016:34  error    'defaultWindowActions' is not defined      no-undef
  1017:33  error    'getEffectiveWindowBinding' is not defined no-undef

✖ 2 problems (2 errors, 0 warnings)
```

#### コミット前チェックリスト

- [ ] `npm run lint` でエラー（error）が0件であること
- [ ] `busted` ですべてのLuaテストが通ること
- [ ] 設定画面が正常に表示されること

## テストの記述

### テスト構造

```lua
describe("モジュール名", function()
    local module

    before_each(function()
        -- 各テスト前のセットアップ
        module = require("modules.module_name")
    end)

    after_each(function()
        -- 各テスト後のクリーンアップ
        module = nil
    end)

    describe("関数名", function()
        it("何かを行うべき", function()
            local result = module.functionName(arg)
            assert.are.equal(expected, result)
        end)

        it("エラーを処理すべき", function()
            assert.has_error(function()
                module.functionName(invalidArg)
            end)
        end)
    end)
end)
```

### Hammerspoonモックの使用

```lua
local helpers = require("spec.helpers.hammerspoon_mock")

describe("hs依存関係を持つモジュール", function()
    before_each(function()
        helpers.setup()
    end)

    after_each(function()
        helpers.teardown()
    end)

    it("モックされたhs APIを使用", function()
        -- hs.*関数はモックされています
        local result = hs.application.find("Safari")
        assert.is_not_nil(result)
    end)
end)
```

## コードスタイル

### Luaの規約

```lua
-- モジュール構造
local M = {}

-- プライベート関数（local）
local function privateFunction()
    -- 実装
end

-- パブリック関数
function M.publicFunction()
    -- 実装
end

-- 定数（大文字）
local DEFAULT_TIMEOUT = 5

-- 変数（キャメルケース）
local isEnabled = true
local windowFrame = {x = 0, y = 0, w = 100, h = 100}

return M
```

### LuaDocコメント

すべてのパブリック関数にLuaDocコメントを付ける：

```lua
--- 関数の簡単な説明
---
--- 必要に応じて詳細な説明
---
--- @param paramName string パラメータの説明
--- @param optionalParam? number オプションのパラメータ
--- @return boolean 成功時はtrue、失敗時はfalse
--- @return string? 失敗時のエラーメッセージ
---
--- @usage
--- local success, err = module.functionName("value", 42)
--- if not success then
---     print("エラー:", err)
--- end
function M.functionName(paramName, optionalParam)
    -- 実装
end
```

### 命名規約

- **モジュール**: アンダースコア付き小文字（`config_loader.lua`）
- **関数**: キャメルケース（`loadConfig()`）
- **クラス/オブジェクト**: パスカルケース（`EventBus`）
- **定数**: アンダースコア付き大文字（`DEFAULT_CONFIG`）
- **プライベート関数**: アンダースコア接頭辞（`_internalHelper()`）

## コントリビューション

### ワークフロー

1. **リポジトリをフォーク**
   ```bash
   # GitHubで「Fork」をクリック
   git clone https://github.com/YOUR_USERNAME/HyperkeyHub.spoon.git
   ```

2. **機能ブランチを作成**
   ```bash
   git checkout -b feature/my-new-feature
   ```

3. **変更を加える**
   - コードを書く
   - テストを追加
   - ドキュメントを更新

4. **テストを実行**
   ```bash
   busted
   ```

5. **変更をコミット**
   ```bash
   git add .
   git commit -m "Add: 変更の簡単な説明"
   ```

6. **GitHubにプッシュ**
   ```bash
   git push origin feature/my-new-feature
   ```

7. **プルリクエストを作成**
   - GitHubリポジトリに移動
   - 「New Pull Request」をクリック
   - 機能ブランチを選択
   - PRテンプレートに記入

### コミットメッセージの規約

従来のコミット形式を使用：

```
種類: 簡単な説明

必要に応じて詳細な説明

- 特定の変更の箇条書き
- 別の変更
```

**種類:**
- `Add:` 新機能
- `Fix:` バグ修正
- `Update:` 既存機能の改善
- `Refactor:` コード再構成
- `Test:` テストの追加または更新
- `Docs:` ドキュメントの変更
- `Chore:` メンテナンスタスク

**例:**
```
Add: ウィンドウ位置記憶機能

セッション間でウィンドウ位置を保存・復元する機能を実装。

- window_positions.jsonストレージを追加
- Hyper+Shift+Sで位置を保存
- Hyper+Shift+Wで位置を復元

Fix: macOS 14+でのElectronアプリ非表示問題

以前のAXPressを使用した方法はSonomaで信頼性が低い。
メニューバークリック方式に切り替え。
```

### プルリクエストガイドライン

**提出前に:**
- [ ] すべてのテストが通る（`busted`）
- [ ] 新機能にテストがある
- [ ] ドキュメントが更新されている（該当する場合）
- [ ] コードがスタイルガイドに従っている
- [ ] コミットメッセージが規約に従っている
- [ ] mainブランチとのマージコンフリクトがない

## デバッグ

### デバッグログを有効化

```lua
-- init.luaで
spoon.HyperkeyHub.logger:setLogLevel("debug")

-- またはHyper + Shift + Dを押す
```

### コンソール出力

```lua
-- Hammerspoonコンソールで確認（Hyper + Shift + H）
print("デバッグメッセージ:", hs.inspect(variable))

-- ロガーを使用
spoon.HyperkeyHub.logger:d("デバッグメッセージ")
spoon.HyperkeyHub.logger:i("情報メッセージ")
spoon.HyperkeyHub.logger:w("警告メッセージ")
spoon.HyperkeyHub.logger:e("エラーメッセージ")
```

### EventBusのデバッグ

```lua
-- すべてのイベントを購読
spoon.HyperkeyHub.eventBus:on("*", function(event, ...)
    print("イベント:", event, "引数:", hs.inspect({...}))
end)
```

### 開発の変更をリロード

```lua
-- クイックリロード: Hyper + Shift + R
-- またはコンソールで:
hs.reload()
```

## 機能の追加

### 新しいシステムアクションの追加

1. **system_actions.luaでアクションを定義:**
```lua
M.actions.myAction = {
    key = "m",
    modifiers = {"shift"},
    action = function()
        -- 実装
    end,
    name = "My Action"
}
```

2. **デフォルト設定に追加（modules/config/defaults.lua）:**
```lua
system_shortcuts = {
    myAction = {
        key = "m",
        modifiers = {"shift"}
    }
}
```

3. **テストを追加（spec/system_actions_spec.lua）:**
```lua
it("should execute myAction", function()
    local executed = false
    M.actions.myAction.action = function() executed = true end
    M.actions.myAction.action()
    assert.is_true(executed)
end)
```

4. **ドキュメントを更新（docs/usage.ja.md）**

### 新しいウィンドウレイアウトの追加

1. **window_manager.luaで定義:**
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

2. **デフォルト設定に追加:**
```lua
window_management = {
    myLayout = {
        key = "l",
        modifiers = {"cmd"}
    }
}
```

3. **テストとドキュメント化**

### スキーママイグレーション

設定ファイル構造を変更する場合：

1. **defaults.luaのschema_versionを更新**
2. **modules/config/migrations.luaにマイグレーションを追加:**
```lua
-- v1からv2へのマイグレーション
[2] = function(config)
    -- 設定構造を変換
    config.newField = config.oldField
    config.oldField = nil
    return config
end
```

3. **マイグレーションテストを追加（spec/migrations_spec.lua）**

## リリースプロセス

1. **バージョンを更新** - ドキュメントとメタデータ
2. **全テストを実行**: `busted`
3. **gitタグを作成**: `git tag -a v1.0.0 -m "Release 1.0.0"`
4. **タグをプッシュ**: `git push origin v1.0.0`
5. **GitHub releaseを作成** - リリースノート付き
6. **リリースパッケージをビルド**: `zip -r HyperkeyHub.spoon.zip HyperkeyHub.spoon`

## リソース

### ドキュメント
- [Hammerspoon API](http://www.hammerspoon.org/docs/)
- [Lua 5.4リファレンス](https://www.lua.org/manual/5.4/)
- [Bustedテスティング](https://olivinelabs.com/busted/)

### コミュニティ
- [Hammerspoon GitHub](https://github.com/Hammerspoon/hammerspoon)
- [Hammerspoon Discussions](https://github.com/Hammerspoon/hammerspoon/discussions)

### 関連プロジェクト
- [Spoonsリポジトリ](https://www.hammerspoon.org/Spoons/)
- [Karabiner-Elements](https://karabiner-elements.pqrs.org/)

## ヘルプを得る

- **Issues**: [GitHub Issues](https://github.com/TK568/HyperkeyHub.spoon/issues)
- **Discussions**: 質問用のディスカッションを作成
- **Pull Requests**: コード貢献用

## ライセンス

MIT License - 詳細は[LICENSE](../LICENSE)を参照

## クレジット

- Electron製アプリの非表示問題の解決策: [Hammerspoon Issue #3580](https://github.com/Hammerspoon/hammerspoon/issues/3580)
- モーダルキーアプローチ: [Evan Travers](https://evantravers.com/articles/2020/06/08/hammerspoon-a-better-better-hyper-key/)

## 次のステップ

- [使い方ガイド](usage.ja.md)で機能を理解
- [設定ガイド](configuration.ja.md)で設定の詳細を確認
- [トラブルシューティング](troubleshooting.ja.md)でよくある問題を確認
