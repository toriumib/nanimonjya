# セキュリティ・課金爆発対策メモ

DDoS やいたずらで Firebase の請求が跳ね上がらないための対策一覧。
**コード側で入れた対策**と、**Firebaseコンソールでやってもらう対策**の2段構え。

---

## ✅ コード側で対応済み（このリポジトリに含まれる）

| 対策 | ファイル | 効果 |
|---|---|---|
| Firestoreルール（認証必須・roomsのみ・サイズ上限） | `firestore.rules` | 未ログインの無制限read/writeを遮断。他コレクションへのアクセス全面禁止 |
| Storageルール（書き込み全面禁止） | `storage.rules` | アップロードによる容量・転送量課金を根絶 |
| Cloud Functions の同時起動上限 `maxInstances:10`(5) | `function/index.js` | スパイクしてもインスタンスが青天井に増えない＝請求の天井ができる |
| Functions の認証必須チェック | `function/index.js` | 未ログインbotによる Gemini(Vertex AI)/TTS のスパム呼び出しを遮断 |
| Functions の入力サイズ制限 | `function/index.js` | 長文・大量生成でAI/TTS課金を膨らませる攻撃を防止 |

### デプロイ方法（このPCから）
```bash
cd C:/Users/tori/Downloads/nanimonjya-main/nanimonjya-main
firebase deploy --only firestore:rules,storage,functions
```
※ ルールだけなら `firebase deploy --only firestore:rules,storage`

---

## 🔒 コンソールで必ずやること（最重要）

### 1. App Check を「強制」にする（最強のDDoS対策）
本物のアプリ（Play Integrity / reCAPTCHA）以外からの Firestore・Functions アクセスを
ほぼ完全に遮断できる。これが入っていれば、プロジェクトIDを知られても部外者は叩けない。

1. [Firebase Console → App Check](https://console.firebase.google.com/project/nanimonjya/appcheck)
2. Android アプリに **Play Integrity** を登録
3. Web アプリに **reCAPTCHA v3** を登録
4. **Cloud Firestore** と **Cloud Functions** を「**強制（Enforce）**」に切り替え
5. アプリ側にも App Check SDK の初期化を追加（`firebase_app_check` パッケージ）

> ⚠️ App Check を「強制」にする前に、必ずアプリ側にSDKを入れて動作確認すること。
> 先に強制にすると本物のアプリまで弾かれる。まず「モニタリング」で様子見 → 強制。

### 2. 予算アラート＋自動停止（請求の安全弁）
Firebase(Blaze)には**ハードな上限が無い**ので、自分で作る。

1. [Google Cloud Console → お支払い → 予算とアラート](https://console.cloud.google.com/billing)
2. 予算を作成（例: 月 **¥1,000** など無理のない額）
3. しきい値 50% / 90% / 100% でメール通知
4. （上級）100%到達で **Pub/Sub → Cloud Function で課金を自動停止**する仕組みを追加すると完全防御
   - 参考: "Cloud Billing budget disable billing" で検索

### 3. Firestore / Functions の無料枠を意識
- Firestore: 1日あたり 読み取り5万・書き込み2万 まで無料
- 対戦1回でおおよそ 読み取り数十〜百・書き込み数十。個人利用なら無料枠内に収まる想定
- App Check + maxInstances があれば、悪意ある大量アクセスでも天井で頭打ちになる

---

## 補足
- 匿名認証は有効のままでOK（アプリの入室フローが使用）。App Checkと併用すれば「アプリ経由の匿名ユーザーだけ」に限定できる。
- Storageのカスタム画像アップロード機能は廃止済み（`storage.rules`で書き込み禁止）。
