# ペタネーム データ分析と改善計画

**分析期間**: 2026-07-12 〜 2026-08-08（28日間）
**データソース**: Firebase Analytics, AdMob, Crashlytics（コード注釈から逆算）

---

## 1. サマリ

| 指標 | 値 | 評価 |
|---|---|---|
| 総アクティブユーザー | 162 (Android 142, Web 20) | オーガニック流入あり |
| 新規ユーザー | 182 (Direct 102, Organic Search 80) | SEO効いている |
| DAU | 平均8.6、最大34 | 安定しているが伸びしろ大 |
| Day 1 リテンション | 約7.7% | **危機的（業界平均25-30%）** |
| Day 7 リテンション | 0% | **事実上ゼロ** |
| game_start → game_end 完走率 | 39.3% (229→90) | **致命的** |
| app_exception | 317件（11ユーザー、28.8件/人） | **緊急対応** |
| 収益 | $5.82 (AdMob) | **収益化が機能していない** |

---

## 2. 発見されたバグ（コード位置特定済み）

### 2.1 【緊急】app_exception 317件 — 推定原因と発生箇所

**データ**: 11ユーザーで317件（1人あたり28.8件＝同じ例外を繰り返し発生）。

**`app_exception` の正体**: アプリコードから送信しているのではなく、Firebase Crashlytics が `FlutterError.onError` と `PlatformDispatcher.instance.onError`（`lib/main.dart:44-51`）で捕まえた未処理例外を自動収集したもの。

**推定発生源（可能性順）**:

1. **オーディオサブシステム**（最有力）
   - `lib/services/bgm.dart:47-53` — `_serialize()` 内の just_audio プラットフォームチャネル。`Platform player already exists` や `Loading interrupted` が特定デバイスで出る
   - `lib/services/sfx.dart:60-93` — 効果音プールの `setAsset`/`play`/`setSpeed`
   - `lib/services/speech.dart:33-85` — flutter_tts の `speak`/`setLanguage`

2. **`.then()` チェーンの未捕捉エラー**
   - `lib/screens/story_screen.dart:45` — `SharedPreferences.getInstance().then(...)` に `.catchError()` がない
   - `lib/screens/match_game_screen.dart:154` — `MemoryStats.instance.load().then(...)` に `.catchError()` がない（name_battle, rank_match, turn_pairs, report_screen, story_screen, top_screen, tutorial_screen でも同様のパターン）

3. **型アサーション失敗**
   - `lib/services/custom_roster_service.dart:142` — `CustomEntry.fromJson()` が JSON値を `as String` でキャストする前に型チェックしていない。破損データでクラッシュ
   - `lib/services/custom_roster_service.dart:381` — `_entries.firstWhere(..., orElse: () => throw 'not found')` が不正なIDで例外を投げる
   - `lib/widgets/route_transitions.dart:76` — `ModalRoute.of(context) as PageRoute<T>` のキャスト失敗

**対応**:
1. Crashlytics コンソールで実際のスタックトレースをグループ化して上位3件を特定
2. `lib/services/bgm.dart:48` の `catchError` 内に `FirebaseCrashlytics.instance.recordError(e, stack)` を追加
3. `lib/screens/story_screen.dart:45` と全ゲーム画面の `.then()` に `.catchError()` を追加
4. `lib/services/custom_roster_service.dart:142` の `fromJson` に型チェックを追加

---

### 2.2 【緊急】game_start 229件 → game_end 90件（102件消失）の根本原因

**驚くべき発見**: `game_exit` 追跡が実装されているのは **6つのゲーム画面のうち1つだけ**（`name_call_screen.dart`）。

| 画面 | game_start | game_end | game_exit (dispose) | WidgetsBindingObserver |
|---|---|---|---|---|
| **name_call_screen** | ✅ L326 | ✅ L832 | ✅ L383 | ✅ L115/358 |
| **match_game_screen** | ✅ L179 | ✅ L307 | **❌ なし** | **❌ なし** |
| **name_battle_screen** | ✅ L171 | ✅ L309 | **❌ なし** | **❌ なし** |
| **rank_match_screen** | ✅ L137 | ✅ L316 | **❌ なし** | **❌ なし** |
| **turn_pairs_screen** | ✅ L129 | ✅ L266 | **❌ なし** | **❌ なし** |
| **tutorial_play_screen** | ✅ L82 | ✅ L117 | **❌ dispose自体がない** | **❌ なし** |

