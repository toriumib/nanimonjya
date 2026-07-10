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
      ? 'なまえで覚える♪ 神経衰弱バトル'
      : 'Name & Remember! Memory Battle';

  // 🎁 無料コインチェスト
  String get freeGift => ja ? '動画で無料コイン🎁' : 'Free coins (video) 🎁';
  String get giftReady => ja ? 'プレゼントがとどいたよ！' : 'A gift is ready!';
  String giftGot(int n) => ja ? '🎉 $nコインもらったよ！' : '🎉 Got $n coins!';
  String giftWaitMin(int m) => ja ? 'つぎは約$m分後' : 'Next in ~${m}min';

  // 招待リンク共有
  String get shareInvite =>
      ja ? '招待リンクを送る' : 'Send invite link';
  String shareInviteText(String code, String link) => ja
      ? 'ナニモンジャで対戦しよう！🎮\n合言葉: $code\n下のリンクからそのまま入れるよ👇\n$link'
      : "Let's battle in Nanimonja! 🎮\nRoom code: $code\nTap to join 👇\n$link";

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
  String get nicknameLabel => ja ? 'ランキング表示名' : 'Display name';
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
      ? '【$titleForShare】ナニモンジャ$players人対戦で優勝！🏆 $score点で無双した😎\nキミはなまえ、覚えられる？👇'
      : '[$titleForShare] Won a $players-player Nanimonja match! 🏆 Crushed it with $score pts 😎\nThink you can remember the names? 👇';
  String sharePlayed(int players, int topScore) => ja
      ? '【$titleForShare】ナニモンジャで白熱の$players人対戦！🔥 最高$topScore点\nこの覚えゲー、地味にクセになる…🃏\nいっしょにあそぼ👇'
      : "[$titleForShare] Intense $players-player Nanimonja match! 🔥 Top score $topScore\nThis memory game is weirdly addictive 🃏 Come play 👇";
  String get shareHashtag =>
      ja ? '#ナニモンジャ #名付け神経衰弱' : '#Nanimonja #NameMemoryGame';
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
      default:
        return '';
    }
  }
}
