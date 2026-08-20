## 🎵 マイページの音楽変更の修正（v2.5.0 更新ビルド）

**マイページで音楽を変えると、選んだ曲がその場でちゃんと鳴るように直しました。**

- 🎮 **ゲーム中の曲**: 選ぶと、そのまま「ゲーム中の曲」としてすぐ再生されるように
- 🏠 **ホームの曲**: 選ぶと、そのまま「ホームの曲」としてすぐ再生されるように（別の場面の曲が混ざって鳴らなくなる不具合を修正）
- 🎺 **結果画面の曲**: 選ぶと、そのまま「結果画面の曲」としてすぐ再生されるように（「おまかせ」も勝利曲から1曲選んで鳴る）
- これまでは「1曲だけ鳴ってホームの曲に戻る」・「選んだ場面と違う曲が鳴る」状態で、曲がちゃんと聴けないことがありました。曲を選んだら、その曲が鳴り続けるようになりました。

## 🎵 My Page Music Fix (v2.5.0 update)

**Changing music on My Page now actually plays the song you chose.**

- 🎮 **Game music**: selecting it now plays it right away as the in-game track
- 🏠 **Home music**: selecting it now plays it right away as the home track (fixed a bug where the wrong scene's music played instead)
- 🎺 **Result music**: selecting it now plays it right away as the result track ("Shuffle" picks a real victory march to play)
- Previously the selected song only played once and then reverted to the home track, or the wrong scene's music played. Now your chosen song keeps playing.

## v2.5.0 リリースノート

### 🔧 今回の更新（お詫びと変更内容）

**まず、以前のバージョンでゲームのバランスや表示にご不便をおかけしたことをお詫びいたします。** 今回の更新で、ご指摘いただいた点を中心に改善しました。

**主な変更点**
- **なまえコールの修正**: 同じ人が延々と出続ける問題を直し、出る回数を調整（デフォルトは6人×1人4枚）
- **回答フィードバックを強化**: 正解はボタンが緑に変わり正解音、不正解は赤に変わって不正解音。答えが分かったらすぐ次の問題へ
- **「どちらも取れなかった」の表示を削除**: ラウンド結果の寂しい表示をなくし、テンポ良く進むように
- **チュートリアルを1人に簡素化**: 2人で出てきて片方にしか回答できない不自然さを解消
- **初回起動の簡素化**: 「さあ、はじめよう！」の導入画面を廃止し、起動後すぐ遊べるように。チュートリアルは「見る／見ない」を選べます
- **よみものを読みやすく**: 全話を1つのスクロールで読めるようにし、目次からジャンプ可能に
- **記事を10本追加**: 2026年の研究をもとにした記事を追加（コイン1,000で購入）
- **コインを現金で買えるように**: ショップに課金（500／1,200／3,000コイン・広告除去・プレミアム）を常時表示
- **タブとホームの整理**: 顔メモをタブに格上げ、ホームの「みんなで対戦」「ひとりで対戦」を大きく表示
- **基本キャラを24種に拡充**: 追加キャラ9体を基本キャラへ昇格し、最初から24種の顔で遊べます
- **みんなで対戦の人数をスライダー化**: 2〜12人まで自由に選べます
- **デフォルト設定の調整**: 6人 × 1人4枚（山札24枚）
- **あそびかたを充実**: 「みんなで対戦」「ひとりで対戦」の遊び方をくわしく説明

### 🛍 ショップを大幅拡充（収益導線の強化）
- 🌟 **神スキン**3種（黄金の記憶／宇宙の織り手／ネオン・ゴッド）を追加。覚えた枚数に応じて演出が豪華に
- 💀 **ハードコアチケット**：次のゲームの報酬が3倍になる高難度オプション
- 🎰 **ガチャ**：コインで追加キャラを抽選（単発／3連）
- 🪙 **コイン倍増ゲーム**：3人覚えるごとにコインが倍額
- ⚡ **コインブースト**：次のゲームの獲得コイン2倍
- 🏪 **日替わりショップ**：毎日5品を30〜70%OFFで提供
- 🎯 **動画スタンプラリー**：7日連続でレジェンド報酬
- ショップUIを刷新：コインバー一体化・「🔥 人気＆お得」見出し・お得感のあるレイアウト

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

### 🔧 This Update (Apology & Changes)

**We sincerely apologize for any inconvenience caused by the game's balance and display in previous versions.** This update focuses on the issues you reported.

**Main changes**
- **Name Call fix**: the same person no longer loops endlessly — the number of appearances is now controlled (default: 6 people × 4 copies each).
- **Answer feedback**: correct turns the button green with a correct sound; wrong turns it red with a wrong sound. The next question comes right away.
- **Removed the "nobody got it" banner** for smoother pacing.
- **Simplified tutorial**: now a single person, and you can choose "Watch / Skip".
- **Faster first launch**: removed the "Let's begin!" intro screen so you can start playing right away.
- **Easier reading**: all articles are now one continuous scroll with a table of contents for jumping.
- **10 new articles** based on 2026 research (1,000 coins each).
- **Buy coins with real money**: in-app purchases (500 / 1,200 / 3,000 coins, remove ads, premium) are now always visible in the shop.
- **Reorganized tabs & home**: Face Notes is now a tab, and the Party Match / Solo Match buttons are larger.
- **24 base characters**: 9 shop characters were promoted to the base roster, so 24 faces are available from the start.
- **Party Match player slider**: choose between 2 and 12 players with a slider.
- **Default settings adjusted**: 6 people × 4 copies each (24-card deck).
- **Enhanced how-to-play**: detailed guides for Party Match and Solo play.

### 🛍 Expanded Shop (monetization)
- 🌟 **God Skins** (Golden Memory / Cosmic Weaver / Neon God) — increasingly flashy effects as you memorize more
- 💀 **Hardcore Ticket** — 3x rewards on your next game
- 🎰 **Gacha** — coin-based character lottery (single / 3-pull)
- 🪙 **Coin Doubler** — double coins for every 3 people memorized
- ⚡ **Coin Boost** — 2x coins on your next game
- 🏪 **Daily Deals** — 5 rotating items at 30–70% off
- 🎯 **Ad Stamp Rally** — 7-day streak for a Legendary reward
- Shop UI revamp: unified coin bar, "🔥 Hot Deals" headers, deal-focused layout

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
