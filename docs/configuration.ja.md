# 設定ガイド

HyperkeyHubは、柔軟性の異なる3つの設定方法を提供しています。

## 設定方法の概要

| 方法 | 最適なユーザー | 柔軟性 | 使いやすさ |
|------|-------------|--------|----------|
| **GUI設定** | ほとんどのユーザー | ★★☆ | ★★★ |
| **JSONファイル** | パワーユーザー | ★★☆ | ★★☆ |
| **コードベース** | 開発者 | ★★★ | ★☆☆ |

**設定の優先順位:**
1. デフォルト設定（組み込み）
2. JSON設定ファイル（存在する場合）
3. `:configure()`によるコードベース設定（最優先）

## 方法1: GUI設定（推奨）

HyperkeyHubを設定する最も簡単な方法です。

### 設定画面を開く

1. メニューバーの✧アイコンをクリック
2. "⚙️ Settings..."を選択

### 利用可能な設定

#### Generalタブ

**✧ (Hyper) キー:**
- プリセットから選択: F15、F16、F17、F18、F19（デフォルト）
- または「キー検出」をクリックして任意のキーを押す

#### Shortcutsタブ

**アプリケーション:**
- 「+」をクリックして新しいアプリを追加
- 起動中のアプリケーションから選択（Bundle IDを自動検出）
- または手動でBundle IDを入力
- 修飾キーを追加: ⇧ Shift、⌘ Command、⌥ Option、⌃ Control

**ウィンドウ管理:**
- 矢印キーのレイアウトをカスタマイズ
- 高度なレイアウト用の修飾キー組み合わせを追加

**システムアクション:**
- システムショートカット（リロード、コンソール、デバッグモード等）を設定

#### Backupタブ

- 設定のバックアップを作成
- 以前のバックアップから復元
- 設定のエクスポート/インポート

### 機能

- ✅ ビジュアルなキー検出（キーコードを調べる必要なし）
- ✅ 起動中のアプリから自動的にアプリ情報を入力
- ✅ 修飾キーのサポート（✧ + ⇧ + A、✧ + ⌘ + C等）
- ✅ キー組み合わせの重複チェック
- ✅ 設定の保存（要configPath設定）

## 方法2: JSON設定ファイル

手動編集やバージョン管理を好むユーザー向け。

### 場所

**デフォルト（読み取り専用）**: Spoon内のテンプレートファイル
- 設定の参照のみ可能
- 設定を保存するには、下記のようにconfigPathを設定する必要があります

**カスタム場所（設定可能）**: `init.lua`で設定
```lua
spoon.HyperkeyHub.configPath = os.getenv("HOME") .. "/.hammerspoon/HyperkeyHub/config.json"
```

または:
```lua
-- Dropboxを使う場合
spoon.HyperkeyHub.configPath = os.getenv("HOME") .. "/Dropbox/HyperkeyHub/config.json"

-- iCloud Driveを使う場合
spoon.HyperkeyHub.configPath = os.getenv("HOME") .. "/Library/Mobile Documents/com~apple~CloudDocs/HyperkeyHub/config.json"
```

### JSON構造

```json
{
  "schema_version": 1,
  "hyperKeyCode": 80,
  "hyperKeyName": "F19",
  "applications": {
    "safari": {
      "key": "s",
      "bundle": "com.apple.Safari",
      "name": "Safari",
      "modifiers": []
    },
    "terminal": {
      "key": "t",
      "bundle": "com.apple.Terminal",
      "name": "ターミナル",
      "modifiers": ["shift"]
    }
  },
  "window_management": {
    "left": {
      "key": "left",
      "modifiers": []
    },
    "right": {
      "key": "right",
      "modifiers": []
    }
  },
  "system_shortcuts": {
    "reload": {
      "key": "r",
      "modifiers": ["shift"]
    }
  },
  "script_shortcuts": {
    "my_script": {
      "name": "マイスクリプト",
      "key": "1",
      "modifiers": [],
      "type": "shell",
      "script_path": "~/scripts/my_script.sh"
    },
    "notification": {
      "name": "通知",
      "key": "2",
      "modifiers": [],
      "type": "applescript",
      "script_inline": "display notification \"Hello\" with title \"Test\""
    }
  },
  "window_animation_duration": 0.2
}
```

