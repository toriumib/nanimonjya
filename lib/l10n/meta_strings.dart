import 'package:flutter/widgets.dart';

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
  String get freeGift => ja ? '動画で無料コイン🎁' : 'Free coins (video) 🎁';
  String get giftReady => ja ? 'プレゼントがとどいたよ！' : 'A gift is ready!';
  String giftGot(int n) => ja ? '🎉 $nコインもらったよ！' : '🎉 Got $n coins!';
  String giftWaitMin(int m) => ja ? 'つぎは約$m分後' : 'Next in ~${m}min';

  // 招待リンク共有
  String get shareInvite =>
      ja ? '招待リンクを送る' : 'Send invite link';
  String shareInviteText(String code, String link) => ja
      ? 'ペタネームで対戦しよう！🎮\n合言葉: $code\n下のリンクからそのまま入れるよ👇\n$link'
      : "Let's battle in PetaName! 🎮\nRoom code: $code\nTap to join 👇\n$link";

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
  String get decideName => ja ? 'なづける！' : 'Name it!';
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
      ? '【$titleForShare】ペタネームのCPU対戦で勝利！🏆 $score点で無双した😎\nキミは顔と名前、覚えられる？👇'
      : '[$titleForShare] Beat the CPU in PetaName! 🏆 Crushed it with $score pts 😎\nCan you match the faces to the names? 👇';
  String sharePlayed(int players, int topScore) => ja
      ? '【$titleForShare】ペタネームで顔と名前の記憶トレ中！🔥 最高$topScore点\nこの覚えゲー、地味にクセになる…🏷️\nいっしょにあそぼ👇'
      : "[$titleForShare] Training my name-memory in PetaName! 🔥 Top score $topScore\nThis memory game is weirdly addictive 🏷️ Come play 👇";
  String get shareHashtag =>
      ja ? '#ペタネーム #顔と名前の記憶トレ' : '#PetaName #NameMemoryTraining';
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
  String get cpuRankLabel => ja ? 'CPU段位' : 'CPU Rank';
  String get cpuRatingLabel => ja ? 'レーティング' : 'Rating';
  String oniLockedHint(int rating) => ja
      ? 'レーティング$rating以上で解禁'
      : 'Unlocks at rating $rating+';
  String cpuRatingDelta(int delta) =>
      delta >= 0 ? '+$delta' : '$delta';

  String get soloTrainingTitle => ja ? '🧠 一人特訓モード' : '🧠 Solo Training';
  String get soloTrainingDesc => ja
      ? '対戦相手なし。顔と名前のペア当てで、自分のペースで記憶力をきたえよう！'
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

  // 🏷️ ペタネーム: 顔と名前の神経衰弱
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
  String get matchLose => ja ? '🤖 CPUの勝ち…' : '🤖 CPU wins…';
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
      ? 'タグ付け法をガイド付きで練習しながら神経衰弱！'
      : 'Guided tagging practice built into the matching game!';
  String get mnemonicGuideStep1 => ja
      ? '💡 ① 顔の特徴を一言タグに（例：まゆげが太い）'
      : '💡 ① Tag each face with one feature (e.g. "thick brows")';
  String get mnemonicGuideStep2 => ja
      ? '💡 ② タグと名前を連想でつなごう（太まゆ→強そう→高橋さん）'
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
      ? 'ペタネームで対戦しよう！🏷️\nアプリのオンライン対戦で合言葉「$code」を入力してね！'
      : 'Race me in PetaName! 🏷️\nEnter room code "$code" in Online Match!';
  String get roomNotFound => ja
      ? 'その合言葉のへやが見つかりませんでした'
      : 'No room found with that code';
  String waitingOpponentFinish(String name) => ja
      ? '$name がプレイ中…\nおわるまでちょっと待ってね'
      : '$name is still playing…\nHang tight!';
  String get opponentForfeited => ja ? 'とちゅう離脱' : 'Forfeited';
  String get gameStartLabel => ja ? 'ゲームスタート！' : 'Start Game!';

  // 📣 メインモード「なまえコール」
  String get nameCallTitle => ja ? '📣 なまえコール' : '📣 Name Call';
  String get nameCallAsYouGoTitle => ja ? '📣 なづけコール' : '📣 Name-as-you-go';

  // 出たとき命名（ナンジャモンジャ式）
  String get newComer => ja ? '✨ はじめまして！名前をつけてね' : '✨ New face! Give a name';
  String get namedSoFar => ja ? 'なづけ済み' : 'Named';
  String get namingDecide => ja ? 'これにする！' : 'Name it!';
  String get asYouGoHint => ja
      ? '💡 はじめて出た子には名前をつけ、もう一度出てきたら思い出して答えよう！'
      : '💡 Name each new face — when it appears again, recall the name!';
  String get rulePreName => ja ? 'まとめて命名' : 'Name first';
  String get ruleAsYouGo => ja ? '出たとき命名' : 'Name as you go';
  String get ruleLabel => ja ? '命名ルール' : 'Naming rule';
  String get tabNameCall => ja ? 'なまえコール' : 'Name Call';
  String get tabPairs => ja ? 'ペアさがし' : 'Pair Hunt';
  String get tabTraining => ja ? 'とっくん' : 'Training';
  String get tabMyPage => ja ? 'マイページ' : 'My Page';
  String get nameCallCatch => ja
      ? 'みんなに名前をつけて、あとで思い出す。顔と名前をむすびつけて覚えよう！'
      : 'Name everyone, then recall each one. Link every face to its name!';
  String get nameCallRule => ja
      ? '① はじめに全員の顔を見て、順番にすきな名前をつける\n'
          '② つけた名前は「名簿」にひみつで記録（終了までみられない）\n'
          '③ 本編ではランダムにカードが登場\n'
          '④ 名前を思い出せたら1枚ゲット！（2枚同時のときは両方言えたら2枚）\n'
          '⑤ 思い出せないと没収…。獲得枚数がいちばん多い人の勝ち！'
      : '① Look at every face and give each one a name\n'
          '② Names are sealed in a hidden roster until the end\n'
          '③ Two random cards appear each round\n'
          '④ Recall both names = sweep both cards! One name = one card\n'
          '⑤ Miss both and they are discarded. Most cards wins!';
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
  String get missAll => ja ? '💦 おてつき…2枚とも没収' : '💦 Missed… cards discarded';
  String get rosterReveal => ja ? '📖 名簿公開！' : '📖 Roster revealed!';
  String get rosterRevealDesc => ja
      ? 'きみがつけた名前はこちら。おぼえてた？'
      : 'Here are the names you gave. How did you do?';
  String get ryoudoriLabel => ja ? '2枚ゲット' : 'Both-card wins';
  String get cardsWonLabel => ja ? 'かくとく' : 'Cards';
  String get cardsUnit => ja ? '枚' : 'cards';
  String get toResultButton => ja ? 'けっかを見る →' : 'See results →';
  String get nameCallSoloButton => ja ? '👤 ひとりで' : '👤 Solo';
  String get nameCallLocalButton => ja ? '🎉 みんなで（1台）' : '🎉 Party (1 phone)';
  String get nameCallOnlineButton => ja ? '🌐 オンライン' : '🌐 Online';

  // 審判方式（オフライン対戦）
  String get refereePrompt =>
      ja ? 'この子の名前を一斉にコール！' : 'Call out this name together!';
  String refereePromptCard(int n) =>
      ja ? '$n枚目：一斉にコール！' : 'Card $n: call it out!';
  String get refereeHint => ja
      ? '早く正しく呼べた人のボタンを押そう'
      : 'Tap the button of whoever called it first & correctly';
  String playerGot(String p) => ja ? '$p が正解！' : '$p got it!';
  String get nobodyKnew => ja ? 'だれもわからなかった…' : 'Nobody knew…';

  // 人数（カード枚数）
  String peopleCountLabel(int n) => ja ? '$n人' : '$n ppl';

  // 2枚同時オプション
  String get doubleCardLabel => ja ? '2枚同時に出す' : 'Two cards at once';
  String get doubleCardHint => ja
      ? 'ONにすると2枚同時に出現。両方言えたら2枚ゲット！'
      : 'Two cards appear at once. Recall both for a double take!';

  // 📸 おぼえるモード（自分の写真）
  String get tabMemorize => ja ? 'おぼえる' : 'Memorize';
  String get customTitle => ja ? '📸 自分の名簿' : '📸 My Roster';
  String get customDesc => ja
      ? '職場や学校の人の写真と名前を登録して、覚える練習や対戦ができるよ。'
      : 'Add photos & names of people you meet, then study or play with them.';
  String get customMobileOnly => ja
      ? '写真のアップロードはスマホアプリ版でご利用いただけます。'
      : 'Photo upload is available on the mobile app.';
  String get customAddButton => ja ? '＋ 写真と名前を追加' : '+ Add photo & name';
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
  String get recallTitle => ja ? '🧠 思い出しトレーニング' : '🧠 Recall Training';
  String get recallHubDesc => ja
      ? '実際に人と出会うように顔・名前・出会った場所を覚えて、少し時間をおいてから「この人だれだっけ？」を思い出す特訓。現実で名前が出てこない、をなくそう。'
      : 'Meet people like in real life — link face, name and where you met — then recall "who was that again?" after a pause. Beat the moment names slip your mind.';
  String get recallStart => ja ? '出会いに行く →' : 'Go meet them →';
  String get recallMeetTitle => ja ? 'であう' : 'Meet';
  String get recallMeetHint => ja
      ? '出会った人たちです。顔・名前・出会った場所をむすびつけて覚えよう。'
      : 'People you just met. Link each face to a name and where you met.';
  String metAt(String where) => ja ? '$where知り合った' : 'You met them $where.';
  String get recallHobbyLabel => ja ? 'しゅみ' : 'Hobby';
  String get recallRemembered => ja ? 'おぼえた →' : 'Got it →';
  String get recallMeetNext => ja ? 'つぎの人 →' : 'Next person →';
  String get recallGapTitle => ja ? 'しばらく時間がたった…' : 'Some time has passed…';
  String get recallGapSub => ja
      ? 'あの人たち、名前を思い出せるかな？'
      : 'Can you recall their names now?';
  String get recallGapButton => ja ? '思い出す →' : 'Try to recall →';
  String get recallWhoTitle => ja ? 'この人だれだっけ？' : 'Who is this again?';
  String hintMetAt(String where) => ja ? 'ヒント: $where会った人' : 'Hint: you met them $where';
  String get recallResultTitle => ja ? '思い出しレポート' : 'Recall Report';
  String recallCorrectOf(int correct, int total) =>
      ja ? '$total人中 $correct人 思い出せた！' : 'You recalled $correct of $total!';
  String get recallReview => ja ? 'おさらい（顔・名前・場所）' : 'Review (face・name・place)';
  String get recallAgain => ja ? 'もう一度' : 'Again';
  String get recallClose => ja ? 'とじる' : 'Close';
  String get recallEncourageHigh => ja
      ? 'かんぺき！実際に会っても、すぐ名前が出てきますね。'
      : 'Perfect! You’d recall their names in real life, too.';
  String get recallEncourageMid => ja
      ? 'いい調子！出会った場所と結びつけると、もっと思い出しやすくなるよ。'
      : 'Nice! Tie each face to where you met — it makes recall easier.';
  String get recallEncourageLow => ja
      ? '思い出せなくても大丈夫。くり返すほど、名前は出てくるようになります。'
      : 'It’s OK to forget. The more you repeat, the easier names come back.';
  String get businessCardHello => ja ? 'はじめまして' : 'Nice to meet you';
  String get researchTipHeader =>
      ja ? '🔬 研究にもとづく名前のコツ' : '🔬 Research-backed name tip';
  String get sourceLabel => ja ? '出典' : 'Source';
}
