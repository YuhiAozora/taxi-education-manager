# GitHubへのアップロード手順

## 現在の状況
- リポジトリURL: https://github.com/YuhiAozora/taxi-education-manager
- ローカルコミット: 完了
- 問題: アクセストークンの権限不足でプッシュできません

## 解決方法

### オプション1: GitHub Desktop を使用
1. [GitHub Desktop](https://desktop.github.com/) をダウンロード
2. GitHubアカウントでサインイン
3. File → Add Local Repository → `/path/to/flutter_app` を選択
4. Publish repository をクリック

### オプション2: コマンドラインで手動プッシュ
1. GitHubで新しいPersonal Access Tokenを生成:
   - https://github.com/settings/tokens
   - "Generate new token (classic)" をクリック
   - 権限: `repo` (Full control) にチェック
   - トークンをコピー

2. ターミナルで実行:
```bash
cd /path/to/flutter_app
git remote set-url origin https://YOUR_TOKEN@github.com/YuhiAozora/taxi-education-manager.git
git push -u origin main
```

### オプション3: ZIP ファイルから手動アップロード
1. プロジェクトのZIPファイルをダウンロード:
   https://5060-itq4ix88g0pl29qsn5wtr-18e660f9.sandbox.novita.ai/taxi-education-manager.tar.gz

2. 解凍してGitHubリポジトリにドラッグ&ドロップ

## コミット内容
- 診断管理機能の追加
- ログイン時通知機能
- CSV出力機能
- サンプルデータ