### Bundle IDの確認方法

**コマンドラインから:**
```bash
osascript -e 'tell application "System Events" to get bundle identifier of application process "アプリ名"'
```

**例:**
```bash
osascript -e 'tell application "System Events" to get bundle identifier of application process "Safari"'
# 出力: com.apple.Safari
```

**よく使うアプリケーション:**
- Safari: `com.apple.Safari`
- Finder: `com.apple.finder`
- ターミナル: `com.apple.Terminal`
- VSCode: `com.microsoft.VSCode`
- Chrome: `com.google.Chrome`

### Hyperキーコード一覧

| キー | コード |
|-----|------|
| F15 | 76 |
| F16 | 77 |
| F17 | 78 |
| F18 | 79 |
| F19 | 80（デフォルト）|

### 修飾キー

`modifiers`配列でサポートされる値:
- `"shift"` - ⇧ Shift
- `"cmd"` - ⌘ Command
- `"alt"` - ⌥ Option（Alt）
- `"ctrl"` - ⌃ Control

**組み合わせ例:**
```json
{
  "myapp": {
    "key": "a",
    "modifiers": ["shift"],        // Hyper + Shift + A
    "bundle": "com.example.MyApp",
    "name": "マイアプリ"
  },
  "otherapp": {
    "key": "b",
    "modifiers": ["cmd", "shift"], // Hyper + Cmd + Shift + B
    "bundle": "com.example.OtherApp",
    "name": "その他のアプリ"
  }
}
```

## 方法3: コードベース設定

カスタム関数や動的な設定が必要な上級ユーザー向け。

### 基本設定

`~/.hammerspoon/init.lua`内：

```lua
hs.loadSpoon("HyperkeyHub")

spoon.HyperkeyHub:configure({
    hyperKeyCode = 79,  -- F18
    applications = {
        safari = {
            key = "s",
            bundle = "com.apple.Safari",
            name = "Safari"
        }
    }
})

spoon.HyperkeyHub:start()
```

### カスタムアクションの追加

```lua
hs.loadSpoon("HyperkeyHub")

spoon.HyperkeyHub:configure({
    system = {
        screenshot = {
            key = "s",
            action = function()
                hs.eventtap.keyStroke({"cmd", "shift"}, "4")
            end,
            name = "スクリーンショット"
        },
        toggleWifi = {
            key = "w",
            action = function()
                hs.wifi.setPower(not hs.wifi.interfaceDetails().power)
            end,
            name = "WiFi切り替え"
        }
    }
})

spoon.HyperkeyHub:start()
```

### 動的な設定

```lua
local config = {
    hyperKeyCode = 80,
    applications = {}
}

-- アプリを動的に追加
local apps = {"Safari", "Chrome", "Terminal"}
local keys = {"s", "c", "t"}

for i, appName in ipairs(apps) do
    config.applications[appName:lower()] = {
        key = keys[i],
        bundle = "com.apple." .. appName,
        name = appName
    }
end

spoon.HyperkeyHub:configure(config)
spoon.HyperkeyHub:start()
```

### 実行時の設定変更

```lua
-- 起動後に新しいアクションを追加
spoon.HyperkeyHub.config.system.newAction = {
    key = "n",
    action = function()
        hs.alert.show("新しいアクション")
    end,
    name = "新しいアクション"
}
```

## スクリプトショートカットの設定

任意のシェルスクリプトやAppleScriptをショートカットキーから実行できます。

### 基本構造

