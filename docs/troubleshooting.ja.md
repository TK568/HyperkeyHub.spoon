# トラブルシューティングガイド

HyperkeyHubのよくある問題と解決方法です。

## インストールの問題

### Hammerspoonが起動しない

**症状:**
- メニューバーにHammerspoonアイコンがない
- 設定のリロードが何も起こらない

**解決方法:**

1. **Hammerspoonが実行中か確認:**
   ```bash
   ps aux | grep Hammerspoon
   ```

2. **手動でHammerspoonを起動:**
   - アプリケーションフォルダを開く
   - Hammerspoon.appをダブルクリック

3. **コンソールでエラーを確認:**
   - Hammerspoonアイコン → Console
   - エラーメッセージを確認

4. **インストールを確認:**
   ```bash
   ls -la ~/.hammerspoon/Spoons/HyperkeyHub.spoon
   ```

### HyperkeyHubが読み込まれない

**症状:**
- メニューバーに✧アイコンがない
- Hyperキーが動作しない

**解決方法:**

1. **init.luaの文法を確認:**
   ```bash
   # Hammerspoonコンソールで
   hs.reload()
   # 文法エラーを確認
   ```

2. **Spoonのパスを確認:**
   ```lua
   -- Hammerspoonコンソールで
   hs.spoons.list()
   -- "HyperkeyHub"が表示されるはず
   ```

3. **読み込みコードを確認:**
   ```lua
   -- ~/.hammerspoon/init.luaに以下があることを確認
   hs.loadSpoon("HyperkeyHub")
   spoon.HyperkeyHub:start()
   ```

4. **タイポをチェック:**
   - 正しい大文字小文字: `HyperkeyHub`（`hyperkeycommander`ではない）
   - 正しいメソッド: `:start()`（`.start()`ではない）

## Hyperキーの問題

### Hyperキーが反応しない

**症状:**
- F19（または設定したキー）を押しても何も起こらない
- Hyperキーのショートカットが全て動作しない

**解決方法:**

1. **設定でキーコードを確認:**
   - `Hyper + ,`を押す（動作する場合）または手動で設定を開く
   - 正しいキーが設定されているか確認
   - 「キー検出」を試して意図したHyperキーを押す

2. **キーの競合をチェック:**
   ```bash
   # すべてのキーボードショートカットを一覧表示
   defaults read com.apple.symbolichotkeys
   ```
   - 他のアプリが同じキーを使用している可能性
   - 別のキー（F18、F17等）を試す

3. **別のキーでテスト:**
   - 設定を開く
   - F18またはF17に変更
   - 保存してリロード

4. **Hammerspoonを再起動:**
   ```bash
   # 終了して再起動
   killall Hammerspoon
   open -a Hammerspoon
   ```

5. **Karabiner-Elementsをチェック:**
   - Karabiner-Elementsを使用してキーをリマップしている場合
   - リマップがアクティブか確認
   - Karabiner-ElementsのEventViewerでキー押下が検出されるか確認

### Hyperキーが部分的に動作

**症状:**
- 一部のショートカットは動作するが、他は動作しない
- 動作が一貫しない

**解決方法:**

1. **重複したバインディングをチェック:**
   - 設定 → Shortcutsタブを開く
   - 重複したキー組み合わせを探す
   - 競合を削除または再割り当て

2. **修飾キーを確認:**
   - 修飾キー（Shift、Cmd、Alt、Ctrl）が正しく設定されているか確認
   - まず修飾キーなしでテスト

3. **デバッグモードを有効化:**
   ```lua
   -- Hyper + Shift + Dでデバッグモードを切り替え
   -- コンソールでエラーを確認
   ```

## アプリケーションランチャーの問題

### アプリが起動しない

**症状:**
- アプリのショートカットを押しても何も起こらない
- アプリが表示されない

**解決方法:**

