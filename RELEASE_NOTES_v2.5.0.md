## v2.5.0 リリースノート

### 🏠 ホーム画面を1画面にリニューアル
- ロゴ・マスコットをコンパクト化し、すべての操作がスクロールなしで行えるようになりました
- 「みんなで対戦」ボタンを大きくし、いちばん使われているモードにすぐアクセス
- ルールのひとこと説明を常時表示。初めての人でも迷わない
- 📖ルール・👧👦チュートリアル・🧑‍🎨顔メモ・⭐評価・🏆マイページ・☕支援 の6つの導線を常設
- 🧠 名前の覚え方Tipsをホームで横スクロール表示（タップで全文）

### 🧑‍🎨 顔メモを大型カードで常設
- ホーム画面に顔メモカードを常時表示。登録人数も見える
- タップですぐに顔の登録・学習が可能

### ⏱ ゲーム設定に所要時間を表示
- キャラ数と枚数を変えると「⏱ 約2分（6人×5枚 = 30枚）」のように所要時間が表示されます
- 既定の登場人数を12人→6人に変更（完走率改善のため）

### 🧠 記憶の殿堂（ショップ新カテゴリ）
- コインで買えるプレミアム知識記事5本を追加
  1. ⏰ なぜ復習は「あとで」が効くのか（スペーシング効果）
  2. 🧪 思い出すこと自体が最強の勉強法（検索練習効果）
  3. 😴 覚えたら、眠る（睡眠と記憶固定化）
  4. 🥖 ベイカーさんとパン屋さん（名前記憶の不思議）
  5. 🪞「自分ごと」にすると忘れない（自己関連づけ効果）
- すべて出典（原著論文の著者・年・誌名）つき

### 📈 広告・収益の改善
- インタースティシャル表示頻度を改善（3プレイ→2プレイに1回）
- ホームに「📺 動画でキャラGET」ボタンを追加
- App Open広告を有効化

### 🔥 継続率の改善
- 連続ログイン日数と週間おぼえた人数をホームに常時表示
- 「あとN日で新キャラ解放」のストリーク進行度を表示
- 戻るボタンで「もう行っちゃうの？」離脱防止ダイアログ
- なまえコール画面のスクロール不要化（全操作が1画面で完結）

### 🌐 英語対応の強化
- ホーム画面・ゲーム画面・ショップのすべての文言を日英対応

### 🐛 バグ修正
- game_exit 追跡を6画面すべてに実装（離脱率の正確な計測）
- インタースティシャル広告のカウンタ保護（表示機会の取りこぼし防止）
- BGM再生のクラッシュ耐性強化
- 顔メモデータ読み込みの型安全化

---

## v2.5.0 Release Notes

### 🏠 Redesigned Home Screen
- Everything fits on one screen — no scrolling needed
- Giant "Party Play" button for the most-used mode
- One-line rule summary always visible
- 📖 Rules / 👧👦 Tutorial / 🧑‍🎨 Face Notes / ⭐ Review / 🏆 Profile / ☕ Support shortcuts
- 🧠 Memory tips with horizontal scroll (tap for full articles)

### 🧑‍🎨 Face Notes Large Card
- Prominent, always-visible card on home screen
- Shows registered person count. Tap to open instantly

### ⏱ Estimated Game Time
- Settings sheet now shows "~2 min (6×5=30 cards)" as you adjust sliders
- Default people count reduced from 12 to 6 to improve completion rate

### 🧠 Memory Hall (New Shop Category)
- 5 premium knowledge articles unlockable with coins:
  1. ⏰ Why spacing works (the science)
  2. 🧪 The testing effect — recall IS learning
  3. 😴 Sleep and memory consolidation
  4. 🥖 The Baker/baker paradox
  5. 🪞 The self-reference effect
- All articles cite original research (authors, year, journal)

### 📈 Revenue & Ads
- Interstitial frequency improved (every 2 plays, down from 3)
- "📺 Ad → Free Character" button on home
- App Open ad enabled

### 🔥 Retention Improvements
- Login streak and weekly "people learned" always visible
- "N more days to unlock a character" progress indicator
- Exit intent dialog ("Leaving already?")
- Name Call screen: no scrolling — everything on one screen

### 🌐 English Localization
- All home, game, and shop strings now fully bilingual (ja/en)

### 🐛 Bug Fixes
- game_exit tracking on all 6 game screens
- Interstitial counter protection
- BGM crash resilience
- Face Note data type safety
