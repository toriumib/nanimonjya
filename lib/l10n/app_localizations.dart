import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Nanjamonja Game'**
  String get appTitle;

  /// No description provided for @playOnline.
  ///
  /// In en, this message translates to:
  /// **'Play Online'**
  String get playOnline;

  /// No description provided for @playOffline.
  ///
  /// In en, this message translates to:
  /// **'Play Offline'**
  String get playOffline;

  /// No description provided for @roomLobby.
  ///
  /// In en, this message translates to:
  /// **'Online Battle Lobby'**
  String get roomLobby;

  /// No description provided for @roomId.
  ///
  /// In en, this message translates to:
  /// **'Room ID'**
  String get roomId;

  /// No description provided for @copyRoomId.
  ///
  /// In en, this message translates to:
  /// **'Copy Room ID'**
  String get copyRoomId;

  /// No description provided for @copiedRoomId.
  ///
  /// In en, this message translates to:
  /// **'Room ID copied!'**
  String get copiedRoomId;

  /// No description provided for @waitingForPlayers.
  ///
  /// In en, this message translates to:
  /// **'Waiting for other players...'**
  String get waitingForPlayers;

  /// No description provided for @playersNeeded.
  ///
  /// In en, this message translates to:
  /// **'Players needed ({current}/{min})'**
  String playersNeeded(Object current, Object min);

  /// No description provided for @startGame.
  ///
  /// In en, this message translates to:
  /// **'Start Game'**
  String get startGame;

  /// No description provided for @joinRoom.
  ///
  /// In en, this message translates to:
  /// **'Join Room'**
  String get joinRoom;

  /// No description provided for @enterPasscode.
  ///
  /// In en, this message translates to:
  /// **'Enter Passcode'**
  String get enterPasscode;

  /// No description provided for @uploadImagesPrompt.
  ///
  /// In en, this message translates to:
  /// **'Optionally, upload your own images for the game.\n(12+ images required for custom sets)'**
  String get uploadImagesPrompt;

  /// No description provided for @uploadedImagesCount.
  ///
  /// In en, this message translates to:
  /// **'Uploaded images: {count}'**
  String uploadedImagesCount(Object count);

  /// No description provided for @uploadImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Image(s)'**
  String get uploadImage;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploading;

  /// No description provided for @uploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'All images uploaded successfully!'**
  String get uploadSuccess;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Image upload failed: {error}'**
  String uploadFailed(Object error);

  /// No description provided for @createRoom.
  ///
  /// In en, this message translates to:
  /// **'Create New Room'**
  String get createRoom;

  /// No description provided for @joinExistingRoom.
  ///
  /// In en, this message translates to:
  /// **'Or, join an existing room with a passcode'**
  String get joinExistingRoom;

  /// No description provided for @roomNotFound.
  ///
  /// In en, this message translates to:
  /// **'Room not found for the given passcode.'**
  String get roomNotFound;

  /// No description provided for @roomFull.
  ///
  /// In en, this message translates to:
  /// **'This room is full.'**
  String get roomFull;

  /// No description provided for @roomInGame.
  ///
  /// In en, this message translates to:
  /// **'This room is already in game.'**
  String get roomInGame;

  /// No description provided for @alreadyJoined.
  ///
  /// In en, this message translates to:
  /// **'You have already joined this room.'**
  String get alreadyJoined;

  /// No description provided for @errorJoiningRoom.
  ///
  /// In en, this message translates to:
  /// **'Failed to join room: {error}'**
  String errorJoiningRoom(Object error);

  /// No description provided for @playerCountSelection.
  ///
  /// In en, this message translates to:
  /// **'Select Number of Players'**
  String get playerCountSelection;

  /// No description provided for @selectPlayerCountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select the number of players (2-6)'**
  String get selectPlayerCountPrompt;

  /// No description provided for @players.
  ///
  /// In en, this message translates to:
  /// **'{count} Players'**
  String players(Object count);

  /// No description provided for @gameStart.
  ///
  /// In en, this message translates to:
  /// **'Start Game'**
  String get gameStart;

  /// No description provided for @gameResult.
  ///
  /// In en, this message translates to:
  /// **'Game Result'**
  String get gameResult;

  /// No description provided for @winner.
  ///
  /// In en, this message translates to:
  /// **'{winnerText} Wins!'**
  String winner(Object winnerText);

  /// No description provided for @noWinner.
  ///
  /// In en, this message translates to:
  /// **'No Winner'**
  String get noWinner;

  /// No description provided for @tie.
  ///
  /// In en, this message translates to:
  /// **'{winnerText} Tie!'**
  String tie(Object winnerText);

  /// No description provided for @finalScore.
  ///
  /// In en, this message translates to:
  /// **'-- Final Score --'**
  String get finalScore;

  /// No description provided for @playerScore.
  ///
  /// In en, this message translates to:
  /// **'Player {playerNum}: {score} Points'**
  String playerScore(Object playerNum, Object score);

  /// No description provided for @playAgainSameMembers.
  ///
  /// In en, this message translates to:
  /// **'Play Again with Same Members'**
  String get playAgainSameMembers;

  /// No description provided for @playAgain.
  ///
  /// In en, this message translates to:
  /// **'Play Again'**
  String get playAgain;

  /// No description provided for @voiceMode.
  ///
  /// In en, this message translates to:
  /// **'Voice Mode (AI Commentary ON)'**
  String get voiceMode;

  /// No description provided for @textMode.
  ///
  /// In en, this message translates to:
  /// **'Text Mode (AI Name Generation)'**
  String get textMode;

  /// No description provided for @firstAppearance.
  ///
  /// In en, this message translates to:
  /// **'First appearance! Name it!'**
  String get firstAppearance;

  /// No description provided for @seenBefore.
  ///
  /// In en, this message translates to:
  /// **'Seen before! What\'s the name?'**
  String get seenBefore;

  /// No description provided for @currentFieldCards.
  ///
  /// In en, this message translates to:
  /// **'Current Field Cards: {count}'**
  String currentFieldCards(Object count);

  /// No description provided for @turn.
  ///
  /// In en, this message translates to:
  /// **'Turn: {turnNum}'**
  String turn(Object turnNum);

  /// No description provided for @myNameTurn.
  ///
  /// In en, this message translates to:
  /// **'It\'s your turn next!'**
  String get myNameTurn;

  /// No description provided for @otherPlayersTurn.
  ///
  /// In en, this message translates to:
  /// **'It\'s Player {playerNum}\'s turn next!'**
  String otherPlayersTurn(Object playerNum);

  /// No description provided for @opponentNaming.
  ///
  /// In en, this message translates to:
  /// **'Other players are naming...'**
  String get opponentNaming;

  /// No description provided for @charNamePrompt.
  ///
  /// In en, this message translates to:
  /// **'Character Name (up to 8 chars)'**
  String get charNamePrompt;

  /// No description provided for @nameIt.
  ///
  /// In en, this message translates to:
  /// **'Name it'**
  String get nameIt;

  /// No description provided for @nameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Name must be 1-8 characters.'**
  String get nameTooLong;

  /// No description provided for @get.
  ///
  /// In en, this message translates to:
  /// **'GET!'**
  String get get;

  /// No description provided for @misplay.
  ///
  /// In en, this message translates to:
  /// **'Misplay!'**
  String get misplay;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @skipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get skipped;

  /// No description provided for @answered.
  ///
  /// In en, this message translates to:
  /// **'Answered'**
  String get answered;

  /// No description provided for @nextCard.
  ///
  /// In en, this message translates to:
  /// **'Next Card'**
  String get nextCard;

  /// No description provided for @gameEnd.
  ///
  /// In en, this message translates to:
  /// **'Game End'**
  String get gameEnd;

  /// No description provided for @loadingChoices.
  ///
  /// In en, this message translates to:
  /// **'Generating AI choices...'**
  String get loadingChoices;

  /// No description provided for @aiError.
  ///
  /// In en, this message translates to:
  /// **'AI Error'**
  String get aiError;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