37件の `game_exit` はすべて `name_call_screen` からのもの。他の5画面は途中離脱しても何も記録されない。

**さらに**：
- `match_game_screen.dart` と `name_battle_screen.dart` は `PopScope` すら実装されておらず、Androidの戻るボタンで確認ダイアログなしにゲームが破棄される
- アプリが強制終了（スワイプ）されると `AppLifecycleState.detached` を誰も拾っていない

**対応**:
1. 5つの画面すべてに `name_call_screen.dart` と同じパターンを実装する：
   - `_finished` フラグ + `dispose()` での `gameExit(reason: 'quit')` 送信
   - `WidgetsBindingObserver` + `didChangeAppLifecycleState` での `gameBackground`/`gameResume` 送信
   - `PopScope` による戻るボタンインターセプト
2. `AppLifecycleState.detached` を全画面で拾い、`paused` 時に退避した進捗を次回起動時に遅延送信

---

### 2.3 【緊急】インタースティシャル広告 446ロード→14表示（3.1%）

**コード分析** (`lib/services/interstitial_ad_helper.dart`):
- 起動時に `load()` を呼んでいない。最初の数プレイは `_ad` が常に null
- `plays` カウンタは SharedPreferences に保存されるが、`_ad` はメモリ上のため、アプリ再起動で必ず null に戻る
- `plays >= 3` で表示しようとするが `_ad == null` なのでスキップ、plays だけ進む
- `minIntervalSeconds = 90` の制限も短いゲーム連続時の表示機会をさらに減らしている

**加えて**: `lib/main.dart:61-66` で App Open 広告（起動時全画面、最もeCPMが高い形式）が**実装済みなのにコメントアウトされている**。

**対応**:
1. `InterstitialAdHelper.load()` を `main.dart` の初期化時に呼ぶ（起動時プリロード）
2. `plays >= playsPerAd && _ad == null` のときは plays を進めず、次回に持ち越す
3. App Open 広告を有効化（`main.dart:66` のコメントアウト解除）。すでに初回スキップ・120秒間隔・他の全画面広告との排他制御は実装済み
4. `minIntervalSeconds` を90→60に短縮（様子を見ながら）

---

### 2.4 リワード広告のユニットID誤り（修正済みだが影響あり）

**`lib/services/ad_ids.dart:16-22`**: 以前のコードがリワード広告の枠IDにリワード**インタースティシャル**のID（`/2619409531`）を指定していた。`RewardedAd.load()` はリワード形式の枠IDが必要なため、**本番で配信されていなかった**。現在は修正済み（`/9009716197`）。

### 2.5 デイリーボーナスの発見不能

**`lib/services/player_profile.dart:290`** でボーナス処理は実装されているが、UIがプロフィール画面（`lib/screens/profile_screen.dart:322-352`）のスクロール下に埋もれている。全ユーザーの**10%しかタブを切り替えたことがない**（`feature_open` 17人/162人）ため、残り90%は存在にすら気づかない。

### 2.6 通知許可フローが事実上死んでいる

**`lib/services/notify_prompt.dart`**: デフォルト `notifyOptIn = false`（`player_profile.dart:89`）。ゲームを1回完了したユーザーにしかプロンプトが出ず（`_minGames=1`）、最大2回まで。9回しか発火していない。許可を得ても `DailyReminder` が `notifyOptIn` をチェックするため、誰も有効にしていなければ通知は1通も飛ばない。

---

## 3. データが示す構造的問題

### 3.1 リテンション崩壊

- Day 1: 7.7%、Day 7: **0%**
- 週次維持率: 7/12-7/18コホート 51→17→7→7、7/19-7/25コホート 37→2（壊滅）
- 162人中87人（54%）が**1回もゲームを開始していない**

