import 'package:flutter/widgets.dart';

import '../models/cpu_difficulty.dart';
import '../models/person.dart';

/// 📮 バグ報告・改善要望の宛先。ここ1か所に置いて画面側から参照する。
const String kFeedbackEmail = 'entorip@gmail.com';

/// 新規追加した「メタ層」機能（コイン/実績/デイリー等）専用の簡易多言語ヘルパー。
/// 既存の AppLocalizations とは独立して自己完結させ、arb再生成の影響を受けないようにする。
class MetaStrings {
  final bool ja;
  const MetaStrings(this.ja);

  static MetaStrings of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return MetaStrings(code == 'ja');
  }

  String get coins => ja ? 'コイン' : 'Coins';
  String get profileTitle => ja ? 'マイページ・戦績' : 'Profile & Records';
  String get records => ja ? '戦績' : 'Records';
  String get gamesPlayed => ja ? '総プレイ数' : 'Games played';
  String get highScore => ja ? '最高得点' : 'Best score';
  String get bestDaily => ja ? '最高連続ログイン' : 'Best daily streak';
  String get bestSession => ja ? '最高連続プレイ' : 'Best play streak';
  String get lifetimeCoins => ja ? '累計コイン' : 'Lifetime coins';
  String get achievements => ja ? '実績' : 'Achievements';
  String get bgm => ja ? 'BGM' : 'Music';
  String get selectBgm => ja ? 'BGMを選ぶ' : 'Choose music';
  String get selected => ja ? '選択中' : 'Selected';
  String get unlock => ja ? 'アンロック' : 'Unlock';
  String get select => ja ? '選択' : 'Select';
  String get free => ja ? '無料' : 'Free';
  String get notEnoughCoins => ja ? 'コインが足りません' : 'Not enough coins';
  String get unlocked => ja ? 'アンロック！' : 'Unlocked!';
  String get locked => ja ? 'ロック中' : 'Locked';

  // オンライン対戦モードのセグメント切替（スマホでも折り返さない短い表記）
  String get modeTextShort => ja ? '📝 テキスト' : '📝 Text';
  String get modeVoiceShort => ja ? '🎤 通話' : '🎤 Voice';
  String get modeTextDesc =>
      ja ? 'AIがにた名前で7択クイズを出題' : 'AI makes similar-name quizzes';
  String get modeVoiceDesc =>
      ja ? 'AIが試合を音声で実況するよ' : 'AI gives voice commentary';

  // 🎲 おなまえガチャ（バズ機能: 押すたび爆笑ネームを提案）
  static const List<String> _gachaPrefixJa = [
    'モジャ', 'プリ', 'ドドド', 'キラ', 'ベロ', 'ガブ', 'ピカ', 'モチ',
    'ズン', 'ニョロ', 'ボヨ', 'ペチ', 'ゴロ', 'フガ', 'チュル', 'バブ',
    'デカ', 'チビ', 'ムキ', 'ホゲ',
  ];
  static const List<String> _gachaSuffixJa = [
    'モン', 'ピー', 'タロウ', 'リン', 'ゴン', 'ニャン', 'ボー', 'スケ',
    'ンゴ', 'チュウ', 'ペロ', 'ジロー', 'キング', 'サマ', 'ッチ', 'プリン',
    'ザウルス', 'ポン', 'ミー', 'ベエ',
  ];
  static const List<String> _gachaPrefixEn = [
    'Mog', 'Fluf', 'Zap', 'Bloo', 'Snug', 'Wig', 'Bop', 'Gro', 'Piko', 'Momo',
    'Blip', 'Choo', 'Der', 'Squi', 'Wob', 'Nom', 'Zig', 'Pud', 'Fro', 'Gib',
  ];
  static const List<String> _gachaSuffixEn = [
    'gy', 'zo', 'kins', 'bert', 'loo', 'pip', 'ster', 'nut', 'boo', 'zle',
    'bug', 'doo', 'mun', 'pop', 'ron', 'wig', 'zap', 'bee', 'gus', 'moo',
  ];

  /// ランダムなおもしろ名前を返す（seedはRandomの整数を渡す）
  String gachaName(int a, int b) {
    final pre = ja ? _gachaPrefixJa : _gachaPrefixEn;
    final suf = ja ? _gachaSuffixJa : _gachaSuffixEn;
    return '${pre[a % pre.length]}${suf[b % suf.length]}';
  }

  String get gachaLabel => ja ? 'おなまえガチャ' : 'Name Gacha';

  // 🎭 リザルトの一言コメント（成績に応じて）
  String resultQuip(bool won, int seed) {
    final quips = won
        ? (ja
            ? [
                'なまえセンス宇宙一！🌌',
                '記憶力バケモノ級！🧠✨',
                '今日のMVPはきみだ！🏆',
                'ネーミング王の風格…！👑',
                'わんちゃんも大よろこび！🐶🎉',
              ]
            : [
                'Naming sense: cosmic! 🌌',
                'Monster memory! 🧠✨',
                "Today's MVP! 🏆",
                'True Naming Royalty! 👑',
                'The dogs are so proud! 🐶🎉',
              ])
        : (ja
            ? [
                'つぎは総取りだ！🔥',
                'おしい！なまえ、覚えた？👀',
                'わんちゃんは見てるよ…🐶',
                'リベンジのにおいがする！💪',
                '練習あるのみ！ファイト！📣',
              ]
            : [
                'Next time, take it all! 🔥',
                'So close! Remember the names? 👀',
                'The dogs are watching… 🐶',
                'Smells like revenge! 💪',
                'Practice makes perfect! 📣',
              ]);
    return quips[seed % quips.length];
  }

  String get tagline => ja
      ? '顔と名前の記憶トレーニング'
      : 'Face & Name Memory Training';

  // 🎁 無料コインチェスト
  String get freeGift => ja ? '動画で無料コイン' : 'Free coins (video)';
  String get giftReady => ja ? 'プレゼントがとどいたよ！' : 'A gift is ready!';
  String giftGot(int n) => ja ? '🎉 $nコインもらったよ！' : '🎉 Got $n coins!';
  String giftWaitMin(int m) => ja ? 'つぎは約$m分後' : 'Next in ~${m}min';

  // 招待リンク共有
  String get shareInvite =>
      ja ? '招待リンクを送る' : 'Send invite link';
  String shareInviteText(String code, String link) => ja
      ? 'なまえがおで対戦しよう！🎮\n合言葉: $code\n下のリンクからそのまま入れるよ👇\n$link'
      : "Let's battle in Name Call! 🎮\nRoom code: $code\nTap to join 👇\n$link";

  // 離脱
  String get opponentLeftWin => ja
      ? '🏃 相手が離脱しました。あなたの勝ち！'
      : '🏃 Your opponent left. You win!';
  String get youLeftMatch =>
      ja ? '対戦から離脱しました（負け）' : 'You left the match (loss)';

  // 📖 珍名アルバム
  String get nameAlbum => ja ? 'みんなの珍名アルバム' : 'Funny Name Album';
  String get weeklyAward => ja ? '今週の爆笑ネーム大賞' : 'Weekly Funny Name Award';
  String get nameAlbumDesc => ja
      ? 'オンライン対戦でつけられた名前があつまるよ。おもしろかったら❤️で投票！（毎週リセット）'
      : 'Names from online battles gather here. Vote with ❤️! (resets weekly)';
  String get nameAlbumEmpty => ja
      ? 'まだ名前がないよ。オンライン対戦で1番のりの命名をしよう！'
      : 'No names yet. Be the first to name one in online battle!';

  // 📋 デイリーミッション
  String get dailyMissions => ja ? 'デイリーミッション' : 'Daily Missions';
  String get missionPlay3 => ja ? '3回あそぶ' : 'Play 3 games';
  String get missionCoin60 => ja ? 'コインを60かせぐ' : 'Earn 60 coins';
  String get missionOnline1 => ja ? 'オンラインで1回あそぶ' : 'Play 1 online match';
  String get claimReward => ja ? '受け取る' : 'Claim';
  String get done => ja ? '達成！' : 'Done!';
  String missionClaimedMsg(int n) =>
      ja ? '🎉 ミッション達成！+$nコイン' : '🎉 Mission complete! +$n coins';

  // 🐶 なつき度
  String get bondLabel => ja ? 'なつき度' : 'Bond';

  // 🏅 ランキング
  String get you => ja ? 'あなた' : 'You';
  String get ranking => ja ? 'ランキング' : 'Ranking';
  String get myRating => ja ? 'あなたのレート' : 'Your rating';
  String get nicknameLabel => ja ? 'ニックネーム' : 'Nickname';
  String get save => ja ? '保存' : 'Save';
  String get nameSaved => ja ? '表示名を保存したよ！' : 'Name saved!';
  String get rankingTop50 =>
      ja ? '⭐レート上位50人（ランダムマッチ）' : '⭐ Top 50 by rating (Random Match)';
  String get rankingEmpty =>
      ja ? 'まだ誰もいないよ。1番のりでランクインしよう！' : 'No one yet. Be the first!';
  String get rankingUnavailable => ja
      ? 'ランキングを読み込めませんでした。時間をおいて試してね。'
      : 'Could not load ranking. Please try again later.';
  String ratingChange(bool won, int delta) => won
      ? (ja ? 'レート +$delta ⬆️' : 'Rating +$delta ⬆️')
      : (ja ? 'レート -$delta ⬇️' : 'Rating -$delta ⬇️');

  // 🤖 CPU対戦
  String get cpuSectionTitle =>
      ja ? '🤖 ひとりであそぶ（CPU対戦）' : '🤖 Play Solo (vs CPU)';
  String get cpuSectionDesc => ja
      ? 'CPUより先に名前を思い出してタップ！'
      : 'Remember the name and tap before the CPU!';
  String get cpuEasy => ja ? '🐣 よわい' : '🐣 Easy';
  String get cpuNormal => ja ? '🤖 ふつう' : '🤖 Normal';
  String get cpuHard => ja ? '👿 つよい' : '👿 Hard';
  String get nameThisChar =>
      ja ? '✏️ このコに名前をつけよう！' : '✏️ Give this one a name!';
  String get nameHint => ja ? 'へんな名前ほど覚えやすい！' : 'The weirder, the better!';
  String get decideName => ja ? 'この名前にする！' : 'Name it!';
  String get whatWasTheName =>
      ja ? '⚡ このコの名前は…！？（CPUより先に！）' : '⚡ What was the name?! (Beat the CPU!)';
  String cpuTook(String name, int n) => ja
      ? '🤖 CPU「$name！」 $n枚総取りされた！'
      : '🤖 CPU: "$name!" — took $n cards!';
  String wrongAnswerCpuTook(String correct, int n) => ja
      ? '❌ お手つき！正解は「$correct」。CPUが$n枚総取り！'
      : '❌ Wrong! It was "$correct". CPU took $n cards!';
  String wrongAnswerReveal(String correct) =>
      ja ? '❌ おしい！正解は「$correct」でした。' : '❌ So close! It was "$correct".';
  String get soloQuizPrompt =>
      ja ? '⚡ このコの名前は…！？' : '⚡ What was the name?!';
  String get cpuLabel => ja ? '🤖 CPU' : '🤖 CPU';

  // ナビゲーション
  String get backToHome => ja ? 'ホームにもどる' : 'Back to Home';
  String get openTrophy =>
      ja ? '🏆 マイページ・戦績を見る' : '🏆 View Profile & Trophies';
  String get tipsTitle => ja ? '💡 できること' : '💡 Things to try';

  // 結果画面などで出す遊び方Tips（ランダムに1つ表示）
  List<String> tips() => ja
      ? [
          '🎨 コインをためて、ホーム画面のきせかえをしてみよう！',
          '🐾 コインがたまると、応援わんちゃんが増えていくよ！',
          '🎵 BGMショップでクラシックの名曲をアンロックできるよ！',
          '🏆 実績を集めて、称号をランクアップさせよう！',
          '📅 毎日ログインするとデイリーボーナスがもらえるよ！',
          '🎺 リザルトの曲もマイページで変えられるよ！',
          '📣 バトル中はチアガールと応援団がにぎやかに応援してくれるよ！',
          '👧👦 あそびかたはホームのチュートリアルで確認できるよ！',
        ]
      : [
          '🎨 Collect coins to change your home theme!',
          '🐾 More coins unlock more cheer dogs in battle!',
          '🎵 Unlock famous classical tracks in the music shop!',
          '🏆 Earn achievements to rank up your title!',
          '📅 Log in daily to grab your daily bonus!',
          '🎺 You can change the result music in your profile too!',
          '📣 The cheer girl and squad hype up every battle!',
          '👧👦 Check the tutorial on the home screen anytime!',
        ];
  String get quitGame => ja ? 'やめる' : 'Quit';
  String get quitTitle => ja ? 'ゲームをやめますか？' : 'Quit the game?';
  String get quitOnlineBody => ja
      ? 'いま抜けると対戦から退出します。本当にやめますか？'
      : 'Leaving now will exit the match. Are you sure?';
  String get quitOfflineBody =>
      ja ? 'ゲームをやめてホームにもどりますか？' : 'Quit and return to Home?';

  String get dailyBonus => ja ? 'デイリーボーナス' : 'Daily Bonus';
  String get claim => ja ? '受け取る' : 'Claim';
  String get claimed => ja ? '受け取り済み' : 'Claimed';
  String get comeBackTomorrow =>
      ja ? 'また明日も来てね！' : 'Come back tomorrow!';
  String streakDays(int n) => ja ? '$n日連続ログイン中🔥' : '$n-day streak 🔥';
  String get dayStreakLabel => ja ? '連続ログイン' : 'Login streak';

  String earnedCoins(int n) => ja ? '+$n コイン獲得！' : '+$n coins!';
  String get watchAdDouble =>
      ja ? '📺 動画を見てコイン2倍' : '📺 Watch ad to double coins';
  String get watchAdBonus =>
      ja ? '📺 動画を見て+50コイン' : '📺 Watch ad for +50 coins';
  String get doubledCoins => ja ? 'コイン2倍GET！🎉' : 'Coins doubled! 🎉';
  String get adNotReady =>
      ja ? '広告の準備中です。少し待ってね' : 'Ad not ready yet. Please wait.';
  String get adPreparing => ja ? '広告じゅんび中…' : 'Preparing ad…';
  String get adQueued => ja
      ? 'じゅんび中…できたら自動で再生するよ📺'
      : 'Loading… it will play automatically 📺';
  String get sessionBonus => ja ? '連続プレイボーナス' : 'Play streak bonus';
  String sessionBonusN(int n) =>
      ja ? '連続プレイボーナス +$n！' : 'Play streak bonus +$n!';
  String get newRecord => ja ? '🏆 自己ベスト更新！' : '🏆 New personal best!';

  String get dressup => ja ? 'きせかえ（ホームの色）' : 'Themes (Home color)';
  String get dressupDesc => ja
      ? 'えらぶとホーム画面の背景とタイトルの色がガラッと変わるよ！'
      : "Changes your Home screen's background & title color!";
  String get howToPlay => ja ? 'あそびかた' : 'How to Play';
  String get cheerSquad => ja ? 'チア応援団' : 'Cheer Squad';
  String get cheerSquadDesc => ja
      ? 'チアガールと応援団が、バトル中みんなを応援してくれるよ！'
      : 'The cheer girl and squad cheer you on during every battle!';
  String get cheerAllJoined =>
      ja ? '🎉 全員さいしょから参加中！' : '🎉 Everyone joins from the start!';
  String get cheerCostume => ja ? '応援団のいしょう' : 'Cheer Costumes';
  String get cheerCostumeDesc => ja
      ? 'コインで着せ替え！声援とゾーンの色もユーモアたっぷりに変わるよ🎽'
      : 'Change outfits with coins! Cheers & colors change too 🎽';
  String get upgrade => ja ? 'アップグレード' : 'Upgrade';
  String get maxLevel => ja ? '最大レベル！' : 'Max level!';
  String cheerLevelLabel(int lv) => ja ? '現在: レベル$lv' : 'Current: Lv.$lv';
  String get resultMusic => ja ? 'リザルトの音楽' : 'Result music';
  String get resultMusicDesc => ja
      ? '勝利のあとに流れる曲。クラシック曲は🎵BGMショップでアンロック！'
      : 'The song after victory. Unlock classics in the 🎵 music shop!';
  String achievementUnlocked(String name) =>
      ja ? '🏆 実績解除「$name」！' : '🏆 Achievement unlocked: $name!';
  String titleRankUp(String name) =>
      ja ? '👑 称号ランクアップ→「$name」！' : '👑 New title: $name!';
  String get titles => ja ? '称号' : 'Titles';
  String get currentTitleLabel => ja ? 'いまの称号' : 'Current title';
  String get dogSquad => ja ? '応援わんちゃんズ' : 'Cheer Dogs';
  String get dogSquadDesc => ja
      ? 'コインをためると仲間がふえて、バトル画面で応援してくれる！'
      : 'Earn coins to unlock more dogs cheering you on in battle!';
  String coinsToUnlock(int n) =>
      ja ? 'あと$nコインでアンロック' : '$n more coins to unlock';

  // ── Xシェア ──
  String get shareOnX => ja ? 'Xで自慢する' : 'Brag on X';
  // 称号入りでシェア（バズりやすい煽り文＋絵文字）
  String shareWin(int players, int score) => ja
      ? '【$titleForShare】なまえがおのCPU対戦で勝利！🏆 $score点で無双した😎\nキミは顔と名前、覚えられる？👇'
      : '[$titleForShare] Beat the CPU in Name Call! 🏆 Crushed it with $score pts 😎\nCan you match the faces to the names? 👇';
  String sharePlayed(int players, int topScore) => ja
      ? '【$titleForShare】なまえがおで顔と名前の記憶トレ中！🔥 最高$topScore点\nこの覚えゲー、地味にクセになる…🏷️\nいっしょにあそぼ👇'
      : "[$titleForShare] Training my name-memory in Name Call! 🔥 Top score $topScore\nThis memory game is weirdly addictive 🏷️ Come play 👇";
  String get shareHashtag =>
      ja ? '#名前を覚えよう #顔と名前の記憶トレ' : '#NameCall #NameMemoryTraining';
  // シェア文に埋め込む現在の称号（シェア直前に設定）。constクラスなのでstatic。
  static String titleForShare = '';

  // ── オンライン戦績・トロフィー ──
  String get onlineGamesLabel => ja ? 'オンライン対戦数' : 'Online games';
  String get onlineWinsLabel => ja ? 'オンライン勝利数' : 'Online wins';
  String onlineWinBonusN(int n) =>
      ja ? 'オンライン勝利ボーナス +$n！' : 'Online win bonus +$n!';

  // ── ランダムマッチ ──
  String get randomMatch => ja ? 'ランダムマッチ' : 'Random Match';
  String get randomMatchDesc => ja
      ? 'せかいのだれかとすぐに対戦！（テキストモード）'
      : 'Instantly play with someone in the world! (text mode)';
  String get searchingOpponent =>
      ja ? '対戦相手を探しています…' : 'Searching for an opponent…';
  String get opponentFound =>
      ja ? '対戦相手が見つかった！まもなく開始！' : 'Opponent found! Starting soon!';
  String get matchmakingFailed =>
      ja ? 'マッチングに失敗しました' : 'Matchmaking failed';
  String get matching => ja ? 'マッチング中…' : 'Matching…';
  String playersWaiting(int n) =>
      ja ? '現在 $n 人が待機中' : '$n player(s) waiting';
  String get cancel => ja ? 'キャンセル' : 'Cancel';
  String get orPlayWithFriends =>
      ja ? 'または、合言葉で友達と対戦' : 'Or play with friends via passcode';

  String get supportDev => ja ? '開発者を応援する' : 'Support the developer';
  String get supportBody => ja
      ? 'このゲームを気に入ってくれたら、コーヒー1杯分の応援をいただけると嬉しいです☕'
      : 'If you enjoy this game, a coffee-sized tip means the world ☕';
  String get couldNotOpenLink =>
      ja ? 'リンクを開けませんでした' : 'Could not open the link';

  // 実績名・説明
  String achTitle(String id) {
    switch (id) {
      case 'first_play':
        return ja ? '初プレイ' : 'First Play';
      case 'regular':
        return ja ? '常連さん' : 'Regular';
      case 'veteran':
        return ja ? 'ヘビーユーザー' : 'Veteran';
      case 'daily3':
        return ja ? '3日坊主克服' : '3-Day Streak';
      case 'daily7':
        return ja ? '1週間皆勤' : 'Weekly Streak';
      case 'binge5':
        return ja ? '一気に5戦' : '5 in a Row';
      case 'sharp20':
        return ja ? 'キレッキレ' : 'Sharp Mind';
      case 'rich1000':
        return ja ? 'コイン長者' : 'Coin Millionaire';
      case 'online_debut':
        return ja ? 'オンラインデビュー' : 'Online Debut';
      case 'online_win1':
        return ja ? 'オンライン初勝利' : 'First Online Win';
      case 'online_win5':
        return ja ? 'オンラインの強者' : 'Online Contender';
      case 'online_win20':
        return ja ? 'オンラインの覇者' : 'Online Champion';
      case 'random_debut':
        return ja ? '世界へ挑戦' : 'World Challenger';
      case 'cpu_win_easy':
        return ja ? 'CPU初勝利' : 'First CPU Win';
      case 'cpu_win_normal':
        return ja ? 'ふつうを撃破' : 'Normal Beaten';
      case 'cpu_win_hard':
        return ja ? 'つよいを撃破' : 'Hard Beaten';
      case 'cpu_win_oni':
        return ja ? '鬼段位撃破' : 'Oni Slayer';
      case 'quiz_perfect':
        return ja ? 'パーフェクト記憶' : 'Perfect Recall';
      case 'fast_reflex':
        return ja ? '反射神経王' : 'Lightning Reflexes';
      case 'training_10':
        return ja ? '特訓の鬼' : 'Training Junkie';
      default:
        return id;
    }
  }

  String achDesc(String id) {
    switch (id) {
      case 'first_play':
        return ja ? '初めてゲームを遊んだ' : 'Played your first game';
      case 'regular':
        return ja ? '10回プレイした' : 'Played 10 games';
      case 'veteran':
        return ja ? '50回プレイした' : 'Played 50 games';
      case 'daily3':
        return ja ? '3日連続でログインした' : 'Logged in 3 days in a row';
      case 'daily7':
        return ja ? '7日連続でログインした' : 'Logged in 7 days in a row';
      case 'binge5':
        return ja ? '1回のプレイで5戦した' : 'Played 5 games in one session';
      case 'sharp20':
        return ja ? '1ゲームで20点以上取った' : 'Scored 20+ in a single game';
      case 'rich1000':
        return ja ? '累計1000コイン貯めた' : 'Earned 1000 coins in total';
      case 'online_debut':
        return ja ? '初めてオンライン対戦をした' : 'Played your first online match';
      case 'online_win1':
        return ja ? 'オンライン対戦で初めて勝った' : 'Won your first online match';
      case 'online_win5':
        return ja ? 'オンライン対戦で5勝した' : 'Won 5 online matches';
      case 'online_win20':
        return ja ? 'オンライン対戦で20勝した' : 'Won 20 online matches';
      case 'random_debut':
        return ja ? 'ランダムマッチに初参加した' : 'Joined your first random match';
      case 'cpu_win_easy':
        return ja ? 'CPU（よわい）に勝った' : 'Beat Easy CPU';
      case 'cpu_win_normal':
        return ja ? 'CPU（ふつう）に勝った' : 'Beat Normal CPU';
      case 'cpu_win_hard':
        return ja ? 'CPU（つよい）に勝った' : 'Beat Hard CPU';
      case 'cpu_win_oni':
        return ja ? 'CPU（おに）に勝った' : 'Beat Oni CPU';
      case 'quiz_perfect':
        return ja ? '5問以上のクイズで全問正解した' : 'Answered 5+ quizzes with 100% accuracy';
      case 'fast_reflex':
        return ja ? '5問以上で平均1.5秒未満の反応速度だった' : 'Averaged under 1.5s reaction on 5+ quizzes';
      case 'training_10':
        return ja ? '一人特訓モードを10回完了した' : 'Completed solo training 10 times';
      default:
        return '';
    }
  }

  // 🧠 CPU段位・一人特訓モード（認知トレーニング）
  String get cpuOni => ja ? '👹 おに' : '👹 Oni';
  String get cpuGod => ja ? '⚡ かみ' : '⚡ God';
  String get cpuUltimate => ja ? '🌌 さいきょう' : '🌌 ULTIMATE';
  String ultimateLockedHint(int wins) => ja
      ? 'かみに${wins}回勝利で開放'
      : 'Beat God $wins times to unlock';
  String godLockedHint(int rating) => ja
      ? 'かみモードはレート$rating以上で開放'
      : 'Unlocked at rate $rating';
  String get cpuRankLabel => ja ? 'CPU段位' : 'CPU Rank';
  String get cpuRatingLabel => ja ? 'レーティング' : 'Rating';
  String oniLockedHint(int rating) => ja
      ? 'レーティング$rating以上で解禁'
      : 'Unlocks at rating $rating+';
  String cpuRatingDelta(int delta) =>
      delta >= 0 ? '+$delta' : '$delta';

  String get soloTrainingTitle => ja ? '🧠 一人特訓モード' : '🧠 Solo Training';
  String get soloTrainingDesc => ja
      ? '対戦相手なし。顔と名前のペア当てで、自分のペースで記憶力を鍛えます。'
      : 'No opponent — match faces to names and train your memory at your own pace!';
  String get soloTrainingStart => ja ? '特訓スタート！' : 'Start Training!';
  String get cognitiveInfoButton => ja ? '？ 認知トレーニングについて' : '？ About Cognitive Training';

  // 📊 トレーニングレポート画面
  String get trainingReportTitle => ja ? '📊 トレーニングレポート' : '📊 Training Report';
  String get trainingReportIntro => ja
      ? 'おつかれさま！今回の記録はこちら👇'
      : "Nice work! Here's how you did 👇";
  String get cardsNamedLabel => ja ? 'おぼえた人数' : 'People memorized';
  String get quizAccuracyLabel => ja ? '一致成功率' : 'Match accuracy';
  String get avgReactionLabel => ja ? '平均判断時間' : 'Avg. decision time';
  String get bestStreakLabel => ja ? '最大連続ペア' : 'Best pair streak';
  String get playAgainTraining => ja ? 'もう一度特訓する' : 'Train Again';

  // 認知傾向コメント（診断ではなく、あくまで励ましのフィードバック）
  String get skillWorkingMemory => ja ? '🧠 作業記憶' : '🧠 Working Memory';
  String get skillAttention => ja ? '👀 選択的注意' : '👀 Selective Attention';
  String get skillSpeed => ja ? '⚡ 処理速度' : '⚡ Processing Speed';
  String skillCommentGood(String skill) => ja
      ? '$skillはとても好調でした！このまま続けてみよう。'
      : '$skill was on fire today! Keep it up.';
  String skillCommentOk(String skill) => ja
      ? '$skillは伸びしろあり。くり返し遊ぶとコツがつかめてくるよ。'
      : "$skill has room to grow — practice tends to help.";

  // 🧠 認知トレーニングについて（説明画面）
  String get cognitiveInfoTitle => ja ? '🧠 認知トレーニングについて' : '🧠 About Cognitive Training';
  String get cognitiveInfoIntro => ja
      ? '一人特訓モードやCPU対戦は、記憶・注意・反応速度を使うゲーム要素を通じて、楽しみながら頭を使う時間を提供することを目指しています。以下はゲームに含まれる要素と、関連するとされる一般的な研究分野の紹介です。'
      : 'Solo Training and CPU battles are designed to give you a fun way to exercise memory, attention, and reaction speed. Below is a general overview of the cognitive areas these game mechanics relate to.';
  String get cognitiveMemoryTitle => ja ? '作業記憶（ワーキングメモリ）' : 'Working Memory';
  String get cognitiveMemoryBody => ja
      ? 'おぼえタイムで顔と名前の組み合わせを一時的に覚え、カードが裏返ったあとに思い出して一致させる課題は、ワーキングメモリを使う課題の一種と考えられています。n-back課題を用いたトレーニング研究（Jaeggiら, 2008年など）では、くり返しの記憶課題によって短期的な課題成績が向上したことが報告されています。'
      : 'Holding face-name pairings in mind during the memorize phase, then recalling them once the cards flip over, resembles a working-memory task. Training studies using n-back tasks (e.g. Jaeggi et al., 2008) have reported short-term improvements in related memory task performance.';
  String get cognitiveAttentionTitle => ja ? '選択的注意' : 'Selective Attention';
  String get cognitiveAttentionBody => ja
      ? '似た名前カードが並ぶ盤面から正しいペアの位置を選び出す作業は、まぎらわしい情報の中から必要な情報を選び取る「選択的注意」に関わる要素を含むとされています。'
      : 'Picking the right pair out of a board full of similar name cards involves selective attention — filtering the relevant information from distractors.';
  String get cognitiveSpeedTitle => ja ? '処理速度' : 'Processing Speed';
  String get cognitiveSpeedBody => ja
      ? '少ない手数・短い時間でのクリアを目指してすばやく判断する場面は、「処理速度」を使う場面です。処理速度は加齢とともに変化しやすいとされ、日常的に使う機会を持つことの意義が一般的に指摘されています。'
      : 'Aiming to clear the board in fewer moves and less time calls on processing speed — the ability to perceive and decide quickly. Processing speed is known to change with age, and staying practiced is commonly cited as worthwhile.';
  String get cognitiveExecutiveTitle => ja ? '実行機能' : 'Executive Function';
  String get cognitiveExecutiveBody => ja
      ? '覚える→カードの位置を追う→思い出して選ぶ、という一連の切り替えは、複数の認知プロセスを制御する「実行機能」に関連するとされています。'
      : 'Switching between memorizing, tracking card positions, and recalling to choose draws on executive function — the set of processes that coordinate other cognitive tasks.';
  String get cognitiveDisclaimer => ja
      ? '※本アプリは医療機器・治療プログラムではなく、認知症等の予防・治療効果を保証するものではありません。効果の感じ方には個人差があります。健康に関するご不安がある場合は医療専門家にご相談ください。'
      : '※ This app is not a medical device or treatment program and does not guarantee any preventive or therapeutic effect for dementia or other conditions. Individual results vary. Please consult a healthcare professional with any health concerns.';

  // 🏷️ 顔と名前の神経衰弱（ペアさがし）
  String get cpuMatchTitle => ja ? '🤖 CPUと神経衰弱' : '🤖 Match vs CPU';
  String get memorizePrompt =>
      ja ? 'おぼえタイム！顔と名前をおぼえよう' : 'Memorize the faces & names!';
  String get memorizeDone => ja ? 'おぼえた！スタート →' : "Got it! Start →";
  String get attemptsLabel => ja ? '手数' : 'Moves';
  String get hobbyQuizPrompt =>
      ja ? '🎨 ボーナス！プロフィールクイズ' : '🎨 Bonus! Profile quiz';
  String hobbyQuizQuestion(String name) =>
      ja ? '$nameの趣味は？' : "What is $name's hobby?";
  String get matchWin => ja ? '🏆 あなたの勝ち！' : '🏆 You win!';
  /// 🤖 CPU戦の負け。**CPU戦の結果画面でしか使わないこと**。
  /// オンライン対戦は相手が人間なので [matchLoseBy] を使う。
  String get matchLose => ja ? '🤖 CPUの勝ち…' : '🤖 CPU wins…';
  /// 対人戦の負け。相手の名前で表示する。
  ///
  /// ⚠️ 以前はオンライン対戦の負けにも [matchLose] を流用していて、
  /// 人と対戦したのに「🤖 CPUの勝ち…」と出ていた。
  String matchLoseBy(String name) =>
      ja ? '😢 $name の勝ち…' : '😢 $name wins…';
  String get matchDraw => ja ? '🤝 ひきわけ！' : '🤝 Draw!';
  String get pairsUnit => ja ? 'ペア' : 'pairs';
  String get resultTitle => ja ? 'けっか' : 'Result';
  String get playAgain => ja ? 'もう一回あそぶ' : 'Play Again';
  String get levelLabel => ja ? 'レベル' : 'Level';
  String levelDesc(int pairs) =>
      ja ? '$pairsペア（${pairs * 2}枚）' : '$pairs pairs (${pairs * 2} cards)';

  // 📚 記憶術（名前の覚え方）
  String get memoryTipsTitle => ja ? '📚 名前の覚え方' : '📚 How to Remember Names';
  String get memoryTipsDone => ja ? 'とじる' : 'Close';
  String get memoryTipsButton =>
      ja ? '📚 名前の覚え方を読む' : '📚 Read: How to Remember Names';
  String get memoryTipsHeader => ja ? '💡 名前おぼえのコツ' : '💡 Name-memory tip';
  String get memoryTipsMore => ja ? 'タップで全文を読む' : 'Tap to read more';
  String get mnemonicTrainingButton =>
      ja ? '📚 記憶術トレーニング' : '📚 Mnemonic Training';
  String get mnemonicTrainingDesc => ja
      ? 'タグ付け法を案内付きで練習しながらペアを探します。'
      : 'Guided tagging practice built into the matching game!';
  String get mnemonicGuideStep1 => ja
      ? '💡 ① 顔の特徴を一言のタグにする（例：眉が太い）'
      : '💡 ① Tag each face with one feature (e.g. "thick brows")';
  String get mnemonicGuideStep2 => ja
      ? '💡 ② タグと名前を連想でつなぐ（太い眉→強そう→高橋さん）'
      : '💡 ② Link tag → name with a mini story';
  String get modeSelectTitle => ja ? 'あそぶモードをえらぶ' : 'Choose a Mode';
  String get playButton => ja ? 'トレーニングする' : 'Start Training';
  String get levelHint => ja
      ? 'おぼえる人数がふえるほどハイスコアのチャンス！'
      : 'More people to memorize = bigger score potential!';
  String get cpuMatchDesc => ja
      ? '交代でカードをめくって、とったペアの数で勝負！勝つと段位レーティングが上がるよ。'
      : 'Take turns flipping cards — most pairs wins! Victories raise your rating.';

  // 🎉 ローカル対戦（1台でみんなで）
  String get localMatchTitle => ja ? '🎉 みんなで対戦' : '🎉 Party Match';
  String get localMatchDesc => ja
      ? '1台のスマホをまわして2〜4人で神経衰弱バトル！ペアをとったらもう1回めくれるよ。'
      : 'Pass one phone around — 2-4 players take turns! Match a pair to go again.';
  String localWinner(String name) =>
      ja ? '🏆 $name の勝ち！' : '🏆 $name wins!';

  // 🌐 オンライン同時レース
  String get onlineMatchTitle => ja ? '🌐 オンライン対戦' : '🌐 Online Match';
  String get onlineRaceDesc => ja
      ? '世界のだれかと同じ盤面を同時にプレイ！少ない手数（同じならタイム）でクリアした方の勝ち。'
      : 'Race someone on the identical board! Fewer moves wins (time breaks ties).';
  String get friendMatchTitle => ja ? '友だちと対戦' : 'Play with a friend';
  String get createRoomButton =>
      ja ? '合言葉をつくって招待する' : 'Create a room code';
  String get enterCodeLabel => ja ? '合言葉（6文字）' : 'Room code (6 chars)';
  String get joinButton => ja ? '入室' : 'Join';
  String get shareCodePrompt => ja
      ? 'この合言葉を友だちに送ってね（入力してもらうと対戦開始）'
      : 'Send this code to your friend to start the match';
  String shareCodeText(String code) => ja
      ? 'なまえがおで対戦しよう！🏷️\nアプリのオンライン対戦で合言葉「$code」を入力してね！'
      : 'Race me in Name Call! 🏷️\nEnter room code "$code" in Online Match!';
  String get roomNotFound => ja
      ? 'その合言葉のへやが見つかりませんでした'
      : 'No room found with that code';
  String waitingOpponentFinish(String name) => ja
      ? '$name がプレイ中…\nおわるまでちょっと待ってね'
      : '$name is still playing…\nHang tight!';
  String get opponentForfeited => ja ? 'とちゅう離脱' : 'Forfeited';
  String get gameStartLabel => ja ? 'ゲームスタート！' : 'Start Game!';

  // ─────────── 🌐 オンラインの遊び方えらび（ロビー） ───────────
  /// フレンドマッチ＝1台で遊ぶときと同じルールを、部屋ごしに相手へ配る。
  String get friendMatchDesc => ja
      ? '1台で遊ぶときと同じルールで対戦できます。人数はあなたが決めて、相手にもそのまま配られます。'
      : 'Same rules as playing on one phone. You pick how many faces; your friend gets the same setup.';
  String get onlinePeopleLabel => ja ? '👥 出てくる人数' : '👥 How many faces';
  String get onlinePeopleHint => ja
      ? 'ここで決めた人数が、そのまま相手の画面にも出ます。'
      : 'Your friend plays with exactly this many faces.';
  String onlineRoomRule(int people) => ja
      ? 'この部屋のルール：出たとき命名／$people人／4択'
      : 'Room rules: name-as-you-go / $people faces / 4 choices';
  String get randomMatchPeopleNote => ja
      ? '※ランダムマッチは、同じ人数を選んだ人どうしが当たります。'
      : 'Random match pairs you with someone who picked the same number.';

  // 🏆 ランクマッチ
  String get rankMatchTitle => ja ? '🏆 ランクマッチ' : '🏆 Ranked Match';
  String get rankMatchDesc => ja
      ? '知らない人と、通話なしで遊べる早押し勝負。8人の名前をおぼえて、同じ問題に先に正解した方がカードを取ります。勝つとランクが上がります。'
      : 'A buzzer duel with a stranger — no voice chat needed. Memorize 8 people, then race to answer the same question first. Winning raises your rank.';
  String get rankMatchButton => ja ? 'ランクマッチをはじめる' : 'Start ranked match';
  String get rankMatchTitleShort => ja ? 'ランク' : 'Ranked';
  String get rankMatchHomeHint => ja
      ? '知らない人と 8人ぶんの早押し。通話はいりません。'
      : 'Buzz against a stranger over 8 faces. No voice chat.';
  String get rankSeeRanking => ja ? '🏅 ランキングを見る' : '🏅 View ranking';
  String rankMemorizeHeader(int people) => ja
      ? '$people人の名前をおぼえよう'
      : 'Memorize these $people people';
  String get rankMemorizeHint => ja
      ? '声に出して読むと残りやすいと言われています。'
      : 'Saying each name out loud is said to help.';
  String get rankBuzzTitle => ja ? '⚡ 早押し' : '⚡ Buzz in';
  String rankQuestionOf(int i, int n) =>
      ja ? '第$i問 / $n問' : 'Q$i of $n';
  String get rankTook => ja ? '⚡ 先取！' : '⚡ You got it!';
  String get rankTaken => ja ? '😢 とられた…' : '😢 Too slow…';
  String get rankMissed => ja ? '❌ ちがった' : '❌ Wrong';
  String get rankNobody => ja ? 'だれも取れなかった' : 'Nobody got it';
  String get rankWaitingJudge => ja ? '判定中…' : 'Judging…';
  String get rankReadyWait => ja ? '相手を待っています…' : 'Waiting for your opponent…';
  String get rankReadyWaitHint => ja
      ? 'ふたり同時に第1問がはじまります。'
      : 'The first question starts for both of you at once.';
  String get rankMyCards => ja ? 'あなた' : 'You';
  String rankRatingLine(int rating) =>
      ja ? 'ランクポイント $rating' : 'Rank points $rating';

  // 🔁 ターン制対戦（記憶術トレーニング）
  String get turnPairsTitle => ja ? '🔁 ターン制対戦' : '🔁 Turn-based Match';
  String get turnPairsDesc => ja
      ? '記憶術トレーニングの盤面を、オンラインの相手と交互にめくる対戦。ペアが当たればもう一度めくれます。同時に急がされないので、タグ付けをじっくり試せます。'
      : 'Take turns flipping the mnemonic-training board against someone online. Match a pair and you go again — no rush, so you can actually practice tagging.';
  String get turnPairsButton => ja ? 'ターン制で対戦する' : 'Play turn-based';
  String get turnYours => ja ? '🟢 あなたの番' : '🟢 Your turn';
  String turnTheirs(String name) => ja ? '⏳ $name の番' : '⏳ $name\'s turn';
  String get turnWaitOpponent => ja ? '相手がめくっています…' : 'They are flipping…';
  String get turnGoAgain => ja ? 'ペア成立！もう一度めくれます' : 'Pair! Flip again';
  String get turnOpponentLeft =>
      ja ? '相手がいなくなりました' : 'Your opponent left';

  // 📣 メインモード「なまえがお」
  String get nameCallTitle => ja ? '📣 なまえがお' : '📣 Name Call';
  String get namingDecide => ja ? 'これにする！' : 'Name it!';
  // 📖 名簿を見て覚える画面（おまかせ命名の確認＋命名中の暗記）
  String get rosterReviewTitle =>
      ja ? '📖 名簿をおぼえよう' : '📖 Memorize the roster';
  String rosterReviewHint(int named, int total) => ja
      ? '$total人中 $named人 に名前がついています。覚えたら封印します。'
      : '$named of $total have names. They get sealed once you start.';
  String get rosterReviewStart =>
      ja ? 'おぼえた！はじめる' : "Got it — let's start";
  String get rosterReviewBack => ja ? '命名にもどる' : 'Back to naming';
  /// 未入力のまま進んだとき、自動でついた名前を知らせる
  String namedAs(String name) => ja ? '「$name」と名づけた！' : 'Named "$name"!';
  /// 出たとき命名で、名前を決めたあと『覚えた』と確認して次へ進むボタン
  /// 出たとき命名: 声に出して名前をつけた（アプリは名前を知らない）
  String get namedItAloud => ja ? '名前をつけた！' : 'We named it!';
  String get gachaNameIt => ja ? 'おまかせで名前をつける' : 'Let the app name it';
  String get gachaNamedHint => ja
      ? 'この名前で覚えてね。つぎに出てきたら呼んであげよう'
      : 'Remember this name — call it out when it appears again';
  String get shopTabLabel => ja ? 'ショップ' : 'Shop';
  String get memorizedNext => ja ? '暗記した！つぎへ' : 'Memorized — next!';
  String get namingMemorize => ja ? 'ここまでの名簿を見る' : 'Review names so far';

  // ⚠️ 表示名は「なまえコール」で統一する。
  //    以前ここだけ「なづけコール」で、ホームの導線と画面の見出しが
  //    食い違っていた。
  String get nameCallAsYouGoTitle => ja ? '📣 なまえコール' : '📣 Name-as-you-go';

  // 出たとき命名: 初登場はその場で命名（無得点）、再登場で想起して獲得
  String get newComer => ja ? '✨ はじめまして！名前をつけてね' : '✨ New face! Give a name';
  String get namedSoFar => ja ? '名前をつけた' : 'Named';
  String get asYouGoHint => ja
      ? '💡 はじめて出た子には名前をつけ、もう一度出てきたら思い出して答えよう！'
      : '💡 Name each new face — when it appears again, recall the name!';
  String get rulePreName => ja ? 'まとめて命名' : 'Name first';
  String get ruleAsYouGo => ja ? '出たとき命名' : 'Name as you go';
  String get autoNamesLabel => ja
      ? '名前はおまかせ（入力しない）'
      : 'Auto-name them (no typing)';
  String get ruleLabel => ja ? '命名ルール' : 'Naming rule';
  /// 「名前をつけた！」で進んだ人の表示。アプリは名前を知らないので伏せる。
  /// （ここに内部の識別子を出すと「言ってない名前」が出て混乱する）
  /// アプリが名前を決める方式（CPU戦・オンライン）の見出し。
  /// 「名前をつけてね」ではなく「この人の名前はこれ」だと伝える。
  String get newComerNamed => ja ? '👤 この人の名前は…' : '👤 This person is…';
  String get newComerNamedHint => ja
      ? 'この名前をおぼえてね。もう一度この顔が出てきたら、4つの中からえらぶよ！'
      : 'Remember this name. When this face returns, pick it from four choices!';
  String get homeMusic => ja ? 'ホームの曲' : 'Home music';
  String get homeMusicDesc => ja
      ? 'ホーム画面と試合前に流れる曲です。ショップで買った曲から選べます。'
      : 'Plays on the home screen. Pick from music you own in the shop.';
  // 📮 フィードバック
  String get feedbackButton =>
      ja ? 'ご意見・不具合を送る' : 'Send feedback';
  String get feedbackSubject =>
      ja ? '【なまえがお】ご意見・不具合の報告' : '[Namaegao] Feedback / bug report';
  String get feedbackBody => ja
      ? '''※わかる範囲で大丈夫です。書ける項目だけ埋めて送ってください。

■ どの画面で
■ 何をしたら
■ どうなった（期待した動きとの違い）

■ 端末（例: Pixel 8 / Android 15）

--------------------
'''
      : '''Fill in whatever you can.

- Which screen
- What you did
- What happened (vs. what you expected)
- Device

--------------------
''';
  String get feedbackNoMailApp => ja
      ? 'メールアプリを開けませんでした。お手数ですが、こちらの宛先へ送ってください。'
      : 'Could not open a mail app. Please write to this address instead.';
  String get secretNamePlaceholder => ja ? '🗣 みんなの名前' : '🗣 Your name';
  // 🏋️ 名刺覚えタブの初回説明。
  //    ここは仕事で人の名前を覚えたい大人が使う場所なので、
  //    なまえがお側のひらがな中心の文体ではなく漢字混じりの文にする。
  String get trainingIntroTitle =>
      ja ? 'ここは一人で練習する場所です' : 'This is your solo practice room!';
  String get trainingIntroBody => ja
      ? '''なまえがおが皆で遊ぶゲームなのに対して、
ここは一人で腕を上げるための場所です。

🖇 線結び … 顔から名前へ指で線を引いて結びます。全員結んだ時点で答え合わせです。

🧠 思い出し訓練 … 名刺を持った相手が自己紹介をします。少し時間を置いてから「誰だったか」を答えます。

🔁 間違えた相手は翌日また登場します。間隔を空けて繰り返すほど定着します。'''
      : '''Name Call is the game you play with friends.
This tab is where you get stronger on your own.

🖇 Line Match — drag your finger from each face to its name, then check your answers!

🧠 Recall Training — people introduce themselves with a business card. After a short break, you try to remember who was who.

🔁 Anyone you got wrong comes back the next day. Repetition is what makes it stick!''';
  String get trainingIntroOk => ja ? '始める' : 'Got it!';
  // 🔇 BGMのON/OFF
  String get bgmEnabledLabel => ja ? '🎵 音楽を鳴らす' : '🎵 Play music';
  String get bgmEnabledHint => ja
      ? 'OFFにすると音楽が止まります（効果音はそのまま）'
      : 'Turning this off stops the music (sound effects stay on)';
  // 📇 実物の名刺＋顔写真での特訓（モバイル限定）
  String get realCardTrainingTitle =>
      ja ? '📇 本物の名刺で特訓する' : '📇 Train with real business cards';
  String get realCardTrainingDesc => ja
      ? 'もらった名刺と顔写真を登録して、そのまま思い出しクイズにできます。（スマホアプリ限定）'
      : 'Register the cards you received with a photo of the person, then quiz yourself. (Mobile app only)'
      ;
  String get realCardTrainingButton =>
      ja ? '名刺・顔写真を登録する' : 'Register cards & faces';
  String get tabNameCall => ja ? 'なまえがお' : 'Name Call';
  String get tabPairs => ja ? 'ペアさがし' : 'Pair Hunt';
  String get tabTraining => ja ? '名刺覚え' : 'Biz Training';
  String get tabMyPage => ja ? 'マイページ' : 'My Page';
  String get nameCallCatch => ja
      ? 'みんなに名前をつけて、あとで思い出す。顔と名前をむすびつけて覚えよう！'
      : 'Name everyone, then recall each one. Link every face to its name!';
  String get nameCallRule => ja
      ? '① はじめに全員の顔を見て、順番にすきな名前をつける\n'
          '② つけた名前は「名簿」にひみつで記録（終了までみられない）\n'
          '③ 本編ではランダムにカードが登場\n'
          '④ 名前を思い出せたら1枚ゲット！（2枚同時のときは両方言えたら2枚）\n'
          '⑤ 思い出せなかったカードは 取れずに流れます。獲得枚数がいちばん多い人の勝ち！'
      : '① Look at every face and give each one a name\n'
          '② Names are sealed in a hidden roster until the end\n'
          '③ Two random cards appear each round\n'
          '④ Recall both names = sweep both cards! One name = one card\n'
          '⑤ Cards you cannot recall simply pass by. Most cards wins!';
  String namingProgress(int n, int total) =>
      ja ? '$n人目 / $total人：この子に名前をつけよう！' : 'Person $n of $total: give them a name!';
  String namingTurnPlayer(String p) =>
      ja ? '$p が名づけ中' : "$p's turn to name";
  String get nameFieldLabel => ja ? 'なまえ（8文字まで）' : 'Name (max 8 chars)';
  String get namingNext => ja ? 'つけた！' : 'Done!';
  String get namingHint => ja
      ? '💡 つけた名前は名簿にひみつで記録されるよ。あとで2枚ずつ出てくるから、顔と名前をむすびつけて覚えてね！'
      : '💡 Names are sealed in a secret roster. Cards come back two at a time — link each face to its name!';
  String get rosterSealed => ja
      ? '名簿を封印！\nここからは記憶だけがたより…'
      : 'Roster sealed!\nFrom here on, memory is all you have…';
  String get whoIsThis => ja ? 'この子のなまえは？' : 'What did you name them?';
  String get ryoudori => ja ? '🎉 2枚ゲット！' : '🎉 Both cards!';
  String get katadori => ja ? '✨ 1枚ゲット！' : '✨ Got one card!';
  String get missAll => ja ? '💦 ざんねん…どちらも取れなかった' : '💦 Missed — neither card';
  String get rosterReveal => ja ? '📖 名簿公開！' : '📖 Roster revealed!';
  String get rosterRevealDesc => ja
      ? 'きみがつけた名前はこちら。おぼえてた？'
      : 'Here are the names you gave. How did you do?';
  String get ryoudoriLabel => ja ? '2枚ゲット' : 'Both-card wins';
  String get cardsWonLabel => ja ? 'かくとく' : 'Cards';
  String get cardsUnit => ja ? '枚' : 'cards';
  String get toResultButton => ja ? 'けっかを見る →' : 'See results →';
  String get nameCallLocalButton => ja ? '🎉 みんなで（1台）' : '🎉 Party (1 phone)';
  // 🤖 CPU対戦（ひとりでも勝ち負けのある遊びにする）
  String get nameCallCpuButton => ja ? '🤖 CPUとたいせん' : '🤖 Play vs CPU';
  String get nameCallCpuHint => ja
      ? 'ひとりで遊ぶモード。顔が出たら4つの中から名前をえらぶ。CPUより早く正解できたらカードをもらえるよ'
      : 'Solo mode. Pick the right name from four choices — beat the CPU to win the card.';
  String get cpuPickTitle => ja ? '🤖 だれと たいせんする？' : '🤖 Choose your rival';
  String get cpuPickHint => ja
      ? 'つよい相手ほど もらえるコインが多い！\nコインを貯めてキャラや音楽を変えよう🪙'
      : 'Tougher rivals pay more coins!\nSave up to unlock characters and music 🪙';
  String cpuLevelName(dynamic lv) {
    // CpuLevel を直接参照すると循環importになるので name で判定する
    switch ('$lv'.split('.').last) {
      case 'easy':
        return ja ? 'かんたん' : 'Easy';
      case 'hard':
        return ja ? 'つよい' : 'Hard';
      case 'oni':
        return ja ? '鬼' : 'Oni';
      case 'god':
        return ja ? '神' : 'God';
      case 'ultimate':
        return ja ? '最強' : 'ULTIMATE';
      default:
        return ja ? 'ふつう' : 'Normal';
    }
  }

  String cpuLevelReward(int coins) => ja ? '勝って🪙$coins' : 'Win 🪙$coins';
  /// 難易度の中身（まとめて覚える人数と、1問の持ち時間）。
  String cpuLevelDetail(int groupSize, int seconds) => ja
      ? '$groupSize人まとめて覚える / $seconds秒で答える'
      : 'Memorize $groupSize at a time / $seconds s to answer';
  String get cpuEntryJoin => ja ? '参戦！' : 'JOINS THE BATTLE!';
  String get cpuEntryTapToSkip => ja ? 'タップでとばす' : 'Tap to skip';
  String get cpuWinTitle => ja ? '🏆 CPUに勝った！' : '🏆 You beat the CPU!';
  String get cpuLoseTitle => ja ? '😢 CPUに負けた…' : '😢 The CPU won…';
  String cpuBonusCoins(int n) =>
      ja ? '難易度ボーナス 🪙+$n' : 'Difficulty bonus 🪙+$n';
  // 🪙 CPU戦のコイン内訳（何で稼げたのかを分けて見せる）
  String cpuCorrectCoins(int correct, int coins) =>
      ja ? '思い出せた $correct問 🪙+$coins' : 'Recalled $correct 🪙+$coins';
  String cpuPerfectCoins(int coins) =>
      ja ? '全問正解ボーナス 🪙+$coins' : 'Perfect bonus 🪙+$coins';
  String cpuWinCoins(int coins) =>
      ja ? '勝利ボーナス 🪙+$coins' : 'Win bonus 🪙+$coins';
  /// コインを貯める動機づけの謳い文句（結果画面などで出す）
  String get saveCoinsPitch => ja
      ? 'コインを貯めて、キャラや音楽を変えよう！🪙'
      : 'Save up coins to unlock characters and music! 🪙';
  String get nameCallOnlineButton => ja ? 'オンライン' : 'Online';

  // 呼んで判定（原作のボードゲームと同じ流れ）
  String get refereePrompt =>
      ja ? 'この子の名前を一斉にコール！' : 'Call out this name together!';
  String refereePromptCard(int n) =>
      ja ? '$n枚目：一斉にコール！' : 'Card $n: call it out!';
  String get refereeHint => ja
      ? '早く正しく呼べた人のボタンを押そう'
      : 'Tap the button of whoever called it first & correctly';
  /// ひとりで遊ぶときは「P1がとった」だと不自然なので言い方を変える
  String get soloRecallPrompt =>
      ja ? 'この子の名前、言える？' : 'Can you name this one?';
  String get soloRecallHint => ja
      ? '声に出して言ってから、下のボタンで自己申告しよう'
      : 'Say it out loud, then judge yourself below';
  String get soloGot => ja ? '✅ 言えた！' : '✅ I got it!';
  String playerGot(String p) => ja ? '$p が正解！' : '$p got it!';
  String get nobodyKnew => ja ? 'だれもわからなかった…' : 'Nobody knew…';
  /// 原作どおり、思い出せなかったカードは新しい名前をつけ直して山札に戻る
  String get renamedAfterMiss => ja
      ? '思い出せなかったので、新しい名前をつけよう'
      : 'Nobody recalled it — give it a new name';

  // 人数（カード枚数）
  /// 「6人」だけでは何の人数か伝わらない（プレイ人数と紛らわしい）ので、
  /// 出てくるキャラの数だと分かる書き方にする。
  String peopleCountLabel(int n) => ja ? '$n キャラ' : '$n chars';
  String peopleCountValue(int n) => ja ? '$n人' : '$n';
  // 🎴 1人あたりの札の枚数
  String get copiesTitle =>
      ja ? '🎴 1人あたりの枚数' : '🎴 Cards per character';
  String copiesValue(int n) => ja ? '$n枚' : '$n';
  String copiesHint(int total, int recalls) => ja
      ? '全部で$total枚。1人につき$recalls回 名前を答えます（多いほど覚えやすい）'
      : '$total cards total — you answer each person $recalls time(s)';
  /// おおよその所要時間。totalCards = people × copiesPerPerson
  String estimatedTime(int people, int copies) {
    final total = people * copies;
    final minutes = (total * 4 / 60).ceil();
    if (ja) {
      return '⏱ 約$minutes分（$people人×$copies枚 = ${total}枚）';
    } else {
      return '⏱ ~$minutes min ($people × $copies = $total cards)';
    }
  }
  String get peopleCountTitle =>
      ja ? '👥 出てくるキャラの数' : '👥 How many characters appear';
  String peopleCountHint(int n) => ja
      ? '$n人ぶんの顔と名前をおぼえます（多いほどむずかしい）'
      : 'You will learn $n faces and names (more = harder)';

  // 2枚同時オプション
  String get doubleCardLabel => ja ? '2枚同時に出す' : 'Two cards at once';
  String get doubleCardHint => ja
      ? 'ONにすると2枚同時に出現。両方言えたら2枚ゲット！'
      : 'Two cards appear at once. Recall both for a double take!';

  // 📸 自分の名簿（もらった名刺・人物メモ）
  // 🧑‍🎨 名前は「顔メモ」で統一する。
  //    以前は入口が「顔メモ」なのに開くと「自分の名簿」と出ていて、
  //    同じ機能が2つあるように見えていた。
  //    用途（会社・学校で会った人）は、見出しのカッコで補う。
  String get tabMemorize => ja ? '顔メモ' : 'Face Notes';
  String get customTitle => ja
      ? '🧑‍🎨 顔メモ（会社・学校の人）'
      : '🧑‍🎨 Face Notes (work & school)';
  String get customDesc => ja
      ? 'もらった名刺と顔写真を登録して、そのまま覚える練習や対戦に使えます。'
          '名前・読み方・ニックネーム・性別・誕生日・会社名・役職・職業・出身・住所・'
          '自分との関係・電話番号・メール・X・Instagram・LINE ID・Facebook・自由記入メモの18項目。'
          '名前だけでも登録でき、登録した人をタップすればいつでも見返して書き足せます。'
          '入力した内容は端末内にのみ保存され、外部へは送信されません。'
      : 'Add photos & names of people you meet, then study or play with them. '
          'You can also keep company, birthday, hometown, socials and free notes. '
          'Tap a person to view or edit later.';
  String get customMobileOnly => ja
      ? '''📇 この「顔メモ」の写真登録は、Google Play版でご利用いただけます。

もらった名刺と顔写真を登録して、名前・読み方・ニックネーム・性別・誕生日・会社名・役職・職業・出身・住所・自分との関係・電話番号・メール・X・Instagram・LINE ID・Facebook・自由記入メモの18項目を残せます。名刺を撮ると会社名や氏名を自動で読み取り、空欄だけ埋めます。

登録した名簿は、そのまま思い出し訓練やなまえがおの出題に使えます。

写真の保存を端末内で行う機能のため、ブラウザ版では動きません。入力した内容が外部へ送信されることはありません。'''
      : '''📇 My Roster is available on the Google Play version.

Register the business cards you receive along with a face photo, and keep 18 fields — name, reading, nickname, gender, birthday, company, title, occupation, hometown, address, relationship, phone, email, X, Instagram, LINE ID, Facebook and free notes.

It needs on-device photo storage, so it does not run in the browser. Nothing you enter is ever sent anywhere.''';
  // ⚠️ 「写真と名前を追加」だと、押す前に写真が要ると思われる。
  //    実際には似顔絵だけでも登録でき、職場の人は写真を撮りにくいので
  //    そちらのほうが出番が多い。ボタンの字で両方あることを見せる。
  String get customAddButton => ja ? '＋ 顔をつくる / 写真' : '+ Add a face';
  String get customEmpty => ja
      ? 'まだ登録がありません。「＋」から追加してみよう！'
      : 'No people yet. Tap "+" to add one!';
  String get customPickPhoto => ja ? '写真をえらぶ' : 'Choose photo';
  String get customTakePhoto => ja ? 'カメラでとる' : 'Take photo';
  String get customNameField => ja ? 'なまえ' : 'Name';
  String get customSave => ja ? '登録する' : 'Save';
  String get customDelete => ja ? '削除' : 'Delete';
  String customDeleteConfirm(String name) =>
      ja ? '「$name」を削除しますか？' : 'Delete "$name"?';
  String get memorizeStudyButton => ja ? '📖 おぼえる（学習）' : '📖 Study';
  String get memorizeQuizButton => ja ? '✏️ かくにんテスト' : '✏️ Quiz';
  String get customBattleButton => ja ? '📣 この名簿で対戦' : '📣 Play with this roster';
  String get needAtLeast => ja
      ? '2人以上登録すると遊べるよ'
      : 'Add at least 2 people to play';
  String get studyTitle => ja ? '📖 おぼえる' : '📖 Study';
  String get studyHint => ja
      ? 'カードをタップすると名前が出るよ。顔と名前をむすびつけて覚えよう！'
      : 'Tap a card to reveal the name. Link each face to its name!';
  String get studyDone => ja ? 'おぼえた！テストへ →' : "Got it! To the quiz →";
  String get quizTitle => ja ? '✏️ かくにんテスト' : '✏️ Quiz';
  String quizScore(int correct, int total) =>
      ja ? '$total問中 $correct問正解！' : '$correct / $total correct!';

  // 🧠 思い出しトレーニング（実際に出会って、時間をおいて思い出す）
  String get recallTitle =>
      ja ? '💼 名刺覚え' : '💼 Card Memory';
  String get recallHubDesc => ja
      ? '実際に人と出会うように顔・名前・出会った場所を覚えて、少し時間をおいてから「この人だれだっけ？」を思い出す特訓。現実で名前が出てこない、をなくそう。'
      : 'Meet people like in real life — link face, name and where you met — then recall "who was that again?" after a pause. Beat the moment names slip your mind.';
  String get recallStart => ja ? '出会いに行く →' : 'Go meet them →';
  String get recallMeetTitle => ja ? '出会う' : 'Meet';
  String get recallMeetHint => ja
      ? '出会った相手です。顔・名前・出会った場所を結び付けて覚えてください。'
      : 'People you just met. Link each face to a name and where you met.';
  String metAt(String where) => ja ? '$where知り合った' : 'You met them $where.';
  String get recallHobbyLabel => ja ? '趣味' : 'Hobby';
  String get recallRemembered => ja ? '覚えた →' : 'Got it →';
  String get recallMeetNext => ja ? '次の人 →' : 'Next person →';
  String get recallGapTitle => ja ? 'しばらく時間が経った…' : 'Some time has passed…';
  String get recallGapSub => ja
      ? 'あの人たちの名前を思い出せますか？'
      : 'Can you recall their names now?';
  String get recallGapButton => ja ? '思い出す →' : 'Try to recall →';
  String get recallWhoTitle => ja ? 'この人は誰でしたか？' : 'Who is this again?';
  String hintMetAt(String where) => ja ? 'ヒント：$where会った相手' : 'Hint: you met them $where';
  String get recallResultTitle => ja ? '思い出しレポート' : 'Recall Report';
  String recallCorrectOf(int correct, int total) =>
      ja ? '$total人中 $correct人を思い出せました' : 'You recalled $correct of $total!';
  String get recallReview => ja ? '復習（顔・名前・場所）' : 'Review (face・name・place)';
  String get recallAgain => ja ? 'もう一度' : 'Again';
  String get recallClose => ja ? '閉じる' : 'Close';
  String get recallEncourageHigh => ja
      ? '完璧です。実際に会っても、すぐ名前が出てくるはずです。'
      : 'Perfect! You’d recall their names in real life, too.';
  String get recallEncourageMid => ja
      ? '良い調子です。出会った場所と結び付けると、さらに思い出しやすくなります。'
      : 'Nice! Tie each face to where you met — it makes recall easier.';
  String get recallEncourageLow => ja
      ? '思い出せなくても問題ありません。繰り返すほど名前は出てくるようになります。'
      : 'It’s OK to forget. The more you repeat, the easier names come back.';
  String get businessCardHello => ja ? 'はじめまして' : 'Nice to meet you';
  String fieldLabel(RecallField f) {
    switch (f) {
      case RecallField.name:
        return ja ? '名前' : 'name';
      case RecallField.company:
        return ja ? '会社名' : 'company';
      case RecallField.title:
        return ja ? '肩書' : 'title';
      case RecallField.phone:
        return ja ? '電話番号' : 'phone number';
      case RecallField.email:
        return ja ? 'メール' : 'email';
    }
  }

  String recallFieldQuestion(String label) =>
      ja ? 'この人の$labelは？' : "What's this person's $label?";
  // 出題項目の選択（とっくんハブ）
  String get recallFieldsTitle =>
      ja ? '🎯 覚える項目（🏷️名前は必須・ほかは自由に追加）' : '🎯 What to memorize (🏷️ name is required, add more freely)';
  // なまえチップ専用の強調ラベル（クイズの設問文には使わないUI表示専用）
  String get nameFieldChipLabel => ja ? '🏷️ 名前' : '🏷️ Name';

  // 🎴 キャラデッキ編集
  String get deckTitle => ja ? '🎴 キャラデッキ' : '🎴 Character Deck';
  String get deckHeadline =>
      ja ? 'ゲームに出てくる顔ぶれを決めよう' : 'Choose who shows up in your games';
  String get deckDesc => ja
      ? 'タップでON／OFF。OFFにしたキャラはなまえがおと名刺覚えに出てこなくなります。買ったキャラや登録した写真は自動でデッキに入ります。'
      : 'Tap to toggle. Characters turned off will not appear in Name Call or Business Training. Purchased characters and your own photos join automatically.';
  String deckActiveCount(int n) => ja ? '✅ 出演中 $n人' : '✅ $n in the deck';
  String get deckTooFew =>
      ja ? '⚠️ 4人以上えらんでね' : '⚠️ Pick at least 4';
  String get deckSelectAll => ja ? 'ぜんいん出す' : 'Select all';
  String get deckSectionBase => ja ? '基本の15人' : 'The original 15';
  String get deckSectionBought => ja ? '🛍 買ったキャラ' : '🛍 Purchased';
  String get deckSectionMine => ja ? '📷 自分で登録した人' : '📷 Your own photos';
  String get deckEmptyBought => ja
      ? 'まだ買ったキャラがいません。ショップでコインと交換できます。'
      : 'No purchased characters yet. Trade coins for them in the shop.';
  String get deckEmptyMine => ja
      ? 'まだ写真を登録していません。職場や学校で会う人の顔を登録すると、その人でゲームができます。'
      : 'No photos yet. Register the faces of people you meet and play with them.';
  String get deckGoShop => ja ? '🛍 ショップへ' : '🛍 Go to shop';
  String get deckGoRoster => ja ? '📷 写真を登録する' : '📷 Register photos';
  String get deckEditButton => ja ? '🎴 キャラデッキを編集' : '🎴 Edit character deck';
  String get tabShop => ja ? 'ショップ' : 'Shop';

  // 🖇 一人特訓（線むすび）
  String get lineMatchTitle => ja ? '🖇 線結び特訓' : '🖇 Line Match';
  String get lineMatchMemorizeTitle =>
      ja ? '記銘タイム' : 'Memorize time!';
  String get lineMatchMemorizeDesc => ja
      ? '顔と名前を組みで覚えます。準備ができたらボタンを押してください。'
      : 'Learn each face with its name. Tap the button when you are ready.';
  String get lineMatchStart => ja ? '覚えた！線結びへ' : 'Got it! Start matching';
  String get lineMatchConnectTitle =>
      ja ? '顔と名前を線で結ぶ' : 'Connect faces to names';
  String get lineMatchConnectDesc => ja
      ? '顔から名前へ指でドラッグします。間違えても引き直せます。'
      : 'Drag from a face to a name. You can redo any line.';
  // ⚔️ ベータ「なまえバトル」
  String get betaBadge => ja ? 'ベータ' : 'BETA';
  String get battleTitle => ja ? '⚔️ なまえバトル' : '⚔️ Name Battle';
  String get battleDesc => ja
      ? '神経衰弱で当てた人が味方に、取り逃した人が敵になります。キャラごとに近距離・遠距離・タワー狙いの能力があり、覚えているほど戦いが有利になります。'
      : 'Everyone you match joins you; everyone you miss fights against you. The more you remember, the easier the battle.';
  String get battleRosterTitle => ja ? '📖 これから出る人たち' : '📖 Who is coming';
  String get battleRosterHint => ja
      ? '顔・名前・役割をひととおり見ておきましょう。'
      : 'Take a look at each face, name and role.';
  String battleAttemptsLeft(int n) =>
      ja ? '🃏 のこり $n 回' : '🃏 $n tries left';
  String battleRecruited(int n, int total) =>
      ja ? '🤝 仲間 $n / $total 人' : '🤝 $n / $total recruited';
  String get battleBriefTitle => ja ? '⚔️ 出陣まえ' : '⚔️ Before the battle';
  String get battleBriefBody => ja
      ? '当てた人が味方、取り逃した人が相手につきます。カードを押すと出撃します（⚡が必要）。'
      : 'Those you matched fight for you; the rest fight against you. Tap a card to deploy (costs ⚡).';
  String get battleMySquad => ja ? '🤝 味方' : '🤝 Your squad';
  String get battleFoeSquad => ja ? '👹 相手' : '👹 Their squad';
  String get battleNobody => ja ? 'いません' : 'Nobody';
  String get battleStart => ja ? '出陣する！' : 'Charge!';
  String get battleCostHint => ja
      ? '⚡ 取った人数が多いほど、出撃できるペースが速くなります。'
      : '⚡ The more people you took, the faster you can deploy.';
  String get battleFoe => ja ? 'あいて' : 'Foe';
  String get battleNoHand => ja
      ? '出せる仲間がいません…（次は1人でも多く当てよう）'
      : 'No one to deploy… try to match more next time.';
  String get battleLose => ja ? '😢 まけ…' : '😢 You lose…';
  String battleTurnOf(String who) =>
      ja ? '$who のばん：2まいめくって、同じ人をそろえよう' : "$who's turn — flip two cards";
  String get battleBrief2p => ja
      ? 'とった人が、そのまま自分の戦力になります。バトルは縦の戦場で同時操作。スマホを挟んで向かい合い、手前がP1・奥がP2の持ち場です（P2側は上下さかさまに出ます）。'
      : "Everyone you took fights for you. The battlefield runs top-to-bottom: sit facing each other with the phone between you — P1 owns the near end, P2 the far end (their side is upside-down).";
  // 🃏 1台で2人で遊ぶときの、カードの作りえらび
  String get battleStylePickTitle =>
      ja ? 'カードの作りをえらぶ' : 'Choose the card style';
  String get battleStyleSplit =>
      ja ? '🃏 顔カード＋名前カード' : '🃏 Face card + name card';
  String get battleStyleSplitDesc => ja
      ? '顔だけの札と、名前だけの札をそろえます。顔と名前を結びつけて覚えていないと取れません。（いままでと同じ）'
      : 'Match a face-only card with a name-only card. You need the link to take it. (as before)';
  String get battleStyleCombined =>
      ja ? '🂡 1枚に顔と名前（トランプ式）' : '🂡 One card, face + name';
  String get battleStyleCombinedDesc => ja
      ? '1枚に顔と名前がいっしょに書いてある札を、2枚そろえます。見た目でそろえられるのでやさしめです。'
      : 'Match two identical cards that each show a face and a name. Easier — you can match on looks.';

  String get battleStyleFaceOnly => ja ? '😀 顔だけ' : '😀 Faces only';
  String get battleStyleFaceOnlyDesc => ja
      ? '顔だけの札を2枚そろえます。名前は出ないので、顔の見分けに専念できます。いちばん素朴で、いちばんやさしい遊び方です。'
      : 'Match two identical face cards. No names — just telling faces apart. The simplest and easiest way to play.';

  String get battleTwoPlayerButton =>
      ja ? '👫 1台で2人であそぶ' : '👫 Two players, one phone';
  // 🎮 やってみるチュートリアル（読ませずに、やらせて覚えてもらう）
  String get tutPlayTitle => ja ? 'やってみよう' : 'Try it';
  String get tutPlaySkip => ja ? 'とばす' : 'Skip';
  String get tutPlayIntro => ja
      ? 'ルールはひとつだけです。\n\n'
          '**はじめて出た人には、名前をつける。\nその人がまた出てきたら、名前を呼ぶ。**\n\n'
          '早く正しく呼べた人が、そのカードをもらえます。\nさっそくやってみましょう。'
      : 'One rule: name each newcomer, then call their name when they come back. '
          'Whoever calls it first wins the card. Let us try it.';
  String get tutPlayStart => ja ? 'はじめる' : 'Start';
  String get tutPlayName1 => ja
      ? 'はじめての人が出てきました。名前をつけてあげましょう。\n'
          'ここでは点は入りません。**覚えるための時間**です。'
      : 'A new face. Give them a name. No points yet — this is the memorising step.';
  String get tutPlayName2 => ja
      ? 'もうひとり出てきました。この人にも名前をつけます。\n'
          '（顔と名前を、いま結びつけておいてください）'
      : 'One more. Name them too — link the face and the name now.';
  String tutPlayNamed(String name) =>
      ja ? '「$name」とおぼえた！' : 'Got it: $name';
  String get tutPlayRecall => ja
      ? 'さっきの人が、また出てきました。\n**名前を呼んであげてください。**'
      : 'They are back. Call their name.';
  String get tutPlayRetry => ja
      ? 'おしい！もう一度どうぞ。\n'
          '（本番でも、まちがえたら取られるだけです。終わりにはなりません）'
      : 'Close! Try again — a miss is never the end.';
  String get tutPlayFaster => ja
      ? '⚡ みんなで遊ぶときは、早く呼べた人がカードをもらえます'
      : '⚡ In a real game, whoever calls it first takes the card';
  String tutPlayWon(String name) => ja
      ? '正解！「$name」のカードをもらえました。\n\n'
          'これが、このゲームのすべてです。\n**つけて、呼ぶ。早いほうが勝ち。**'
      : 'Correct — you won the card. That is the whole game: name them, call them, fastest wins.';
  String tutPlayGetCoins(int coins) =>
      ja ? '🪙 $coins コインを受け取る' : 'Get 🪙 $coins';
  String get tutPlayDone => ja
      ? 'これでルールはぜんぶです。\n'
          'もらったコインは、キャラや読み物と交換できます。'
      : 'That is all the rules. Spend your coins on characters and articles.';
  String get tutPlayToGame => ja ? 'ゲームをはじめる' : 'Start playing';

  // 📚 コインで読める読み物
  String get articleLibraryTitle => ja ? '📚 もっと読む' : '📚 Read more';
  String get articleLibraryLead => ja
      ? 'コインで開ける読み物です。タイトルと「何の話か」は開く前から読めます。'
          '記憶の仕組み・名前の覚え方・忘れないための組み立て方を、研究や公的機関の資料をもとにまとめました。'
      : 'Articles you can open with coins. Titles and summaries are free to read.';
  String articleBuyConfirm(int cost, int coins) => ja
      ? 'この記事を 🪙$cost で開きますか？（持っているコイン: $coins）\n一度開けば、ずっと読めます。'
      : 'Open this article for 🪙$cost? (You have $coins.) Once opened, it stays open.';
  String get articleBuy => ja ? '開く' : 'Open';
  String get articleOwned => ja ? '読める' : 'Open';
  String get articleNotEnough => ja ? 'コインが足りません' : 'Not enough coins';
  String articleWatchToEarn(int coins) => ja
      ? '動画を最後まで見ると 🪙$coins もらえます。見ますか？'
      : 'Watch a video to the end and get 🪙$coins. Watch now?';
  String get articleWatchButton => ja ? '動画を見る' : 'Watch';
  String get articleSources => ja ? '🔬 出典' : '🔬 Sources';
  String get articleDisclaimer => ja
      ? '※ ここに書いたのは日常の工夫であって、診断や治療ではありません。'
          '効果には個人差があります。物忘れが以前より明らかに増えた、'
          '日常生活に支障が出ているといった場合は医療機関にご相談ください。'
      : 'This is everyday practice, not diagnosis or treatment. Effects vary. If forgetfulness affects daily life, please consult a medical professional.';
  String get articleMoreButton =>
      ja ? '📚 コインで読める記事をみる' : '📚 More articles (coins)';

  // 🛠 開発者モード
  String get devModeTitle => ja ? '🛠 開発者モード' : '🛠 Developer mode';
  String get devModeDesc => ja
      ? '動作確認と画面撮影のための機能です。合言葉を入れると、ショップのアイテム・キャラ・テーマ・読み物がすべて開きます。'
      : 'For testing and screenshots. Enter the passphrase to unlock every shop item, character, theme and article.';
  String get devModePrompt => ja ? '合言葉' : 'Passphrase';
  String get devModeEnable => ja ? '有効にする' : 'Enable';
  String get devModeWrong => ja ? '合言葉がちがいます' : 'Wrong passphrase';
  String get devModeOn => ja
      ? '🛠 開発者モード：すべて開放しました'
      : '🛠 Developer mode: everything unlocked';
  String get devModeOff => ja ? '表示を戻す' : 'Hide badge';
  String get devModeNote => ja
      ? '※ 戻しても、開いた持ち物は取り上げません。'
      : 'Turning it off does not take items back.';

  // 📇 結果画面の「誰が誰だったか」
  String get reportRosterTitle =>
      ja ? '📇 今回の顔ぶれ' : '📇 Who was who';
  String get reportRosterHint => ja
      ? '取り違えた人がいたら、ここでもう一度そろえて見ておきましょう。'
      : 'Mixed someone up? Take one more look at them together.';

  /// 全部つないだあとの一言。ここから自動で判定に入る。
  String get lineMatchAllLinked =>
      ja ? '✅ 全員つながりました！答え合わせします' : '✅ All linked — checking…';
  String lineMatchProgress(int done, int total) =>
      ja ? '残り${total - done}人（$done/$total）' : '$done/$total connected';
  String get lineMatchButton => ja ? '🖇 線結びで特訓' : '🖇 Line match training';
  // 実物の名刺＋顔写真アップロード（カスタム名簿）
  String get customCompanyField => ja ? '会社名（任意）' : 'Company (optional)';
  String get customTitleField => ja ? '肩書（任意）' : 'Title (optional)';
  String get customPhoneField => ja ? '電話番号（任意）' : 'Phone (optional)';
  String get customEmailField => ja ? 'メール（任意）' : 'Email (optional)';
  String get customPickCardImage => ja ? '📇 名刺の写真を選ぶ（任意）' : '📇 Add a business-card photo (optional)';
  String get customCardSelected => ja ? '✓ 名刺の写真を選択済み' : '✓ Business-card photo added';
  String get customDetailsTitle => ja ? '名刺の情報を入力' : 'Enter card details';
  String get customRecallQuizButton =>
      ja ? '🧠 名刺で思い出しクイズ' : '🧠 Business-card recall quiz';
  String get customFaceFirstHint => ja
      ? 'まず顔写真を選び、次に名刺の情報を入力します。'
      : 'Pick a face photo first, then enter the card details.';
  String get researchTipHeader =>
      ja ? '🔬 研究にもとづく名前のコツ' : '🔬 Research-backed name tip';
  String get sourceLabel => ja ? '出典' : 'Source';

  // 🛍 キャラクターショップ／報酬広告／レビュー誘導
  String get storeTitle => ja ? '🛍 キャラクターショップ' : '🛍 Character Shop';
  String storeCoins(int n) => ja ? 'コイン: $n' : 'Coins: $n';
  String storeWatchAd(int n) =>
      ja ? '🎁 動画でコイン +$n' : '🎁 Free coins +$n (video)';
  String get storeAdLoading => ja ? '動画をじゅんび中…' : 'Loading video…';
  String get storeRate => ja ? '⭐ アプリを評価する' : '⭐ Rate the app';
  String get storeOwned => ja ? '所持ずみ' : 'Owned';
  String get storeStarter =>
      ja ? '基本キャラ（15人・最初から）' : 'Starter cast (15, free)';
  String get storeMore => ja ? '➕ 追加キャラ（コインで仲間に）' : '➕ More characters (buy with coins)';
  String get storeBought => ja ? '新しいキャラを仲間にした！🎉' : 'New character unlocked! 🎉';
  /// 買った直後の案内。買っただけでは変化が見えないので、
  /// デッキに入ったことを伝えて編集画面への導線を出す。
  String get storeBoughtDeckHint => ja
      ? '🎉 仲間にした！ゲームに出るようになったよ'
      : '🎉 Unlocked! They will now appear in your games';
  String get storeOpenDeck => ja ? 'デッキを見る' : 'View deck';
  // 🏆 実績で解放するキャラ（コインでは買えない枠）
  String featCondition(dynamic feat) {
    switch ('$feat'.split('.').last) {
      case 'hardWins3':
        return ja ? 'つよいに3勝' : 'Beat Hard ×3';
      case 'oniWin1':
        return ja ? '鬼に勝つ' : 'Beat Oni';
      case 'oniWins3':
        return ja ? '鬼に3勝' : 'Beat Oni ×3';
      case 'play50':
        return ja ? '50回あそぶ' : 'Play 50 games';
      case 'perfectWin':
        return ja ? '全問正解で勝つ' : 'Perfect win';
      default:
        return ja ? '条件を満たす' : 'Meet the condition';
    }
  }

  String featLocked(String cond) => ja
      ? 'このキャラはコインで買えません。「$cond」で参戦します🏆'
      : 'Not for sale. Unlock by: $cond 🏆';
  String featJoined(String name) =>
      ja ? '🏆 $name が参戦した！' : '🏆 $name joins the battle!';

  // 🎁 今日のキャラガチャ（1日1回タダで1体）
  String get gachaTitle => ja ? '🎁 今日のキャラ' : '🎁 Today\'s character';
  String get gachaReady => ja ? '1日1回 タダで1体！' : 'One free pull a day!';
  String get gachaDoneToday =>
      ja ? 'また明日きてね' : 'Come back tomorrow';
  String gachaGot(String emoji) =>
      ja ? '$emoji 新しいキャラが仲間になった！' : '$emoji A new character joined!';
  String gachaAllOwned(int coins) => ja
      ? 'ぜんぶ持ってる！かわりに🪙$coins もらった'
      : 'You own them all! Got 🪙$coins instead';

  // 🏆 段位（ホームに常設）
  String get trophyLabel => ja ? 'だんい' : 'Rank';
  // 📅 今週おぼえた人数
  String weeklyLearnedLabel(int n) =>
      ja ? '📅 今週 $n人 おぼえた' : '📅 $n learned this week';
  String get weeklyLearnedZero =>
      ja ? '📅 今週はまだ0人。1回あそぼう！' : '📅 None yet this week — play once!';
  String get storeHint => ja
      ? '買ったキャラは「なまえがお」と「名刺覚え」に登場します。'
      : 'Bought characters show up in Name Call and Card Memory.';
  String get storeBuyConfirm => ja ? 'このキャラを仲間にする？' : 'Add this character?';
  // 試合・特訓のあとのショップ誘導
  String get ctaNewCharTitle =>
      ja ? '🧑‍🤝‍🧑 新しいキャラを仲間にしよう！' : '🧑‍🤝‍🧑 Add new characters!';
  String get ctaNewCharDesc => ja
      ? 'コインを貯めて、出会える顔ぶれを増やそう。'
      : 'Spend coins to grow your cast of faces.';
  String get ctaToShop => ja ? 'ショップへ →' : 'To Shop →';

  // 🎬 動画でコイン2倍（リザルト画面）
  String doubleCoinsButton(int n) =>
      ja ? '🎬 動画でコイン2倍！(+$n)' : '🎬 Watch ad to double coins! (+$n)';
  String get doubleCoinsDone => ja ? '✓ コイン2倍ずみ！' : '✓ Coins doubled!';

  // 🌌 覚醒（プレステージ）システム
  String get awakenTitle => ja ? '🌌 覚醒' : '🌌 Awakening';
  String get awakenDesc => ja
      ? '鬼段位をきわめた者だけが選べる、もうひとつの道。段位はリセットされるが、'
      '獲得コインが永久にアップし、称号に覚醒の証が刻まれる。何度でも、その先へ。'
      : 'A path only those who have mastered Oni Rank may choose. Your rating '
      'resets, but coin gains rise forever, and your title bears the mark of '
      'awakening. Again and again, beyond the limit.';
  String awakenCount(int n) => ja ? '覚醒 $n回' : 'Awakened ×$n';
  String awakenMultiplier(String pct) =>
      ja ? 'コイン獲得 +$pct%' : '+$pct% coins from all sources';
  String get awakenLocked => ja
      ? '🔒 鬼段位（レート1600）で鬼CPUに3勝すると覚醒できるようになる'
      : '🔒 Beat Oni-difficulty CPU 3 times at Oni Rank (1600+) to unlock';
  String get awakenButton => ja ? '覚醒する' : 'Awaken';
  String get awakenConfirmTitle => ja ? '覚醒しますか？' : 'Awaken now?';
  String get awakenConfirmBody => ja
      ? '段位レーティングは見習いに戻りますが、コイン獲得倍率が永久に上がり、'
      '称号に覚醒回数が刻まれます。この操作は取り消せません。'
      : 'Your rating returns to Novice, but your coin multiplier increases '
      'permanently and your title records this awakening. This cannot be undone.';
  String get awakenDone => ja ? '覚醒した！🌌' : 'You have awakened! 🌌';

  // ショップ拡張（ほめボイス／装備アイテム／名刺スキン）
  String get shopVoicesTitle => ja ? '🎉 ほめボイス' : '🎉 Praise Voices';
  String get shopVoicesDesc => ja
      ? '正解や勝利のときに、声で褒めてくれます。今日のがんばりに、ひとこと。'
      : 'A voice praises you when you get it right. A word for your effort today.';
  String get shopCharmsTitle => ja ? '装備アイテム' : 'Equipment';
  String get shopCharmsDesc => ja
      ? '1つだけ持てます。プレイが少しやさしくなったり、コインが増えたり。'
      : 'Equip one. Makes play a little kinder, or your coins a little more.';
  String get shopSkinsTitle => ja ? '💳 名刺のデザイン' : '💳 Card Designs';
  String get shopSkinsDesc => ja
      ? '名刺覚えで差し出される名刺の見た目が変わります。'
      : 'Changes how the business card looks in Card Memory.';
  String shortByCoins(int short, int reward) => ja
      ? 'あと $short コインで手に入ります。動画を1本見ると $reward コインもらえます。'
      : 'You need $short more coins. Watching one video gives you $reward.';
  String get shopThemesTitle => ja ? '🎨 着せ替えテーマ' : '🎨 Themes';
  String get shopThemesDesc => ja
      ? 'アプリ全体の色あいが変わります。毎回目に入るごちそう。'
      : 'Recolors the whole app — you’ll see it every time.';
  String get storeCharsDesc => ja
      ? 'なまえがおと名刺覚えに登場する人が増えます。'
      : 'Adds more people to Name Call and Card Memory.';
  // 🔔 練習リマインド
  // 🔁 日をまたいだ復習（間隔をあけた再テスト）
  String spacedReviewTitle(int n) =>
      ja ? '🔁 きょう復習する人が $n 人います' : '🔁 $n to review today';
  String get spacedReviewDesc => ja
      ? '前に思い出せなかった人です。間隔をあけてもう一度会うと、長く残りやすいとされています。'
      : 'People you missed before. Meeting them again after a gap is said to make names last.';
  String get spacedReviewStart => ja ? '復習をはじめる' : 'Start review';

  // 🔔 練習リマインドのソフトアスク（services/notify_prompt.dart）
  //    OSの許可を求める前に、なぜ必要かをアプリの言葉で説明する。
  String get notifyAskTitle => ja
      ? '🧠 明日、もう一度おぼえてみませんか？'
      : '🧠 Want to try remembering again tomorrow?';
  String get notifyAskWhy => ja
      ? '覚えたことは、時間をおいて思い出すと定着します。'
      : 'What you learn sticks better when you recall it after a gap.';
  String notifyAskWhen(int hour) => ja
      ? '毎日$hour時に、ひとことお知らせします。'
      : "We'll send one short nudge every day at $hour:00.";
  String get notifyAskEscape => ja
      ? '（時間は変えられます／あとで切れます）'
      : '(You can change the time, or turn it off later.)';
  String get notifyAskLater => ja ? 'あとで' : 'Later';
  String get notifyAskAccept => ja ? 'お知らせを受け取る' : 'Send me the nudge';
  String get notifyDeniedHint => ja
      ? '端末の設定で通知が切れています。マイページからいつでもONにできます。'
      : 'Notifications are off in your device settings. You can enable them from My Page.';
  /// 🔕 通知そのもののON/OFF（「あとで切れます」と言った以上、切れる場所が要る）
  String get notifyToggleLabel => ja ? 'お知らせを受け取る' : 'Send me the nudge';
  String get notifyOffHint => ja
      ? 'OFFにすると通知は止まります。いつでも戻せます。'
      : 'Turning this off stops the reminders. You can turn it back on anytime.';

  String get reminderTitle => ja ? '練習のリマインド' : 'Practice reminder';
  String get reminderDesc => ja
      ? '毎日この時刻に「名前トレーニングの時間です」とお知らせします。'
      : "We'll remind you to train at this time every day.";
  String get reminderCueHint => ja
      ? '「夕食のあと」「通勤電車で」など、毎日必ずやることの直後に決めると続きやすいと言われています。'
      : 'Tying it to something you already do daily — after dinner, on the commute — is said to help it stick.';
  String hourLabel(int h) => ja ? '$h時' : '$h:00';
  String reminderSaved(String time) =>
      ja ? '$time にお知らせします' : "We'll remind you at $time";
  // 📇 名刺OCR
  String get ocrReading => ja ? '名刺を読み取り中…' : 'Reading the card…';
  String get ocrFilled => ja
      ? '✅ 読み取った内容を入れました。ちがっていたら直してください。'
      : '✅ Filled from the card. Please correct anything wrong.';
  String get ocrFailed => ja
      ? '読み取れませんでした。明るい場所で、まっすぐ撮ると成功しやすいです。'
      : "Couldn't read it. Bright light and a straight angle help.";
  // 💳 広告除去（買い切り課金）
  String get removeAdsTitle => ja ? '💎 広告を消す（買い切り）' : '💎 Remove ads (one-time)';
  String get removeAdsDesc => ja
      ? 'バナーと全画面広告が出なくなります。動画でコインを増やす機能はそのまま使えます。'
      : 'Removes banners and full-screen ads. Video-for-coins still works.';
  String get removeAdsThanksToast => ja ? '💎 ありがとうございます！' : '💎 Thank you!';
  String get adsRemovedThanks => ja
      ? '💎 広告なしでご利用いただけます。ありがとうございます！'
      : '💎 Ads are off. Thank you for your support!';
  String get restorePurchase => ja ? '購入を復元' : 'Restore purchase';
  String get shopBgmTitle => ja ? '🎵 BGM' : '🎵 Music';
  String get shopBgmDesc => ja
      ? 'ゲーム中に流れる曲。コインで買うか、動画1本でも解放できます。'
      : 'In-game music. Buy with coins, or unlock with one video.';
  String get unlockByAd => ja ? '🎬 動画で解放' : '🎬 Free via video';
  // 🎵 ⚠️ 曲を足したら、ここも足すこと。
  //    「運命」の演奏は Skidmore College orchestra（Musopen 経由）で、
  //    録音そのものがパブリックドメインとして公開されている。
  //    表示は義務ではないが、提供元の希望なので出す。
  String get bgmCredit => ja
      ? '楽曲提供: 魔王魂／クラシック曲はパブリックドメイン\n'
          '運命の演奏: Skidmore College orchestra（Musopen）\n'
          '威風堂々: United States Army Band\n'
          '義勇軍進行曲: United States Navy Band\n'
          '軍艦行進曲: 海上自衛隊東京音楽隊（防衛省）'
      : 'Music: MaouDamashii / classical tracks are public domain\n'
          'Symphony No.5: Skidmore College orchestra (Musopen)\n'
          'Pomp and Circumstance: United States Army Band\n'
          'March of the Volunteers: United States Navy Band\n'
          'Warship March: JMSDF Tokyo Band (Japan MoD)';
  String get shopEquipped => ja ? '装備中' : 'Equipped';
  String get shopEquip => ja ? '使う' : 'Equip';
  String get shopTry => ja ? '試し聞き' : 'Preview';
  String get shopBought => ja ? '手に入れた！🎉' : 'Unlocked! 🎉';
  String get charmSaved =>
      ja ? 'アイテムの効果で助かりました' : 'Your equipment saved you';

  // 📚 よみものタブ
  String get tabRead => ja ? 'よみもの' : 'Read';
  String get tabStory => ja ? 'ものがたり' : 'Story';
  String get tabFaceMemo => ja ? '顔メモ' : 'Face Notes';
  // 📖 ルールブック（いつでも見直せるルール一覧）
  String get rulebookTitle => ja ? '📖 ルール' : '📖 Rules';
  /// ボタンに添える短いラベル（アイコンだけでは何のボタンか分からないため）。
  String get rulebookShort => ja ? 'ルール' : 'Rules';
  String get rulebookRead => ja ? '読み上げる' : 'Read aloud';
  String get rulebookLead => ja
      ? 'あそび方をわすれたら、ここを見てね。ゲーム中でも 📖 ボタンから開けます。'
      : 'Forgot how to play? Look here. The 📖 button works during a game too.';

  String ruleEmoji(dynamic t) {
    switch ('$t'.split('.').last) {
      case 'cpu':
        return '🤖';
      case 'onlineFriend':
        return '🤝';
      case 'rank':
        return '🏆';
      case 'turnPairs':
        return '🔁';
      case 'battle':
        return '⚔️';
      case 'lineMatch':
        return '🖇';
      case 'cardMemory':
        return '💼';
      case 'pairs':
        return '🃏';
      default:
        return '📣';
    }
  }

  String ruleTitle(dynamic t) {
    switch ('$t'.split('.').last) {
      case 'cpu':
        return ja ? 'CPUとたいせん' : 'Play vs CPU';
      case 'onlineFriend':
        return ja ? 'オンライン・フレンドマッチ' : 'Online: Friend Match';
      case 'rank':
        return ja ? 'オンライン・ランクマッチ' : 'Online: Ranked Match';
      case 'turnPairs':
        return ja ? 'オンライン・ターン制対戦' : 'Online: Turn-based Match';
      case 'battle':
        return ja ? 'なまえバトル（ベータ）' : 'Name Battle (beta)';
      case 'lineMatch':
        return ja ? '線むすび特訓' : 'Line Match';
      case 'cardMemory':
        return ja ? '名刺覚え（思い出し訓練）' : 'Card Memory';
      case 'pairs':
        return ja ? 'ペアさがし' : 'Pair Hunt';
      default:
        return ja ? 'なまえがお（メイン）' : 'Name Call (main)';
    }
  }

  /// 🤖 難易度表の1行ずつ。数字は models/cpu_difficulty.dart が一次情報なので、
  /// ここに直書きせず必ずそこから作る（ルールブックだけ古い値のまま残るのを防ぐ）。
  String _cpuTableJa() {
    const names = {
      'easy': 'かんたん',
      'normal': 'ふつう',
      'hard': 'つよい',
      'oni': '鬼',
    };
    return [
      for (final k in const ['easy', 'normal', 'hard', 'oni'])
        '${kCpuDifficulties[k]!.emoji} ${names[k]}'
            '：${kCpuDifficulties[k]!.groupSize}人ずつ / '
            '${kCpuDifficulties[k]!.answerSeconds}秒 / '
            '勝つと🪙${kCpuDifficulties[k]!.winBonus}',
    ].join('\n');
  }

  String _cpuTableEn() {
    const names = {
      'easy': 'Easy',
      'normal': 'Normal',
      'hard': 'Hard',
      'oni': 'Oni',
    };
    return [
      for (final k in const ['easy', 'normal', 'hard', 'oni'])
        '${kCpuDifficulties[k]!.emoji} ${names[k]}'
            ': ${kCpuDifficulties[k]!.groupSize} at once / '
            '${kCpuDifficulties[k]!.answerSeconds}s / '
            'win 🪙${kCpuDifficulties[k]!.winBonus}',
    ].join('\n');
  }

  String ruleBody(dynamic t) {
    switch ('$t'.split('.').last) {
      case 'cpu':
        return ja
            ? '''ひとりであそぶモード。CPUと カードのとりあいをするよ。\n\n① はじめて出たキャラに 名前がつく（おまかせ）\n② 同じキャラが また出てきたら、4つの中から 正しい名前をえらぶ\n③ CPUが思い出すより 早く正解できたら カードをゲット\n④ おそかったり まちがえたら CPUに とられる\n\n🤖 むずかしさで 変わるのは 相手の速さだけじゃない。\n「何人まとめて おぼえてから 答えるか」が いちばん大きい。\n${_cpuTableJa()}\nかんたんは 1人おぼえて すぐ答える。鬼は 4人おぼえてから 4人ぶん答える。\nあいだに ほかの人が はさまるほど むずかしくなる。\n\n🪙 コインは 3つの合計。\n・思い出せた1問ごと（むずかしいほど 単価が高い）\n・全問正解ボーナス\n・勝利ボーナス\nぜんぶ思い出せたら 負けても コインは入るよ。'''
            : '''Solo mode. You and the CPU compete for cards.\n\n1. Each new character is given a name (auto)\n2. When they appear again, pick the right name from four\n3. Answer correctly before the CPU to win the card\n4. Too slow or wrong, and the CPU takes it\n\n🤖 Difficulty changes how many people you memorize before answering.\n${_cpuTableEn()}\nEasy: memorize 1, answer right away. Oni: memorize 4, then answer all 4.\n\n🪙 Coins = per correct answer + perfect bonus + win bonus.''';
      case 'onlineFriend':
        return ja
            ? '''友だちと オンラインで あそぶ なまえがお。\n1台で あそぶときと **同じルール**です。\n\n① 合言葉（6文字）を つくって 友だちに おくる\n② 友だちが 合言葉を いれると スタート\n\n👥 出てくる人数は **部屋をつくった人**が きめる。\n　 その人数が そのまま 相手の画面にも 出るので、\n　 ふたりとも 同じ顔ぶれ・同じ順番で あそべます。\n\n③ カードが 1まいずつ 出てくる（出たとき命名）\n④ はじめて出た人には アプリが 名前をつける\n⑤ また出てきたら 4つの中から えらぶ\n\n🏆 かくとく枚数が 多い方の勝ち（同じなら タイム）。\n通話は いりません。それぞれの スマホで 同時に すすみます。\n\n🎲 ランダムマッチは、**同じ人数を えらんだ人**と当たります。'''
            : '''Name Call with a friend online — the same rules as one-phone play.\n\n1. Create a 6-character room code and send it\n2. They enter it and the match starts\n\n👥 The host picks how many faces, and the guest gets exactly the same setup, so you both see the same people in the same order.\n\n3. Cards appear one at a time (name-as-you-go)\n4. New faces are named automatically\n5. When they return, pick from four choices\n\n🏆 Most cards wins (time breaks ties). No voice chat needed.\n🎲 Random match pairs you with someone who picked the same number.''';
      case 'rank':
        return ja
            ? '''知らない人と、通話なしで あそべる 早押し勝負。\n\n① おぼえタイム … 8人の顔と名前を まとめて おぼえる\n　 名前は 実際に多い苗字100から アプリが 配ります\n② 早押し … 顔が 1人ずつ 出るので 4つの中から えらぶ\n③ **先に 正解した方が そのカードを 取る**（早い者勝ち）\n④ どちらも 取れないまま 8秒たったら 次の問題へ\n\n⚡ 相手と まったく同じ問題が 同時に 出ます。\n　 まちがえると その問題は もう答えられません。\n\n🏆 8問おわった時点で 取った枚数が 多い方の勝ち。\n🏅 勝つと ランクポイントが +25、負けると -15。\n　 ポイントは ランキングに 反映されます。'''
            : '''A buzzer duel with a stranger — no voice chat needed.\n\n1. Memorize 8 faces and names (names come from the 100 most common surnames)\n2. One face appears at a time; pick from four choices\n3. Whoever answers correctly FIRST takes the card\n4. If nobody takes it within 8 seconds, it moves on\n\n⚡ You both see the identical question at the same moment. A wrong answer locks you out of that question.\n\n🏆 Most cards after 8 questions wins.\n🏅 Win +25 rank points, lose -15.''';
      case 'turnPairs':
        return ja
            ? '''記憶術トレーニングの盤面で、交互に めくる 対戦。\n\n① おぼえタイム … 顔と名前の 組み合わせを 見る\n　 「この人は 〇〇だから 〇〇さん」と タグをつけるのがコツ\n② カードが 裏返る\n③ **交互に** 2まいずつ めくる\n④ 顔と名前が そろったら ペア成立 → **もう一度 めくれる**\n⑤ ちがったら 相手の番\n\n🏆 カードが なくなった時点で、多く取った方の勝ち。\n\n⏳ 同時に 急かされないので、記憶術を ためすのに 向いています。\n部屋をつくった人が 先手です。'''
            : '''Take turns flipping the mnemonic-training board.\n\n1. Study the face-name pairs — try tagging each one\n2. The cards flip over\n3. Players alternate, flipping two cards each turn\n4. Match a face with its name and you go again\n5. Miss, and it is the other player's turn\n\n🏆 Most pairs when the board is cleared wins.\n⏳ Nobody is rushing you, so it is a good place to actually practice tagging. The host goes first.''';
      case 'lineMatch':
        return ja
            ? '''一人でじっくり練習するモードです。運の要素はありません。\n\n① 記銘タイム … 顔と名前を組みで覚えます\n② 線結び … 顔から名前へ指でドラッグしてつなぎます\n③ つなぎ直しは何度でもできます（同じ名前を別の人へ引くと、前の線は外れます）\n④ 全員つないだ時点で自動的に答え合わせをして、結果が出ます\n\n💡 顔を見て名前を引き出す形なので、実生活にいちばん近い練習です。'''
            : '''A calm solo drill — no luck involved.\n\n1. Memorize each face with its name\n2. Drag from a face to a name to connect them\n3. Redo any line as often as you like\n4. Connect them all, then check your answers''';
      case 'cardMemory':
        return ja
            ? '''仕事で会う人を覚えるための訓練です。

① 出会う … 名刺を持った相手が自己紹介をします（音声付き）
② 時間を置く … あえて間隔を空けます。この「間」が定着に効きます
③ 思い出す … 顔を見て「この人は誰だったか」を答えます

🎯 出題項目は名前が必須。会社名・役職・電話番号・メールアドレスを任意で追加できます。
🔁 間違えた相手は翌日また登場します。

📇 実際にもらった名刺と顔写真を登録して、そのまま出題できます（スマートフォン版のみ）。名前・読み方・誕生日・出身・自分との関係・SNS・自由記入メモまで残せるので、名簿としても使えます。入力した内容は端末内にのみ保存され、外部へは送信されません。'''
            : '''Practice for people you meet at work.\n\n1. Meet — they introduce themselves with a business card (with voice)\n2. Time passes — a deliberate gap helps memory\n3. Recall — look at the face and answer who it was\n\n🎯 Name is required; add company, title, phone, email as you like.''';
      case 'battle':
        return ja
            ? '''🧪 まだベータ版のモードです。覚えたことが、そのまま戦いの強さになります。\n\n① 📖 名簿 … これから出る人の顔・名前・能力をひととおり見ます\n② 🃏 神経衰弱 … **同じ人の2まい**をそろえて取ります\n　 1台で2人のときは、始める前にカードの作りをえらべます。\n　 🃏 顔カード＋名前カード … 顔と名前を結びつけて覚えていないと取れません\n　 🂡 1枚に顔と名前（トランプ式）… 同じ札を2まいそろえるだけ。やさしめです\n　 😀 顔だけ … 名前は出ません。顔の見分けに専念できます\n③ ⚔️ タワーディフェンス … 取った人を出撃させて、相手のタワーを狙います\n\n👤 ひとりのとき … 6人。10回のめくりの中で当て、**取り逃した人が相手**につきます\n👫 1台で2人のとき … 8人。**交互に**めくり、当てた人がその人をもらいます（当てたらもう一度めくれます）。だいたい4人ずつになります\n\n⚡ カードを押すと出撃します（⚡は時間で回復）。相手のタワーを壊せば勝ち。90秒たったときは、タワーの残りが多いほうの勝ちです。\n\n⚡ **取った人数が多いほど、⚡の回復が速くなります**。覚えているほど手数が増える、というのがこのモードの肝です。残り30秒からは⚡が2倍になります。\n\n📱 戦場は**縦**です。**手前（下）があなたの陣、奥（上）が相手の陣**。2人で遊ぶときはスマホを挟んで向かい合い、**それぞれ自分側の端**を操作します（相手側は上下さかさまに出ます）。\n\n🏰 **タワーは撃ち返します**。うすい色の帯がタワーの射程です。単騎で突っ込ませると着く前に溶けます。\n\n能力は**顔ごとに決まっていて、いつも同じ**です。\n🧱 前衛／🛡️ 重装 … 近距離。かたい。壁になります\n⚔️ 斬りこみ … 近距離。強いけれど紙です\n🏃 遊撃 … 近距離。速くて安い\n🏹 弓／🎯 狙撃 … 遠距離。前衛のうしろから撃てます\n💣 タワー狙い … **相手のユニットを無視して素通りし、タワーだけ**を叩きます。撃ち返されるので、前衛と一緒に出すのがコツ\n\n🪙 コインは当てた人数が主で、勝敗はおまけです。'''
            : '''🧪 Beta. What you remember becomes your strength.\n\n1. 📖 Roster — look over each face, name and ability\n2. 🃏 Concentration — match each person's face card with their name card\n3. ⚔️ Tower defense — deploy the people you took and go for their tower\n\n👤 Solo: 6 people, 10 tries. Everyone you miss fights against you.\n👫 Two players on one phone: 8 people, taking turns (match and go again) — roughly 4 each.\n\n⚡ Tap a card to deploy. Break their tower, or have more tower HP left after 90 seconds.\n🏰 Towers shoot back — the tinted band is their range.\n\nAbilities are fixed per face:\n🧱🛡️ Melee, tough — a wall\n⚔️ Melee, strong but fragile\n🏃 Melee, fast and cheap\n🏹🎯 Ranged — fires from behind your front line\n💣 Siege — walks past enemy units and only hits the tower''';
      case 'pairs':
        return ja
            ? '''顔と名前の神経衰弱。マイページから あそべます。\n\n① おぼえタイム … 顔と名前の組み合わせを見る\n② カードが裏返る\n③ 顔カードと 名前カードの 正しいペアをさがす\n\nCPU対戦・1台でみんなで対戦も できます。'''
            : '''Face-and-name concentration. Open it from My Page.\n\n1. Study the face-name pairs\n2. The cards flip over\n3. Find the matching face and name''';
      default:
        return ja
            ? '''ともだちや かぞくと 1台のスマホであそぶ メインのゲーム。\n\n① カードが 1まいずつ 出てくる\n② はじめて出たキャラには その場で 名前をつける\n　 声に出して「〇〇！」と言ってから ✨名前をつけた！を おす\n　 （まよったら 🎲おまかせ でもOK）\n③ まえに名前をつけたキャラが また出てきたら\n　 みんなで いっせいに 名前をさけぶ！📣\n④ いちばん早く 正しく 言えた人のボタン（P1・P2…）を おす\n　 おされた人が そのカードをもらえる\n⑤ だれも思い出せなかったら「だれもわからなかった…」\n\n🏆 カードが なくなったら おしまい。いちばん多く あつめた人の勝ち！\nさいごに みんなの名前が ぜんぶ出ます。'''
            : '''The main game — play with friends on one phone.\n\n1. Cards appear one at a time\n2. Name each newcomer out loud, then tap "We named it!"\n3. When a named character returns, everyone shouts the name\n4. Tap the button (P1, P2...) of whoever said it first\n5. If nobody remembers, tap "Nobody knew..."\n\n🏆 When the cards run out, whoever collected the most wins!''';
    }
  }

  // ── ホーム画面（top_screen）のコンパクト表記 ──
  String settingsChip(int players, int people, int copies) => ja
      ? '$players人・$peopleキャラ・$copies枚'
      : '${players}P · $people chars · $copies cards';
  String get partyButtonLabel =>
      ja ? 'みんなで対戦（1台）' : 'Party (1 phone)';
  String get partyButtonHint => ja
      ? 'いちばん人気！友だちと名前を呼びあおう'
      : 'Most popular! Call out names with friends';
  String get cpuButtonCompact => ja ? 'ひとりで対戦' : 'Play Solo';
  String get onlineButtonCompact => ja ? 'オンライン' : 'Online';
  String get rankButtonCompact => ja ? 'ランク' : 'Ranked';
  String get trainingButtonCompact =>
      ja ? 'ビジネス特訓' : 'Business Training';
  String get howManyPlayers => ja ? '何人であそぶ？' : 'How many players?';
  String get myPageTooltip => ja ? 'マイページ' : 'My Page';
  String get tutorialLabel => ja ? 'チュートリアル' : 'Tutorial';
  String get reviewLabel => ja ? 'レビューする' : 'Review';

  // ── なまえコール画面（name_call_screen）のUI文言 ──
  String get cardGetBanner => ja ? 'カードゲット！' : 'Card Get!';
  String comboBanner(int n) => ja ? '$n れんぞく！' : '$n combo!';
  String playerGotBanner(int p) => ja ? 'P$p がゲット！' : 'P$p got it!';
  String get nobodyRecalled => ja
      ? 'だれも思い出せなかったので、名前をつけ直します'
      : 'Nobody recalled — renaming';
  String get clearVictory => ja ? 'クリア！' : 'Clear!';
  String cardsLeft(int n) => ja ? 'のこり$n枚' : '$n cards left';
  String get lastCardLabel => ja ? 'ラスト！' : 'Last!';
  String bestComboLabel(int n) => ja ? 'さいこう $n れんぞく' : 'Best: $n combo';

  // ── ホームシェル（home_shell）の初回案内 ──
  String get offerGuideTitle =>
      ja ? 'ほかの あそびかたも あるよ' : 'There is more to play';
  String get offerGuideBody => ja
      ? 'みんなで あそぶ・顔メモ・名刺覚え・ものがたり。\n'
          '5分くらいで ぜんぶ わかるよ。\n\n'
          'あとから ホームの 📖ルール でも 読めます。'
      : 'Play together, Face Notes, Card Memory, Story.\n'
          'About 5 minutes to see it all.\n\n'
          'You can also read it later from 📖 Rules.';
  String get offerGuideLater => ja ? 'あとで' : 'Later';
  String get offerGuideRead => ja ? '読む' : 'Read';
  String get playReviewLabel => ja ? '⭐ 評価する' : '⭐ Rate app';
  String get watchAdGetChar => ja ? '動画でキャラ獲得' : 'Ad for a character';
  String get faceMemoCardTitle => ja
      ? '顔メモ — 会った人を忘れない'
      : 'Face Notes — Never forget a face';
  String get faceMemoCardBody => ja
      ? '写真か似顔絵で顔をつくって名前を登録。そのまま覚える練習や対戦ができるよ。'
      : 'Create a face from a photo or avatar, add a name, then study or play with them.';
  String get faceMemoCardButton => ja ? '顔をつくってみる' : 'Create a face';
  String get faceMemoStudyButton => ja ? '登録した人をおぼえる' : 'Study your people';
  String faceMemoCardHint(int count) => ja
      ? (count > 0 ? '📋 ${count}人登録ずみ → タップで開く' : 'タップして顔を登録しよう')
      : (count > 0 ? '📋 $count registered → tap to open' : 'Tap to create a face');
  String get rulebookLabel => ja ? '📖 ルール' : '📖 Rules';
  String get faceMemoLabel => ja ? '🧑‍🎨 顔メモ' : '🧑‍🎨 Face Notes';
  String get supportLabel => ja ? '☕ 支援' : '☕ Support';
  // 🧠 記憶の殿堂（コインで買うプレミアム読み物）
  String get shopKnowledgeTitle =>
      ja ? '🧠 記憶の殿堂 — コインで脳科学を読む' : '🧠 Memory Hall — Brain science for coins';
  String get shopKnowledgeDesc => ja
      ? '名前記憶・脳科学のとっておきの知識。1記事ずつコインでアンロック。'
      : 'Premium brain science & memory insights. Unlock one article at a time with coins.';
  String shopKnowledgeRead(String title) =>
      ja ? '📖 $title を読む' : '📖 Read $title';
  String get shopKnowledgeOwned => ja ? '✅ 読める' : '✅ Readable';
  String get storeBoughtKnowledge => ja
      ? '🧠 知識を手に入れた！タップで読めるよ'
      : '🧠 Knowledge unlocked! Tap to read.';
  // 💰 課金（コインパック・広告除去・プレミアム）
  String get iapCoinsTitle => ja ? '💰 コインを買う' : '💰 Buy Coins';
  String get iapCoinsDesc => ja
      ? 'コインを増やしてキャラや知識をアンロック！'
      : 'Get more coins to unlock characters and knowledge!';
  String get iapRemoveAdsTitle => ja ? '💎 広告を消す（買い切り）' : '💎 Remove Ads (one-time)';
  String get iapRemoveAdsDesc => ja
      ? 'バナー・全画面・動画広告がすべて消えます。アプリがより快適に。'
      : 'Banners, interstitials, and video ads are all gone. Clean experience.';
  String get iapPremiumTitle => ja ? '👑 プレミアム（全部入り）' : '👑 Premium (All-in-One)';
  String get iapPremiumDesc => ja
      ? '広告除去＋全キャラ＋全知識記事＋コイン2000枚。いちばんお得！'
      : 'No ads + All characters + All articles + 2000 coins. Best value!';
  String get iapBuy => ja ? '買う' : 'Buy';
  String get iapOwned => ja ? '✅ 購入済み' : '✅ Purchased';
  String get iapPurchased => ja
      ? '🎉 購入ありがとうございます！'
      : '🎉 Thank you for your purchase!';
  String get iapRestore => ja ? '購入を復元' : 'Restore Purchases';
  String get iapRestoring => ja ? '復元中…' : 'Restoring…';
  String get iapNotAvailable => ja
      ? '課金はスマホアプリでご利用いただけます'
      : 'Purchases available in the mobile app';
  String iapBonusLabel(String bonusPercent) => ja
      ? '（$bonusPercent%お得）'
      : '($bonusPercent% extra)';
  String loginCharProgress(int days, int needed, String emoji) => ja
      ? '$emoji あと${needed - days}日で新キャラ解放'
      : '$emoji ${needed - days} more days to unlock a new character';
  String get exitDialogTitle => ja ? 'もう行っちゃうの？' : 'Leaving already?';
  String get exitDialogBody => ja
      ? '明日も来ると、連続ログインが続いて\nボーナスが大きくなるよ！🪙'
      : 'Come back tomorrow to keep your\nlogin streak and bonus coins! 🪙';
  String get exitDialogStay => ja ? 'もう少しあそぶ' : 'Stay a bit longer';
  String get exitDialogLeave => ja ? 'とじる' : 'Close';
  String get ruleSummary => ja
      ? '💡 ルール：出会った人に名前をつける → もう一度会ったら思い出して答える'
      : '💡 How to: Name each new face → Recall the name when they return';
  String get viewFullRules => ja ? '📖 くわしく見る' : '📖 Full rules';
  String weeklyStatsLine(int learned, int streak) {
    if (ja) {
      final parts = <String>[];
      if (streak > 1) parts.add('🔥 ${streak}日連続');
      if (learned > 0) parts.add('📅 今週${learned}人おぼえた');
      if (parts.isEmpty) parts.add('今日も名前を覚えよう！');
      return parts.join('  ');
    } else {
      final parts = <String>[];
      if (streak > 1) parts.add('🔥 ${streak}-day streak');
      if (learned > 0) parts.add('📅 $learned learned this week');
      if (parts.isEmpty) parts.add('Let\'s learn some names today!');
      return parts.join('  ');
    }
  }
  String characterJoined(String emoji) => ja
      ? '$emoji が仲間になった！'
      : '$emoji joined your party!';
  String get memoryTipHeader => ja ? '🧠 名前を覚えるコツ' : '🧠 Name memory tips';
  String get otherGamesHeader => ja ? '🎮 ほかのあそびかた' : '🎮 More ways to play';
  String get otherGamesBody => ja
      ? 'ビジネス特訓（名刺覚え）・ペアさがし・ものがたり・読みものは 下のタブからどうぞ'
      : 'Business Training, Pair Hunt, Story, and Reading — tap the tabs below';
  String get playReviewButton => ja
      ? '⭐ Google Play で評価する'
      : '⭐ Rate on Google Play';

  // 📮📣 ゲーム内フィードバック＋SNSシェア
  String get feedbackHomeButton => ja ? 'ご意見・不具合' : 'Feedback';
  String get shareAppButton => ja ? '📣 シェア' : '📣 Share';
  String get feedbackTitle => ja ? 'ご意見・不具合を送る' : 'Send feedback';
  String get feedbackHint => ja
      ? '気づいたこと・直してほしいことを教えてください（すぐに直します）'
      : 'Tell us what you noticed or want fixed — we\'ll fix it fast';
  String get feedbackSend => ja ? '送る' : 'Send';
  String get feedbackSending => ja ? '送信中…' : 'Sending…';
  String get feedbackThanks => ja ? '送りました。すぐに直します！' : 'Sent! We\'ll fix it soon.';
  String get shareAppText => ja
      ? '「ペタネーム」で顔と名前を覚えよう！ #なまえがお'
      : 'Learn faces & names with PetaName! #なまえがお';

  // 🧑‍🎨 アバター編集・顔メモの文言（2026-08 英語対応）
  String get avatarEditorFeatureTitle => ja ? 'この人の特徴' : 'Key features';
  String get avatarEditorFeatureHint => ja
      ? 'メガネ・ほくろ・ひげ・髪型をつけると、\n思い出す手がかりになります。'
      : 'Glasses, moles, beards, and hairstyles give you cues to recall.';
  String get avatarEditorConfirmFace => ja ? 'この顔で決定' : 'Use this face';
  String get faceMemoCreateAvatarHint =>
      ja ? '似顔絵をつくる（写真が無いとき）' : 'Create a face (if no photo)';
  String get faceMemoCreateAvatarSub => ja
      ? '職場の人の写真は撮りにくいもの。メガネ・ほくろ・髪型で特徴を残せます'
      : 'Photos at work are awkward — keep their look with glasses, moles, and hair.';
  String get faceMemoCreateAvatar => ja ? '似顔絵をつくる' : 'Create a face';
  String get faceMemoEditFace => ja ? '顔を直す' : 'Edit face';

}
