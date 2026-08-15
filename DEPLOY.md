# デプロイ手順（Web / Vercel）

ペタネームの Web 版を Vercel の本番URLへ反映する手順。

- 本番URL: https://web-sigma-drab-72.vercel.app
- Vercel プロジェクト名: `web`（`toriumikengo-6712s-projects` チーム配下）

---

## 手順

### 1. ビルド

```bash
cd "/c/Users/tori/Downloads/nanimonjya-main/nanimonjya-main"
flutter build web --release
```

出力先は `build/web/`。`web/app-ads.txt`（AdMob審査用）はビルド時に自動でコピーされる。

### 2. デプロイ

**必ず `build/web` の中で実行する。** リポジトリのルートから叩くとソースコードごとアップロードされ、ファイル数上限（15,000）に引っかかって失敗する。

```bash
cd "/c/Users/tori/Downloads/nanimonjya-main/nanimonjya-main/build/web"
npx vercel --prod
```

### 3. 確認

デプロイ完了時に表示される URL、または本番URL（https://web-sigma-drab-72.vercel.app）を開いて動作確認する。

---

## プロジェクトの紐付けについて

`build/web/.vercel/project.json` に紐付け情報を置いてある。

```json
{"projectId":"prj_OB0KyXoExetfZSk3YWoFJnOoDGx3","orgId":"team_NrVyErIF90VQ83A8D5SkK8z2","projectName":"web"}
```

⚠️ `flutter build web` は `build/web/` を作り直すため、**このファイルはビルドのたびに消える**。消えた状態で `npx vercel --prod` を叩くと「新しいプロジェクトを作るか？」と対話で聞かれてしまうので、ビルド後にこのファイルを置き直すか、対話に従って既存の `web` プロジェクトを選ぶこと。

---

## つまずきどころ

| 症状 | 原因と対処 |
|---|---|
| `files should NOT have more than 15000 items` | リポジトリのルートでデプロイしている。`build/web` に移動してから実行する |
| 対話で「Set up and deploy?」と聞かれる | `build/web/.vercel/project.json` が消えている。上記JSONを置き直す |
| ログインを求められる | `npx vercel login` を対話ターミナルで一度実行する |
| デプロイは成功したが内容が古い | `flutter build web --release` を先に実行し忘れている |

---

## 参考: 他の配信先

- **Android (Google Play)**: `scripts/bump_and_build.ps1` で versionCode を +1 して AAB をビルド。出力は `build/app/outputs/bundle/release/app-release.aab`
- **Firebase Hosting**: `build/web` を同様にデプロイ可能（現在はVercelが主）