```json
{
  "script_shortcuts": {
    "ショートカットID": {
      "name": "表示名",
      "key": "キー",
      "modifiers": ["修飾キー配列"],
      "type": "shell または applescript",
      "script_path": "スクリプトファイルパス（オプション）",
      "script_inline": "インラインスクリプト（オプション）"
    }
  }
}
```

### フィールド説明

| フィールド | 必須 | 説明 | 例 |
|----------|------|------|-----|
| `name` | はい | ログやエラー表示に使用される名前 | `"マイスクリプト"` |
| `key` | はい | トリガーキー | `"1"`, `"a"`, `"space"` |
| `modifiers` | いいえ | 修飾キー配列 | `[]`, `["shift"]`, `["cmd", "alt"]` |
| `type` | いいえ | スクリプトタイプ（デフォルト: `"shell"`） | `"shell"`, `"applescript"` |
| `script_path` | 条件付き | スクリプトファイルへのパス | `"~/scripts/test.sh"` |
| `script_inline` | 条件付き | インラインスクリプトコード | `"echo 'Hello'"` |

**注意:** `script_path` または `script_inline` のどちらか一方は必須です。

### シェルスクリプトの例

#### ファイルから実行

```json
{
  "script_shortcuts": {
    "backup": {
      "name": "バックアップ実行",
      "key": "b",
      "modifiers": ["shift"],
      "type": "shell",
      "script_path": "~/scripts/backup.sh"
    }
  }
}
```

実行されるコマンド: `/bin/bash ~/scripts/backup.sh`

#### インラインスクリプト

```json
{
  "script_shortcuts": {
    "hello": {
      "name": "Hello World",
      "key": "h",
      "modifiers": [],
      "type": "shell",
      "script_inline": "echo 'Hello World' && osascript -e 'display notification \"Hello\" with title \"Test\"'"
    }
  }
}
```

### AppleScriptの例

#### ファイルから実行

```json
{
  "script_shortcuts": {
    "notify": {
      "name": "カスタム通知",
      "key": "n",
      "modifiers": [],
      "type": "applescript",
      "script_path": "~/scripts/notify.scpt"
    }
  }
}
```

実行されるコマンド: `osascript ~/scripts/notify.scpt`

#### インラインスクリプト

```json
{
  "script_shortcuts": {
    "alert": {
      "name": "アラート表示",
      "key": "a",
      "modifiers": ["alt"],
      "type": "applescript",
      "script_inline": "display notification \"作業完了しました\" with title \"HyperkeyHub\""
    }
  }
}
```

### 複雑な例

#### システム情報の通知

```json
{
  "script_shortcuts": {
    "system_info": {
      "name": "システム情報",
      "key": "i",
      "modifiers": ["cmd"],
      "type": "shell",
      "script_inline": "battery=$(pmset -g batt | grep -Eo '\\d+%' | head -1) && osascript -e \"display notification \\\"バッテリー: $battery\\\" with title \\\"システム情報\\\"\""
    }
  }
}
```

#### 音量調整

```json
{
  "script_shortcuts": {
    "mute": {
      "name": "ミュート切り替え",
      "key": "m",
      "modifiers": [],
      "type": "applescript",
      "script_inline": "set volume output muted (not (output muted of (get volume settings)))"
    }
  }
}
```

#### アプリケーションの起動（AppleScriptファイル）

```json
{
  "script_shortcuts": {
    "start_day": {
      "name": "朝のアプリ起動",
      "key": "d",
      "modifiers": ["shift"],
      "type": "applescript",
      "script_path": "~/scripts/start_day.scpt"
    }
  }
}
```

### パスの展開

スクリプトファイルのパスでは、以下の形式がサポートされています：

#### 絶対パス
`/` で始まるパスはそのまま使用されます：
- `/usr/local/bin/myscript.sh`

#### チルダ (`~`)
ホームディレクトリに展開されます：
- `~/scripts/test.sh` → `/Users/username/scripts/test.sh`