1. **Bundle IDを確認:**
   ```bash
   osascript -e 'tell application "System Events" to get bundle identifier of application process "アプリ名"'
   ```
   - 設定されたBundle IDと比較
   - 異なる場合は設定で更新

2. **アプリがインストールされているか確認:**
   ```bash
   mdfind "kMDItemKind == 'Application'" | grep -i "アプリ名"
   ```

3. **手動で起動を試す:**
   ```lua
   -- Hammerspoonコンソールで
   hs.application.open("com.apple.Safari")
   ```

4. **アクセシビリティ権限を確認:**
   - システム環境設定 → セキュリティとプライバシー → プライバシー
   - 左側で「アクセシビリティ」を選択
   - Hammerspoonにチェックが入っているか確認

### アプリが非表示にならない

**症状:**
- アプリは起動するが、もう一度押しても非表示にならない
- トグル動作が機能しない

**解決方法:**

1. **アクセシビリティ権限を付与:**
   - システム環境設定 → セキュリティとプライバシー → プライバシー → アクセシビリティ
   - Hammerspoonがチェックされ、有効になっているか確認
   - すでにチェックされている場合:
     - チェックを外す → 再度チェック
     - またはHammerspoonを削除 → 再追加

2. **Electron製アプリ:**
   - HyperkeyHubには組み込みのElectron製アプリサポートがあります
   - 一部のアプリは特別な処理が必要な場合があります
   - コンソールで警告を確認

3. **代替非表示方法を試す:**
   ```lua
   -- Hammerspoonコンソールで
   local app = hs.application.find("com.apple.Safari")
   app:hide()
   ```

4. **アプリを再起動:**
   - 問題のあるアプリを完全に終了
   - HyperkeyHubで再度起動を試す

### 別のアプリが開く

**症状:**
- 意図したアプリとは異なるアプリが開く
- Bundle IDの不一致

**解決方法:**

1. **正しいBundle IDを確認:**
   ```bash
   # 起動中のアプリからBundle IDを取得
   osascript -e 'tell application "System Events" to get bundle identifier of application process "Safari"'
   ```

2. **設定を更新:**
   - 設定を開く
   - アプリエントリを編集
   - Bundle IDを更新
   - 保存してリロード

3. **複数バージョンをチェック:**
   ```bash
   # アプリの全バージョンを検索
   mdfind "kMDItemKind == 'Application' && kMDItemDisplayName == 'Safari'"
   ```
   - 複数バージョンがインストールされている可能性
   - 使用したいバージョンの正確なBundle IDを指定

## ウィンドウ管理の問題

### ウィンドウ管理が動作しない

**症状:**
- 矢印キーのショートカットがウィンドウを動かさない
- ウィンドウがリサイズされない

**解決方法:**

1. **ショートカットの競合をチェック:**
   - システム環境設定 → キーボード → ショートカット
   - Mission Control、アプリのショートカットとの競合を探す
   - 競合するショートカットを無効化

2. **フォーカスされたウィンドウでテスト:**
   - ショートカットを使う前にウィンドウがフォーカスされているか確認
   - ウィンドウをクリックしてフォーカス
   - もう一度ショートカットを試す

3. **フルスクリーンではないことを確認:**
   - macOSのフルスクリーンモードではウィンドウ管理が動作しません
   - フルスクリーンを終了（ESCまたは緑のウィンドウボタン）

4. **別のアプリでテスト:**
   - 一部のアプリはウィンドウ管理が制限されています
   - まずSafariまたはFinderで試す

### ウィンドウアニメーションが遅い

**症状:**
- ウィンドウの移動が遅いまたはカクつく
- 応答が遅い

**解決方法:**

1. **アニメーション時間を短縮:**
   ```lua
   -- init.luaまたは設定で
   spoon.HyperkeyHub:configure({
       window_animation_duration = 0.1  -- デフォルトは0.2
   })
   ```

2. **アニメーションを無効化:**
   ```lua
   spoon.HyperkeyHub:configure({
       window_animation_duration = 0
   })
   ```