**原因の層**:
1. ゲーム完走率39%（クラッシュ＋離脱）
2. 「また明日」の動機がない（ボーナス非表示、通知なし）
3. オンボーディングが不十分（チュートリアル11ページは長すぎる）

### 3.2 マネタイズ不全

**AdMob実績（28日間）**:
| フォーマット | 表示 | 収益 |
|---|---|---|
| バナー | 788 | $0.16 |
| インタースティシャル | 14 | $0.10 |
| リワード | 14 | $0.00 |
| **合計** | | **$5.82** |

eCPM自体は悪くない（バナー $0.20、インタースティシャル $7.14）が、**表示量が致命的に少ない**。リワード収益 $0 は前項のユニットIDバグで説明がつく。

### 3.3 機能の未発見

タブ切替（`feature_open`）がわずか17ユーザー（10%）。90%のユーザーはホーム画面しか見ていない。ショップ・特訓・よみもの・プロフィールのすべてが発見されていない。

---

## 4. 改善計画

### フェーズ1：つぶす（今週）— バグ修正

#### Bug 1: 5画面に game_exit 追跡を実装

以下の5ファイルに `name_call_screen.dart` と同じパターンを追加する：
- `lib/screens/match_game_screen.dart`
- `lib/screens/name_battle_screen.dart`
- `lib/screens/rank_match_screen.dart`
- `lib/screens/turn_pairs_screen.dart`
- `lib/screens/tutorial_play_screen.dart`

```dart
// 追加するパターン（各ファイルに）
class _XxxState extends State<Xxx> with WidgetsBindingObserver {
  bool _finished = false;

  @override void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // ... existing code
  }

  @override void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_finished) return;
    if (state == AppLifecycleState.paused) {
      AppAnalytics.gameBackground(
        mode: _modeName, progressPct: _progressPct,
        card: _currentCard, totalCards: _totalCards,
      );
    } else if (state == AppLifecycleState.resumed) {
      // game_resume logging
    } else if (state == AppLifecycleState.detached) {
      // 退避して次回起動時に遅延送信
      _deferGameExit();
    }
  }

  @override void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!_finished) {
      AppAnalytics.gameExit(
        mode: _modeName, reason: 'quit',
        progressPct: _progressPct, people: _peopleCount,
      );
    }
    super.dispose();
  }

  // _finishGame() や _goToResult() の先頭で:
  // _finished = true;
  // AppAnalytics.gameExit(mode: _modeName, reason: 'completed', progressPct: 100, people: _peopleCount);
}
```

#### Bug 2: インタースティシャル表示率改善

**`lib/main.dart`**: App Open 広告の有効化（コメントアウト解除）
```dart
// 現在 L61-66:
// AppOpenAdHelper.instance.start();
// ↓
AppOpenAdHelper.instance.start();
```

**`lib/services/interstitial_ad_helper.dart`**: 起動時プリロードとカウンタ保護
- `main.dart` の初期化シーケンスで `InterstitialAdHelper.instance.load()` を呼ぶ
- `onGameFinished()` 内で `plays >= playsPerAd && _ad == null` のときは plays を進めない（次回に持ち越し）

#### Bug 3: 未捕捉エラーに Crashlytics 記録を追加

以下の `.catchError()` と `.then()` に `FirebaseCrashlytics.instance.recordError` を追加：
- `lib/services/bgm.dart:48`
- `lib/screens/story_screen.dart:45`
- `lib/screens/match_game_screen.dart:154`（+ 同じパターンの全画面）

### フェーズ2：なおす（来週）— UX改善

- [ ] **デイリーボーナスをホームに出す** (`lib/screens/top_screen.dart`)
  - 未受け取り時にホーム上部に目立つカードで表示（既存の赤バッジはタブにしか出ていない）
  - 「🔥 連続○日」のストリーク表示
  