#### 相対パス
`/` や `~` で始まらないパスは、HyperkeyHub Spoonのリソースディレクトリからの相対パスとして扱われます：
- `resources/examples/test.sh` → `~/.hammerspoon/Spoons/HyperkeyHub.spoon/resources/examples/test.sh`

Spoon内のサンプルスクリプトを使う場合に便利です。

### エラーハンドリング

- スクリプトファイルが見つからない場合、エラーアラートが表示されます
- スクリプト実行が失敗した場合、終了コードとともにログに記録されます
- エラーは Hammerspoon コンソールで確認できます（✧ + Shift + R）

### デバッグ

スクリプトの実行状況を確認するには：

1. Hammerspoonコンソールを開く（✧ + Shift + R、またはメニューバーから）
2. ログレベルをデバッグに設定:
   ```lua
   spoon.HyperkeyHub.logLevel = "debug"
   ```
3. スクリプトを実行してログを確認

## ウィンドウ管理のカスタマイズ

ウィンドウ管理のレイアウトは、どの設定方法でもカスタマイズできます。

### 利用可能なレイアウト

**基本レイアウト:**
- `left`: 左半分
- `right`: 右半分
- `up`: 上半分
- `down`: 下半分
- `m`: 最大化

**3分割レイアウト（Shift併用）:**
- `left` + Shift: 左3分の1
- `right` + Shift: 右3分の1
- `c` + Shift: 中央3分の1

**2/3レイアウト（Shift併用）:**
- `up` + Shift: 左3分の2
- `down` + Shift: 右3分の2

**4分割レイアウト（Cmd併用）:**
- `u` + Cmd: 左上4分の1
- `i` + Cmd: 右上4分の1
- `j` + Cmd: 左下4分の1
- `k` + Cmd: 右下4分の1

### カスタムウィンドウレイアウト

```lua
spoon.HyperkeyHub:configure({
    window_management = {
        custom = {
            key = "c",
            modifiers = {"cmd"},
            action = function()
                local win = hs.window.focusedWindow()
                local frame = win:screen():frame()
                win:setFrame({
                    x = frame.x + frame.w * 0.25,
                    y = frame.y + frame.h * 0.25,
                    w = frame.w * 0.5,
                    h = frame.h * 0.5
                })
            end,
            name = "中央50%"
        }
    }
})
```

## 設定ファイルの場所

### デフォルトの場所

`~/.hammerspoon/HyperkeyHub/config.json`

### カスタムの場所

`:start()`を呼び出す前に設定：

```lua
hs.loadSpoon("HyperkeyHub")

-- Dropbox
spoon.HyperkeyHub.configPath = os.getenv("HOME") .. "/Dropbox/HyperkeyHub/config.json"

-- iCloud Drive
-- spoon.HyperkeyHub.configPath = os.getenv("HOME") .. "/Library/Mobile Documents/com~apple~CloudDocs/HyperkeyHub/config.json"

spoon.HyperkeyHub:start()
```

**注意:** 設定ファイルは自動的に移行されません。設定を保持する場合は、手動でファイルをコピーする必要があります。

## バックアップと復元

### GUIを使用

1. 設定を開く（✧ → Settings）
2. 「Backup」タブに移動
3. 「バックアップ作成」をクリックして現在の設定を保存
4. 「復元」を使用して以前のバックアップを読み込む

### 手動バックアップ

```bash
# バックアップ作成
cp ~/.hammerspoon/HyperkeyHub/config.json ~/.hammerspoon/HyperkeyHub/config.json.backup

# バックアップから復元
cp ~/.hammerspoon/HyperkeyHub/config.json.backup ~/.hammerspoon/HyperkeyHub/config.json
```

## 次のステップ

- [使い方ガイド](usage.ja.md) - キーバインドと機能について学ぶ
- [トラブルシューティング](troubleshooting.ja.md) - 設定の問題を解決
- [開発ガイド](development.ja.md) - HyperkeyHubに貢献