3. **システムパフォーマンスを確認:**
   - リソース集約型のアプリを閉じる
   - アクティビティモニタでCPU/メモリ使用量を確認

### ウィンドウが正しい位置に配置されない

**症状:**
- ウィンドウが意図した位置に移動しない
- サイズが正しくない

**解決方法:**

1. **複数モニターをチェック:**
   - ウィンドウが別のスクリーンに移動している可能性
   - フォーカスされたウィンドウが意図したスクリーンにあることを確認

2. **画面解像度を確認:**
   - 一部のレイアウトは特定の解像度で予期しない動作をする可能性
   - まず基本レイアウト（左、右、最大化）を試す

3. **ウィンドウ位置をリセット:**
   - 手動でウィンドウをおおよその位置に移動
   - レイアウトショートカットを再度試す

## 設定の問題

### 設定が保存されない

**症状:**
- 設定GUIでの変更が保持されない
- リロード後に設定が元に戻る

**解決方法:**

1. **ファイル権限を確認:**
   ```bash
   ls -la ~/.hammerspoon/HyperkeyHub/config.json
   chmod 644 ~/.hammerspoon/HyperkeyHub/config.json
   ```

2. **設定パスを確認:**
   ```lua
   -- Hammerspoonコンソールで
   print(spoon.HyperkeyHub.configPath)
   ```

3. **JSON文法エラーをチェック:**
   ```bash
   # JSONを検証
   cat ~/.hammerspoon/HyperkeyHub/config.json | python -m json.tool
   ```

4. **バックアップして再作成:**
   ```bash
   mv ~/.hammerspoon/HyperkeyHub/config.json ~/.hammerspoon/HyperkeyHub/config.json.backup
   # 設定を開いて再設定
   ```

### 設定の競合

**症状:**
- 設定がJSONファイルと一致しない
- コードベースの設定が無視される

**解決方法:**

1. **優先順位を理解:**
   - デフォルト < JSON < コードベース（`:configure()`）
   - コードベースの設定がJSONを上書きします

2. **複数の設定を確認:**
   - init.lua内の複数の`:configure()`呼び出しを検索
   - 設定を削除または統合

3. **クリーンスタート:**
   ```bash
   # 現在の設定をバックアップ
   cp ~/.hammerspoon/HyperkeyHub/config.json ~/Desktop/backup.json

   # 設定を削除
   rm -r ~/.hammerspoon/HyperkeyHub

   # init.luaからコードベースの設定を削除
   # リロードしてGUIから再設定
   ```

### 設定が保存できない（デフォルト設定使用時）

**症状:**
- 設定画面で変更を保存しようとすると「Configuration Path Not Set」エラーが表示される
- デフォルト設定のまま使用している

**原因:**
- デフォルト設定（リポジトリ内のテンプレートファイル）は読み取り専用です
- 設定を保存するには、カスタムconfigPathの設定が必要です

**解決方法:**

1. **設定ファイルを作成:**
   ```bash
   mkdir -p ~/.hammerspoon/HyperkeyHub
   cp ~/.hammerspoon/Spoons/HyperkeyHub.spoon/resources/config_templates/default_config.json \
      ~/.hammerspoon/HyperkeyHub/config.json
   ```

2. **`init.lua`にconfigPathを追加:**
   ```lua
   hs.loadSpoon("HyperkeyHub")
   spoon.HyperkeyHub.configPath = os.getenv("HOME") .. "/.hammerspoon/HyperkeyHub/config.json"
   spoon.HyperkeyHub:start()
   ```

3. **Hammerspoonをリロード**

これで設定の保存が可能になります。

### カスタム設定パスが機能しない

**症状:**
- カスタムパスの設定ファイルが読み込まれない
- 変更が保存されない

**注意:** このセクションは、カスタムconfigPathを設定済みで問題が発生している場合のトラブルシューティングです。設定を保存したい場合は、上記の「設定が保存できない」を参照してください。

