import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuthをインポート
import 'package:flutter/foundation.dart'; // kIsWebのために追加
import 'package:just_audio/just_audio.dart'; // BGMのために追加

import 'online_game_screen.dart'; // オンラインゲーム本体の画面
import 'top_screen.dart'; // Top画面に戻るため追加

// 多言語対応のために追加
import 'package:untitled/l10n/app_localizations.dart'; // プロジェクトの実際のパスに合わせてください

class OnlineGameLobbyScreen extends StatefulWidget {
  const OnlineGameLobbyScreen({super.key});

  @override
  State<OnlineGameLobbyScreen> createState() => _OnlineGameLobbyScreenState();
}

class _OnlineGameLobbyScreenState extends State<OnlineGameLobbyScreen> {
  final TextEditingController _roomIdController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();
  final AudioPlayer _bgmPlayer = AudioPlayer(); // BGM用のAudioPlayerを追加

  final List<String> _defaultCharacterImageFiles = List.generate(
    12,
    (index) => 'assets/images/char${index + 1}.jpg',
  );

  List<String> _uploadedImageUrls = [];
  bool _isUploading = false;
  bool _isVoiceMode = false; // デフォルトをテキストモード (false) に変更

  // 画像の最大サイズ (5MB)
  static const int _maxImageSizeBytes = 5 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    _startBGM(); // BGM再生を開始
  }

  @override
  void dispose() {
    _roomIdController.dispose();
    _bgmPlayer.dispose(); // BGM用プレイヤーを解放
    super.dispose();
  }

  // BGM再生用のメソッド
  Future<void> _startBGM() async {
    try {
      await _bgmPlayer.setAsset(
        'assets/audio/op9-2-Nocturne.mp3',
      ); // BGMファイルのパス
      _bgmPlayer.setLoopMode(LoopMode.one); // ループ再生
      _bgmPlayer.setVolume(0.5); // 音量を調整 (0.0 から 1.0)
      _bgmPlayer.play();
    } catch (e) {
      debugPrint("Error loading BGM: $e");
    }
  }

  /// 画像をFirebase Storageにアップロードする機能
  /// ギャラリーから複数画像を選択し、Storageに保存し、そのURLを状態に保持します。
  Future<void> _uploadImage() async {
    final localizations = AppLocalizations.of(context)!; // 多言語対応のインスタンス

    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("noImagesSelected")));
      return;
    }

    // 画像枚数制限のチェック (12枚まで)
    if (images.length > 12) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(localizations.tooManyImages(12))));
      return;
    }

    setState(() {
      _isUploading = true;
    });

    List<String> successfullyUploadedUrls = []; // 今回のバッチでアップロードに成功したURLを追跡

    try {
      for (final XFile imageFile in images) {
        Uint8List? bytes;
        int fileSize = 0;

        if (kIsWeb) {
          bytes = await imageFile.readAsBytes();
          if (bytes == null) {
            debugPrint(
              'Web upload: Failed to read image bytes for ${imageFile.name}. Skipping.',
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(localizations.imageTooLarge(imageFile.name)),
              ),
            );
            continue; // この画像はスキップ
          }
          fileSize = bytes.length;
        } else {
          fileSize = await File(imageFile.path).length();
        }

        // 画像サイズ制限のチェック
        if (fileSize > _maxImageSizeBytes) {
          debugPrint(
            'Image ${imageFile.name} is too large ($fileSize bytes). Skipping.',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.imageTooLarge(imageFile.name)),
            ),
          );
          continue; // この画像はスキップ
        }

        final String fileName = '${_uuid.v4()}.jpg';
        final Reference ref = _storage
            .ref()
            .child('game_images')
            .child(fileName);

        UploadTask uploadTask;
        if (kIsWeb) {
          uploadTask = ref.putData(bytes!); // bytesはnullチェック済み
        } else {
          uploadTask = ref.putFile(File(imageFile.path));
        }

        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        successfullyUploadedUrls.add(downloadUrl); // アップロード成功したURLを追加
      }

      setState(() {
        _uploadedImageUrls.addAll(
          successfullyUploadedUrls,
        ); // 既存リストに今回成功したURLを追加
        _isUploading = false;
      });

      if (successfullyUploadedUrls.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations.uploadSuccessWithCount(
                successfullyUploadedUrls.length,
              ),
            ),
          ),
        );
      } else if (images.isNotEmpty) {
        // ユーザーが画像を選択したが、全てバリデーションで弾かれた場合
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(localizations.noImagesUploaded)));
      }
    } catch (e) {
      debugPrint('画像のアップロード中にエラーが発生しました: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.uploadFailed(e.toString()))),
      );
      setState(() {
        _isUploading = false;
      });
    }
  }

  /// 新しいルームを作成し、そのルームに参加します。
  /// 画像がアップロードされていない場合は、デフォルトの画像パスを使用します。
  /// ユーザーがカスタム画像をアップロードした場合は、12枚以上の画像が必要となります。
  Future<void> _createRoom() async {
    final localizations = AppLocalizations.of(context)!;

    final String roomId = _uuid.v4().substring(0, 6).toUpperCase();

    List<String> finalImageUrls;
    if (_uploadedImageUrls.isNotEmpty) {
      if (_uploadedImageUrls.length < 12) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.customImagesMin(12))),
        );
        return;
      }
      finalImageUrls = _uploadedImageUrls;
    } else {
      finalImageUrls = _defaultCharacterImageFiles;
    }

    try {
      // 匿名認証でサインインを試みる
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        user = (await FirebaseAuth.instance.signInAnonymously()).user;
        if (user == null) {
          throw Exception('認証に失敗しました。'); // ローカライズが必要な場合は追加
        }
      }
      final String myPlayerId = user.uid; // Firebase AuthenticationのUIDを使用

      // ルームの初期状態をFirestoreに設定
      await _firestore.collection('rooms').doc(roomId).set({
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'waiting', // 初期状態は'waiting'
        'players': [myPlayerId], // 作成者を最初のプレイヤーとして追加
        'imageUrls': finalImageUrls, // 使用する画像URL/パスリスト
        'deck': [], // ゲーム開始時にシャッフルされたデッキ
        'fieldCards': [], // 場札
        'seenImages': [], // 見たことのある画像
        'scores': {myPlayerId: 0}, // 作成者の初期スコアを設定
        'currentCard': null, // 現在表示中のカード
        'isFirstAppearance': true,
        'canSelectPlayer': false,
        'turnCount': 0,
        'gameStarted': false, // ゲームが開始されたかどうかのフラグ
        'gameMode': _isVoiceMode ? 'voice' : 'text', // ゲームモードを保存
        'characterNames': {}, // キャラクター名を保存するマップ
        'playerOrder': [], // ターン順序を保存するリスト
        'currentPlayerIndex': 0, // 現在のターンプレイヤーのインデックス
        'readyPlayerIds': [], // 準備完了プレイヤーのIDリスト
      });

      // 作成後、自動的にゲーム画面へ遷移
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OnlineGameScreen(
            roomId: roomId,
            myPlayerId: myPlayerId,
            isVoiceMode: _isVoiceMode,
          ), // ゲームモードを渡す
        ),
      );
    } catch (e) {
      debugPrint('ルームの作成に失敗しました: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.errorCreatingRoom(e.toString()))),
      );
    }
  }

  /// 既存のルームに合言葉で参加します。
  /// ルームが存在し、かつ満員でない場合にのみ参加を許可します。
  Future<void> _joinRoom(String roomId) async {
    final localizations = AppLocalizations.of(context)!;

    DocumentReference roomRef = _firestore.collection('rooms').doc(roomId);

    try {
      // 匿名認証でサインインを試みる
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        user = (await FirebaseAuth.instance.signInAnonymously()).user;
        if (user == null) {
          throw Exception('認証に失敗しました。'); // ローカライズが必要な場合は追加
        }
      }
      final String myPlayerId = user.uid; // Firebase AuthenticationのUIDを使用

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot freshSnap = await transaction.get(roomRef);

        if (!freshSnap.exists) {
          throw Exception(localizations.roomNotFoundForPasscode);
        }

        Map<String, dynamic> roomData =
            freshSnap.data() as Map<String, dynamic>;
        List<dynamic> players = roomData['players'] ?? [];

        if (players.length >= 6) {
          throw Exception(localizations.roomFull);
        }
        if (roomData['status'] == 'playing') {
          throw Exception(localizations.roomInGame);
        }

        // 既にこのIDが参加者リストにあるかチェック（同一デバイスからの再接続など）
        if (players.contains(myPlayerId)) {
          debugPrint('既にこのプレイヤーはルームに参加しています。');
        } else {
          players.add(myPlayerId);
          Map<String, dynamic> scores = roomData['scores'] ?? {};
          scores[myPlayerId] = 0;

          transaction.update(roomRef, {'players': players, 'scores': scores});
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OnlineGameScreen(
              roomId: roomId,
              myPlayerId: myPlayerId,
              isVoiceMode: roomData['gameMode'] == 'voice', // ルームのゲームモードを渡す
            ),
          ),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.errorJoiningRoom(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.roomLobby),
        leading: IconButton(
          icon: const Icon(Icons.home), // ホームアイコン
          onPressed: () {
            // トップ画面に戻る (他の画面スタックを全てクリア)
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const TopScreen()),
              (Route<dynamic> route) => false,
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // ゲームモード選択トグル
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(localizations.textMode),
                Switch(
                  value: _isVoiceMode,
                  onChanged: (bool newValue) {
                    setState(() {
                      _isVoiceMode = newValue;
                    });
                  },
                ),
                Text(localizations.voiceMode),
              ],
            ),
            const SizedBox(height: 20),

            Text(
              localizations.uploadImagesPrompt,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _uploadImage,
              icon: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.upload_file),
              label: Text(
                _isUploading
                    ? localizations.uploading
                    : localizations.uploadImage,
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              localizations.uploadedImagesCount(_uploadedImageUrls.length),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            if (_uploadedImageUrls.isNotEmpty)
              Container(
                height: 100,
                margin: const EdgeInsets.only(top: 10),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _uploadedImageUrls.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Image.network(
                        _uploadedImageUrls[index],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: _createRoom,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
                backgroundColor: Colors.green,
              ),
              child: Text(localizations.createRoom),
            ),
            const SizedBox(height: 40),

            Text(
              localizations.joinExistingRoom,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _roomIdController,
              decoration: InputDecoration(
                labelText: localizations.enterPasscode,
                border: const OutlineInputBorder(),
                hintText: '例: ABCDEF',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _joinRoom(_roomIdController.text.trim()),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: Text(localizations.joinRoom),
            ),
          ],
        ),
      ),
    );
  }
}
