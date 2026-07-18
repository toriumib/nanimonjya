# ペタネーム (PetaName)

顔と名前の記憶トレーニングゲーム。「顔はわかるのに名前が出てこない」を、
顔カード×名前カードの神経衰弱（ペアマッチング）で楽しくトレーニングするFlutterアプリ。

- 🧠 一人特訓（レベル1〜3、手数・タイムでスコア化）
- 📚 記憶術トレーニング（タグ付け法をガイド付きで実践）
- 🤖 CPU対戦（交互めくりのペア数勝負、段位レーティング）
- 📇 「名前の覚え方」記憶術の読み物（タグ付け・映像化・場所法）

## 配信

- Android: Google Play `com.nanimonjya`（内部ID。表示名は「ペタネーム」）
- Web: Vercel / Firebase Hosting

## 開発

```powershell
flutter pub get
flutter run

# リリースAAB（versionCode自動bump＋署名）
.\scripts\bump_and_build.ps1
```

詳細な開発メモは `CLAUDE.md` を参照。
