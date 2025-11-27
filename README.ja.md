# HyperkeyHub.spoon

Hyperキーをベースにしたアプリランチャー & ウィンドウ管理コマンダー

[English](README.md)

## クイックスタート

3分程度で利用を開始できます：

1. **Hammerspoonのインストール**: `brew install --cask hammerspoon`（その後、アプリケーションから起動してください）
2. **Spoonのインストール**: [インストールガイド](docs/installation.ja.md)をご参照ください
3. **設定ファイルの編集**: `~/.hammerspoon/init.lua`に以下の2行を追加してください：
   ```lua
   hs.loadSpoon("HyperkeyHub")
   spoon.HyperkeyHub:start()
   ```
4. **設定の読み込み**: メニューバーのHammerspoonアイコンから"Reload Config"を選択してください
5. **確認**: `F19 + F`でFinderが起動/フォーカスされることを確認してください

**設定のカスタマイズ**: `F19 + ,`で設定画面を開き、アプリケーションやショートカットを自由に変更できます。

**詳細な設定**: 設定を保存するには、Dropboxやローカルに設定ファイルを配置してください。詳細は[設定ガイド](docs/configuration.ja.md)をご参照ください。

**Hyperキーについて**: F19キーが利用できない場合は、[Karabiner-Elements](https://karabiner-elements.pqrs.org/)を使用してCaps Lock → F19へのリマップを推奨します。

## 機能

- **アプリケーションランチャー**: Hyperキー + キーでアプリを起動/フォーカス/非表示
- **ウィンドウ管理**: Hyperキー + 矢印キーでウィンドウ配置を変更
- **スクリプトショートカット**: Shell、AppleScript、Luaスクリプトを引数付きで実行
- **Electron製アプリ対応**: 標準の`hide()`が動作しないアプリを自動的に処理
- **カスタマイズ可能**: GUI、JSON、コードで自由に設定
- **ウィンドウ位置記憶**: ウィンドウレイアウトの保存・復元
- **マルチモニター対応**: 複数ディスプレイでシームレスに動作

## 必要要件

- macOS
- [Hammerspoon](https://www.hammerspoon.org/) 0.9.97以降

## ドキュメント

### ユーザーガイド
- [インストールガイド](docs/installation.ja.md) - HyperkeyHubのインストール
- [使い方ガイド](docs/usage.ja.md) - 全機能とキーバインド
- [設定ガイド](docs/configuration.ja.md) - カスタマイズ方法（GUI/JSON/コード）
- [トラブルシューティング](docs/troubleshooting.ja.md) - よくある問題の解決

### 開発者ガイド
- [開発ガイド](docs/development.ja.md) - プロジェクトへの貢献
- [アーキテクチャ概要](docs/development.ja.md#アーキテクチャ) - コードベースの理解
- [テスト実行](docs/development.ja.md#テストの実行) - テストフレームワークガイド

## クイックリファレンス

### デフォルトのキーバインディング

**アプリケーション**（カスタマイズ可能）:
- `Hyper + F`: Finder
- `Hyper + S`: Safari
- `Hyper + T`: ターミナル

**ウィンドウ管理**:
- `Hyper + ←/→/↑/↓`: 半分レイアウト（左/右/上/下）
- `Hyper + M`: 最大化
- `Hyper + Shift + ←/→/↑/↓`: 3分割と2/3分割
- `Hyper + Cmd + U/I/J/K`: 4分割

**システム**:
- `Hyper + ,`: 設定
- `Hyper + Shift + R`: 設定リロード
- `Hyper + Shift + H`: Hammerspoonコンソール

完全なリストは[使い方ガイド](docs/usage.ja.md)をご参照ください。

## 設定方法

用途に応じて適切な方法を選択してください：

| 方法 | 最適なユーザー | ガイド |
|------|-------------|-------|
| **GUI設定** | ほとんどのユーザー | [設定ガイド](docs/configuration.ja.md#方法1-gui設定推奨) |
| **JSONファイル** | パワーユーザー | [設定ガイド](docs/configuration.ja.md#方法2-json設定ファイル) |
| **コードベース** | 開発者 | [設定ガイド](docs/configuration.ja.md#方法3-コードベース設定) |

## 設計について

### なぜ `bindHotkeys()` メソッドがないのか？

従来のHammerspoon Spoonは`bindHotkeys()`でホットキーを設定しますが、HyperkeyHubは設定ファイル（`~/.hammerspoon/HyperkeyHub/config.json`）とSettings UIですべてのキーバインドを管理します。

**この設計の理由：**

1. **Hyperキーアーキテクチャ**: HyperkeyHubはHyperキー（F19）を中心に設計されており、すべてのショートカットは`Hyper + キー`の組み合わせです。これは`bindHotkeys()`で使用される標準的な`{modifiers, key}`形式とは異なります。

2. **GUI優先アプローチ**: Settings UI（`Hyper + ,`）により、Luaコードを編集せずにすべてのショートカットを視覚的に設定できます。

3. **統一された設定**: すべての設定（アプリケーション、ウィンドウ管理、スクリプト）が単一のJSONファイルに保存され、バックアップ、同期、バージョン管理が容易です。

**コードベースの設定を好む場合**は、`:configure()`メソッドを使用してください：

```lua
hs.loadSpoon("HyperkeyHub")
spoon.HyperkeyHub:configure({
    applications = {
        vscode = { name = "Visual Studio Code", key = "v", bundle = "com.microsoft.VSCode" }
    }
}):start()
```

## 貢献

コントリビューションを歓迎いたします。[開発ガイド](docs/development.ja.md)をご参照ください：
- 開発環境のセットアップ
- テストの実行
- コードスタイルガイドライン
- プルリクエストプロセス

## ライセンス

MIT License - 詳細は[LICENSE](LICENSE)を参照

## クレジット

- Electron製アプリの非表示問題の解決策: [Hammerspoon Issue #3580](https://github.com/Hammerspoon/hammerspoon/issues/3580)
- モーダルキーアプローチ: [Evan Travers](https://evantravers.com/articles/2020/06/08/hammerspoon-a-better-better-hyper-key/)

## サポート

- [GitHub Issues](https://github.com/TK568/HyperkeyHub.spoon/issues) - バグ報告・機能リクエスト
- [ドキュメント](docs/) - 包括的なガイド
- [トラブルシューティング](docs/troubleshooting.ja.md) - よくある問題と解決策
