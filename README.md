# タクシー乗務員教育管理システム

運輸局監査対応の教育・診断管理システム

[![Flutter](https://img.shields.io/badge/Flutter-3.35.4-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.9.2-blue.svg)](https://dart.dev/)

## 📱 デモ

**プレビューURL**: https://5060-itq4ix88g0pl29qsn5wtr-18e660f9.sandbox.novita.ai

### デモアカウント

#### 👔 管理者
- 社員番号: `ADMIN`
- パスワード: `admin123`

#### 🚕 ドライバー（通知あり）
- 社員番号: `D001`
- パスワード: `password123`

#### 🚕 ドライバー（正常状態）
- 社員番号: `D002`
- パスワード: `password123`

---

## ✨ 主な機能

### 📚 教育管理
- ✅ 国土交通省教育マニュアル準拠（6項目）
- ✅ 学習記録の自動保存
- ✅ クイズ機能（理解度チェック）
- ✅ 学習履歴の閲覧
- ✅ カテゴリ別コンテンツ管理

### 🏥 診断管理
- ✅ 6種類の診断記録管理
  - 適齢診断（65歳以上）
  - 初任診断（新規採用）
  - 適性診断（全運転者）
  - 事故惹起運転者診断
  - 特定診断Ⅰ（65歳以上新規）
  - 特定診断Ⅱ（75歳以上）
- ✅ 期限切れの自動検出
- ✅ ログイン時通知ポップアップ
- ✅ 義務診断の明確化
- ✅ CSV出力（監査対応）

### 👔 管理者機能
- ✅ 全乗務員の学習状況一覧
- ✅ 全乗務員の診断状況一覧
- ✅ 要注意項目の自動抽出
- ✅ CSV出力機能
- ✅ 統計ダッシュボード

---

## 🛠️ 技術スタック

- **Flutter**: 3.35.4
- **Dart**: 3.9.2
- **状態管理**: Provider 6.1.5+1
- **ローカルDB**: Hive 2.2.3 + hive_flutter 1.1.0
- **その他**: shared_preferences 2.5.3, intl 0.19.0, uuid 4.5.2

---

## 📦 セットアップ

### 前提条件
- Flutter 3.35.4
- Dart 3.9.2

### インストール手順

```bash
# 1. リポジトリのクローン
git clone https://github.com/YuhiAozora/taxi-education-manager.git
cd taxi-education-manager

# 2. 依存関係のインストール
flutter pub get

# 3. Web版の起動
flutter run -d chrome

# 4. Android版のビルド
flutter build apk --release
```

---

## 📱 iPhoneでの使用方法

### ホーム画面に追加（アプリ化）

1. **Safari**でURLを開く
2. 画面下部の**共有ボタン**(□に↑)をタップ
3. **「ホーム画面に追加」**を選択
4. 名前を確認して**「追加」**
5. ホーム画面にアイコンが追加される

---

## 🔔 通知機能

### ドライバー向けログイン時通知

ドライバーがログインすると、以下の場合に自動的にポップアップが表示されます:

#### ⚠️ 期限切れの診断（赤色警告）
- 次回診断予定日を過ぎている診断

#### 📅 もうすぐ期限の診断（オレンジ色警告）
- 通知期間内に入っている診断
  - 適齢診断: 60日前から通知
  - 初任診断: 30日前から通知
  - 適性診断: 30日前から通知
  - 事故惹起: 7日前から通知
  - 特定診断Ⅰ: 30日前から通知
  - 特定診断Ⅱ: 60日前から通知

---

## 📊 運輸局監査対応

### 必要な記録
- ✅ 診断実施記録（診断種別、受診日、実施機関、診断書番号）
- ✅ 管理台帳（全運転者の診断状況）
- ✅ 期限管理（期限切れの検出、事前通知）
- ✅ CSV出力（監査資料作成）

### CSV出力項目
- 社員番号
- 氏名
- 診断種別
- 前回受診日
- 次回予定日
- 実施機関
- 診断書番号
- ステータス

---

## 📂 プロジェクト構造

```
lib/
├── main.dart                           # エントリーポイント
├── models/                             # データモデル
│   ├── user.dart                       # ユーザーモデル
│   ├── education_item.dart            # 教育項目モデル
│   ├── learning_record.dart           # 学習記録モデル
│   └── medical_checkup.dart           # 診断記録モデル
├── screens/                            # 画面
│   ├── login_screen.dart              # ログイン画面
│   ├── driver_home_screen.dart        # ドライバーホーム
│   ├── admin_home_screen.dart         # 管理者ホーム
│   ├── education_detail_screen.dart   # 教育詳細画面
│   ├── learning_history_screen.dart   # 学習履歴画面
│   ├── medical_checkup_screen.dart    # 診断管理画面
│   ├── medical_checkup_detail_screen.dart  # 診断詳細画面
│   └── admin_checkup_management_screen.dart # 管理者診断台帳
└── services/                           # サービス
    └── database_service.dart          # データベースサービス
```

---

## 🚀 デプロイ

### Cloudflare Pages（推奨）

```bash
# 1. Webビルド
flutter build web --release

# 2. Cloudflare Pagesにデプロイ
# build/web ディレクトリをアップロード
```

### Firebase Hosting

```bash
# 1. Firebase CLIのインストール
npm install -g firebase-tools

# 2. Firebaseプロジェクトの初期化
firebase init hosting

# 3. Webビルド
flutter build web --release

# 4. デプロイ
firebase deploy --only hosting
```

---

## 📝 ライセンス

このプロジェクトは、タクシー事業者向けの教育・診断管理システムです。

---

## 🙏 謝辞

- 国土交通省の教育マニュアルに準拠
- Flutterコミュニティ
- オープンソースライブラリの作者の皆様

---

## 📧 お問い合わせ

フィードバックや改善要望は、GitHubのIssuesまでお願いします。
