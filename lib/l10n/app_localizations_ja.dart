// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'ナンジャモンジャ風ゲーム';

  @override
  String get playOnline => 'オンラインで遊ぶ';

  @override
  String get playOffline => 'オフラインで遊ぶ';

  @override
  String get roomLobby => 'オンライン対戦ロビー';

  @override
  String get roomId => 'ルームID';

  @override
  String get copyRoomId => 'ルームIDをコピー';

  @override
  String get copiedRoomId => 'ルームIDをコピーしました！';

  @override
  String get waitingForPlayers => '他のプレイヤーを待っています...';

  @override
  String playersNeeded(Object current, Object min) {
    return 'プレイヤーが足りません ($current/$min)';
  }

  @override
  String get startGame => 'ゲーム開始';

  @override
  String get joinRoom => 'ルームに参加';

  @override
  String get enterPasscode => '合言葉を入力';

  @override
  String get uploadImagesPrompt =>
      '必要であれば、ゲームに使用する独自の画像をアップロードしてください。\n(カスタム画像を使用する場合は12枚以上必須)';

  @override
  String uploadedImagesCount(Object count) {
    return 'アップロード済み画像数: $count';
  }

  @override
  String get uploadImage => '画像をアップロード';

  @override
  String get uploading => 'アップロード中...';

  @override
  String get uploadSuccess => '全ての画像のアップロードに成功しました！';

  @override
  String uploadFailed(Object error) {
    return '画像のアップロードに失敗しました: $error';
  }

  @override
  String get createRoom => '新しいルームを作成';

  @override
  String get joinExistingRoom => 'または、合言葉を入力して既存のルームに参加';

  @override
  String get roomNotFound => 'Room not found for the given passcode.';

  @override
  String get roomFull => 'This room is full.';

  @override
  String get roomInGame => 'This room is already in game.';

  @override
  String get alreadyJoined => 'You have already joined this room.';

  @override
  String errorJoiningRoom(Object error) {
    return 'Failed to join room: $error';
  }

  @override
  String get playerCountSelection => 'プレイヤー人数を選択';

  @override
  String get selectPlayerCountPrompt => 'ゲームに参加する人数を選択してください (2人〜6人)';

  @override
  String players(Object count) {
    return '$count 人';
  }

  @override
  String get gameStart => 'ゲーム開始';

  @override
  String get gameResult => 'ゲーム結果';

  @override
  String winner(Object winnerText) {
    return '🏆 $winnerText の勝利！ 🏆';
  }

  @override
  String get noWinner => '勝者なし';

  @override
  String tie(Object winnerText) {
    return '🏆 $winnerText の勝利！ (同点) 🏆';
  }

  @override
  String get andSeparator => ' と ';

  @override
  String get finalScore => '-- 最終スコア --';

  @override
  String playerScore(Object playerNum, Object score) {
    return 'プレイヤー $playerNum: $score 点';
  }

  @override
  String get playAgainSameMembers => 'もう一度同じメンバーで遊ぶ';

  @override
  String get playAgain => 'もう一度遊ぶ';

  @override
  String get voiceMode => '通話モード (AI実況ON)';

  @override
  String get textMode => 'テキストモード (AIの名前生成)';

  @override
  String get firstAppearance => '初登場！名前をつけて！';

  @override
  String get seenBefore => '見たことある！名前は？';

  @override
  String currentFieldCards(Object count) {
    return '現在の場札: $count 枚';
  }

  @override
  String turn(Object turnNum) {
    return 'ターン: $turnNum';
  }

  @override
  String get myNameTurn => 'あなたの番です';

  @override
  String otherPlayersTurn(Object playerNum) {
    return 'プレイヤー$playerNumの番です';
  }

  @override
  String get opponentNaming => '他のプレイヤーが名前をつけています...';

  @override
  String get charNamePrompt => 'キャラクター名 (8文字まで)';

  @override
  String get nameIt => '名前をつける';

  @override
  String get nameTooLong => '名前は1〜8文字で入力してください。';

  @override
  String get get => 'GET!';

  @override
  String get misplay => 'お手つき！';

  @override
  String get skip => 'スキップ';

  @override
  String get skipped => 'スキップ済み';

  @override
  String get answered => '回答済み';

  @override
  String get nextCard => '次のカードをめくる';

  @override
  String get gameEnd => 'ゲーム終了';

  @override
  String get loadingChoices => 'AIが名前を生成中...';

  @override
  String get aiError => 'AIエラー';

  @override
  String get retry => '再試行';

  @override
  String get unknown => '不明';

  @override
  String get you => 'あなた';

  @override
  String player(Object playerNum) {
    return 'プレイヤー$playerNum';
  }

  @override
  String leadingPlayer(Object playerAlias, Object score) {
    return '$playerAliasが$score点でリードしています！';
  }

  @override
  String tieLead(Object players, Object score) {
    return '$playersが$score点で同点リード中！激戦です！';
  }
}
