# YouTube自動投稿 設定手順（1回だけ）

## 1. Google Cloud ConsoleでOAuth認証情報を作る

1. https://console.cloud.google.com を開く（Googleアカウントでログイン）
2. プロジェクトを作成 → 名前「PetaName」
3. 左上メニュー → APIとサービス → ライブラリ →「YouTube Data API v3」を検索 → 有効にする
4. 左メニュー → OAuth同意画面
   - User Type: 外部
   - アプリ名: PetaName
   - メール: 自分のGmail
   - デベロッパーの連絡先: 自分のGmail
   - スコープ: 何も追加しなくてOK → 保存して次へ
   - テストユーザー: 自分のGmailを追加 → 保存
5. 左メニュー → 認証情報 → 認証情報を作成 → OAuthクライアントID
   - アプリケーションの種類: デスクトップアプリ
   - 名前: PetaName Uploader
   - 作成 → JSONをダウンロード
6. ダウンロードしたJSONを `scripts/client_secret.json` にリネームして置く

## 2. 初回認証

```bash
cd "C:\Users\tori\Downloads\nanimonjya-main\nanimonjya-main"
python scripts/youtube_upload.py --video store_assets/promo/youtube_shorts_1080x1920.mp4
```

ブラウザが開く → Googleアカウントを選ぶ →「このアプリはGoogleで確認されていません」→ 続行 → 許可

## 3. 以降は自動

トークンが `scripts/.youtube_token.pickle` に保存されるので、次回から自動。

```bash
# 動画をアップロード
python scripts/youtube_upload.py --video store_assets/promo/youtube_shorts_1080x1920.mp4

# フォルダ内の全MP4を一括アップロード
python scripts/youtube_upload.py --batch store_assets/promo/
```
