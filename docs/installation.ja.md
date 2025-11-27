# インストールガイド

HyperkeyHub.spoonのインストール方法について説明いたします。

## 前提条件

- macOS
- [Hammerspoon](https://www.hammerspoon.org/) 0.9.97以降

Hammerspoonがインストールされていない場合は、以下のコマンドでインストールしてください：

```bash
brew install --cask hammerspoon
```

インストール後、アプリケーションフォルダから起動してください。

## インストール方法

### 方法1: 手動インストール（一般ユーザー向け）

1. [最新版をダウンロード](https://github.com/TK568/HyperkeyHub.spoon/releases)
2. `HyperkeyHub.spoon.zip`を解凍
3. `HyperkeyHub.spoon`をダブルクリック
4. Hammerspoonが自動的にインストール

### 方法2: Gitクローン（開発者向け）

```bash
cd ~/.hammerspoon/Spoons
git clone https://github.com/TK568/HyperkeyHub.spoon.git
```

この方法のメリット：
- `git pull`で簡単に更新可能
- プロジェクトへの貢献が容易
- 開発版のテストが可能

## 基本セットアップ

HyperkeyHubは設定ファイルなしですぐに使い始めることができます。

### 1. init.luaに追加

`~/.hammerspoon/init.lua`に以下の2行を追加してください：

```lua
hs.loadSpoon("HyperkeyHub")
spoon.HyperkeyHub:start()
```

これだけで、デフォルト設定で起動します。

## 設定ファイルのセットアップ（オプション）

設定をカスタマイズして保存したい場合は、設定ファイルを配置してください。

### 1. 設定ファイルの作成

標準的な場所（`~/.hammerspoon/HyperkeyHub/config.json`）に配置する場合：

```bash
mkdir -p ~/.hammerspoon/HyperkeyHub
cp ~/.hammerspoon/Spoons/HyperkeyHub.spoon/resources/config_templates/default_config.json \
   ~/.hammerspoon/HyperkeyHub/config.json
```

### 2. init.luaでパスを指定

`:start()`を呼び出す前に`configPath`プロパティを設定してください：

```lua
hs.loadSpoon("HyperkeyHub")

-- 標準的な場所を使用する場合
spoon.HyperkeyHub.configPath = os.getenv("HOME") .. "/.hammerspoon/HyperkeyHub/config.json"

-- Dropboxを使う場合:
-- spoon.HyperkeyHub.configPath = os.getenv("HOME") .. "/Dropbox/HyperkeyHub/config.json"

-- iCloud Driveを使う場合:
-- spoon.HyperkeyHub.configPath = os.getenv("HOME") .. "/Library/Mobile Documents/com~apple~CloudDocs/HyperkeyHub/config.json"

spoon.HyperkeyHub:start()
```

**ポイント:**
- `configPath`を設定しない場合は、デフォルト設定（読み取り専用）で起動します
- 設定を変更して保存したい場合のみ、`configPath`の設定が必要です
- カスタムパスを使用する場合は、そのパスに設定ファイルをコピーしてください

## インストールの確認

インストール後：

1. `~/.hammerspoon/init.lua`に以下を追加：
   ```lua
   hs.loadSpoon("HyperkeyHub")
   spoon.HyperkeyHub:start()
   ```

2. Hammerspoonをリロード：メニューバーのアイコンをクリック → "Reload Config"

3. メニューバーに✧アイコンが表示されることを確認

4. `F19 + F`でFinderが起動/フォーカスすることを確認

✧アイコンが表示され、キーバインドが動作すればインストール成功です！

## アンインストール

HyperkeyHubを削除するには：

1. `~/.hammerspoon/init.lua`から読み込み行を削除
2. Spoonディレクトリを削除：
   ```bash
   rm -rf ~/.hammerspoon/Spoons/HyperkeyHub.spoon
   ```
3. （オプション）設定ファイルも削除：
   ```bash
   rm -r ~/.hammerspoon/HyperkeyHub
   ```
4. Hammerspoonをリロード

## 次のステップ

- [使い方ガイド](usage.ja.md) - HyperkeyHubの使い方を学ぶ
- [設定ガイド](configuration.ja.md) - セットアップをカスタマイズ
- [トラブルシューティング](troubleshooting.ja.md) - よくある問題を解決