- [ ] **ゲーム完走率向上（39% → 65%）**
  - 残り枚数表示は実装済み（`_deckProgress`）。さらに進捗50%で「折り返し！」の声かけ
  - デフォルト人数を6人に（`name_call_screen.dart:83` の `peopleCount` デフォルト変更）
  
- [ ] **通知許可率の改善**
  - プロンプトをゲーム1回完了→**チュートリアル直後**に移動
  - 研究Tips（「1日おくと記憶が定着する」）とセットで価値を伝える
  
- [ ] **チュートリアルの短縮**
  - `lib/screens/tutorial_screen.dart` の11ページは長すぎる。前半5ページ＋残りは「もっと読む」方式に

### フェーズ3：そだてる（再来週〜）— リテンションと収益

- [ ] **リワード広告の導線追加**
  - デイリーボーナスに「動画で2倍」を追加
  - ショップ常設の「🪙 動画で+60コイン」ボタン

- [ ] **ショップの発見性**
  - ゲームクリア時に「新しいキャラがショップに登場！」ティーザー
  - コイン残高をホームに常時表示

- [ ] **リテンション習慣づくり**
  - 「今日覚えた人数」のカレンダー表示
  - 週間レポート通知（「今週は◯人覚えました！」）

### フェーズ4：実験する（1ヶ月後〜）

- [ ] **課金（IAP）試験導入** — `adsRemoved` フラグは実装済み
- [ ] **オンライン対戦の再検討** — マッチ待ち時間をCPU代理で埋めるハイブリッド方式
- [ ] **Web→アプリ導線** — Webユーザー（高エンゲージメント）にアプリインストール誘導

---

## 5. KPI 目標

| 指標 | 現在 | 1ヶ月目標 | 3ヶ月目標 |
|---|---|---|---|
| Day 1 リテンション | 7.7% | 20% | 30% |
| Day 7 リテンション | 0% | 8% | 15% |
| ゲーム完走率 | 39% | 60% | 75% |
| app_exception (件/月) | 317 | <50 | <20 |
| インタースティシャル表示率 | 3.1% | 60% | 80% |
| 月間広告収益 | $5.82 | $30 | $100 |
| デイリーボーナス利用率 | 3人 | 30人 | 60人 |
| 初回ゲーム開始率 | 46% | 65% | 80% |

---

## 6. 参考：修正対象ファイル一覧

| 優先度 | ファイル | 修正内容 |
|---|---|---|
| 🔴 P0 | `lib/screens/match_game_screen.dart` | game_exit 追跡 + WidgetsBindingObserver 追加 |
| 🔴 P0 | `lib/screens/name_battle_screen.dart` | game_exit 追跡 + WidgetsBindingObserver 追加 |
| 🔴 P0 | `lib/screens/rank_match_screen.dart` | game_exit 追跡 + WidgetsBindingObserver 追加 |
| 🔴 P0 | `lib/screens/turn_pairs_screen.dart` | game_exit 追跡 + WidgetsBindingObserver 追加 |
| 🔴 P0 | `lib/screens/tutorial_play_screen.dart` | game_exit 追跡 + WidgetsBindingObserver + dispose 追加 |
| 🔴 P0 | `lib/main.dart:66` | App Open 広告の有効化 |
| 🔴 P0 | `lib/services/interstitial_ad_helper.dart` | 起動時プリロード + カウンタ保護 |
| 🟡 P1 | `lib/services/bgm.dart:48` | Crashlytics recordError 追加 |
| 🟡 P1 | `lib/screens/story_screen.dart:45` | .catchError() 追加 |
| 🟡 P1 | `lib/services/custom_roster_service.dart:142,381` | 型チェック + 安全なorElse |
| 🟢 P2 | `lib/screens/top_screen.dart` | デイリーボーナスカード表示 |
| 🟢 P2 | `lib/screens/tutorial_screen.dart` | ページ数短縮（11→5+補足） |
| 🟢 P2 | `lib/screens/name_call_screen.dart:83` | デフォルト人数 12→6 |
| 🟢 P3 | `lib/screens/profile_screen.dart` | カレンダー表示（覚えた人数） |