**解決方法:**

1. **`:start()`の前にパスを設定していることを確認:**
   ```lua
   hs.loadSpoon("HyperkeyHub")
   spoon.HyperkeyHub.configPath = "/your/custom/path.json"
   spoon.HyperkeyHub:start()  -- パス設定の後でなければなりません
   ```

2. **パスが存在することを確認:**
   ```bash
   ls -la /your/custom/path.json
   ```

3. **書き込み権限を確認:**
   ```bash
   touch /your/custom/path.json
   ```

4. **絶対パスを使用:**
   ```lua
   -- 良い例
   spoon.HyperkeyHub.configPath = os.getenv("HOME") .. "/Dropbox/config.json"

   -- 悪い例（相対パス）
   spoon.HyperkeyHub.configPath = "~/Dropbox/config.json"
   ```

## パフォーマンスの問題

### 高CPU使用率

**症状:**
- Hammerspoonが過度にCPUを使用
- システムの速度低下

**解決方法:**

1. **デバッグモードを無効化:**
   ```lua
   -- Hyper + Shift + Dを押してOFFに切り替え
   ```

2. **無限ループを確認:**
   - コードベースの設定でカスタムアクションを確認
   - 再帰的にトリガーされるイベントハンドラを探す

3. **Hammerspoonを再起動:**
   ```bash
   killall Hammerspoon && open -a Hammerspoon
   ```

### メモリリーク

**症状:**
- Hammerspoonのメモリ使用量が時間とともに増加
- システムが重くなる

**解決方法:**

1. **Hammerspoonを再起動:**
   - クイック修正: 設定をリロード（Hyper + Shift + R）
   - 完全再起動: 終了して再起動

2. **イベントのリークを確認:**
   - クリーンアップされていないイベントリスナーがないかカスタムコードを確認
   - コンソールで警告を確認

3. **最新バージョンに更新:**
   - HyperkeyHubの更新を確認
   - Hammerspoon自体を更新

## デバッグのヒント

### デバッグログを有効化

```lua
-- Hyper + Shift + Dを押す
-- またはコードで:
spoon.HyperkeyHub.logger:setLogLevel("debug")
```

### コンソール出力を確認

```lua
-- Hyper + Shift + Hを押す
-- またはHammerspoonアイコン → Console
```

### 個別コンポーネントをテスト

```lua
-- Hammerspoonコンソールで

-- アプリ起動をテスト
hs.application.open("com.apple.Safari")

-- ウィンドウ管理をテスト
local win = hs.window.focusedWindow()
local frame = win:frame()
print(hs.inspect(frame))

-- キー検出をテスト
local eventtap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(e)
    print("Key code:", e:getKeyCode())
end)
eventtap:start()
```

### EventBusを確認

```lua
-- Hammerspoonコンソールで
-- すべてのイベントを購読
spoon.HyperkeyHub.eventBus:on("*", function(event, ...)
    print("Event:", event, ...)
end)
```

## ヘルプを得る

問題が解決しない場合：

1. **既存のissueを確認:**
   - [GitHub Issues](https://github.com/TK568/HyperkeyHub.spoon/issues)

2. **情報を収集:**
   - Hammerspoonのバージョン: Aboutメニューを確認
   - macOSのバージョン: システム環境設定 → このMacについて
   - HyperkeyHubのバージョン: Spoonのメタデータを確認
   - コンソールからのエラーメッセージ

3. **issueを作成:**
   - 収集した情報をすべて含める
   - 再現手順を説明
   - 関連する設定を添付（機密データは削除）

4. **コミュニティサポート:**
   - Hammerspoon Discord/フォーラム
   - Stack Overflow（タグ: hammerspoon）

## 次のステップ

- [使い方ガイド](usage.ja.md) - 全機能を学ぶ
- [設定ガイド](configuration.ja.md) - 高度なカスタマイズ
- [開発ガイド](development.ja.md) - 修正を貢献
