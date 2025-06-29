// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Nanjamonja Game';

  @override
  String get playOnline => 'Play Online';

  @override
  String get playOffline => 'Play Offline';

  @override
  String get roomLobby => 'Online Battle Lobby';

  @override
  String get roomId => 'Room ID';

  @override
  String get copyRoomId => 'Copy Room ID';

  @override
  String get copiedRoomId => 'Room ID copied!';

  @override
  String get waitingForPlayers => 'Waiting for other players...';

  @override
  String playersNeeded(Object current, Object min) {
    return 'Players needed ($current/$min)';
  }

  @override
  String get startGame => 'Start Game';

  @override
  String get joinRoom => 'Join Room';

  @override
  String get enterPasscode => 'Enter Passcode';

  @override
  String get uploadImagesPrompt =>
      'Optionally, upload your own images for the game.\n(12+ images required for custom sets)';

  @override
  String uploadedImagesCount(Object count) {
    return 'Uploaded images: $count';
  }

  @override
  String get uploadImage => 'Upload Image(s)';

  @override
  String get uploading => 'Uploading...';

  @override
  String get uploadSuccess => 'All images uploaded successfully!';

  @override
  String uploadFailed(Object error) {
    return 'Image upload failed: $error';
  }

  @override
  String get createRoom => 'Create New Room';

  @override
  String get joinExistingRoom => 'Or, join an existing room with a passcode';

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
  String get playerCountSelection => 'Select Number of Players';

  @override
  String get selectPlayerCountPrompt => 'Select the number of players (2-6)';

  @override
  String players(Object count) {
    return '$count Players';
  }

  @override
  String get gameStart => 'Start Game';

  @override
  String get gameResult => 'Game Result';

  @override
  String winner(Object winnerText) {
    return '$winnerText Wins!';
  }

  @override
  String get noWinner => 'No Winner';

  @override
  String tie(Object winnerText) {
    return '$winnerText Tie!';
  }

  @override
  String get andSeparator => ' and ';

  @override
  String get finalScore => '-- Final Score --';

  @override
  String playerScore(Object playerNum, Object score) {
    return 'Player $playerNum: $score Points';
  }

  @override
  String get playAgainSameMembers => 'Play Again with Same Members';

  @override
  String get playAgain => 'Play Again';

  @override
  String get voiceMode => 'Voice Mode (AI Commentary ON)';

  @override
  String get textMode => 'Text Mode (AI Name Generation)';

  @override
  String get firstAppearance => 'First appearance! Name it!';

  @override
  String get seenBefore => 'Seen before! What\'s the name?';

  @override
  String currentFieldCards(Object count) {
    return 'Current Field Cards: $count';
  }

  @override
  String turn(Object turnNum) {
    return 'Turn: $turnNum';
  }

  @override
  String get myNameTurn => 'It\'s your turn next!';

  @override
  String otherPlayersTurn(Object playerNum) {
    return 'It\'s Player $playerNum\'s turn next!';
  }

  @override
  String get opponentNaming => 'Other players are naming...';

  @override
  String get charNamePrompt => 'Character Name (up to 8 chars)';

  @override
  String get nameIt => 'Name it';

  @override
  String get nameTooLong => 'Name must be 1-8 characters.';

  @override
  String get get => 'GET!';

  @override
  String get misplay => 'Misplay!';

  @override
  String get skip => 'Skip';

  @override
  String get skipped => 'Skipped';

  @override
  String get answered => 'Answered';

  @override
  String get nextCard => 'Next Card';

  @override
  String get gameEnd => 'Game End';

  @override
  String get loadingChoices => 'Generating AI choices...';

  @override
  String get aiError => 'AI Error';

  @override
  String get retry => 'Retry';

  @override
  String get unknown => 'Unknown';

  @override
  String get you => 'You';

  @override
  String player(Object playerNum) {
    return 'Player $playerNum';
  }

  @override
  String leadingPlayer(Object playerAlias, Object score) {
    return '$playerAlias is leading with $score points!';
  }

  @override
  String tieLead(Object players, Object score) {
    return '$players are tied for the lead with $score points!';
  }
}
