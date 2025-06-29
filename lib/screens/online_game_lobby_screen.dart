import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'online_game_screen.dart'; // オンラインゲーム本体の画面

// 多言語対応のために追加
import 'package:untitled/l10n/app_localizations.dart';

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
      await _bgmPlayer.setAsset('assets/audio/for_siciliano.mp3'); // BGMファイルのパス
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
    if (images.isEmpty) return;

    // 画像枚数制限のチェック (12枚まで)
    if (images.length > 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.tooManyImages(12))), // ローカライズキーを使用
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    int uploadedCount = 0; // 実際にアップロードされた枚数

    try {
      // Webの場合、全てのバイトデータを事前に読み込む
      List<Uint8List> imageBytesList = [];
      if (kIsWeb) {
        for (final XFile imageFile in images) {
          final Uint8List? bytes = await imageFile.readAsBytes();
          if (bytes == null) {
            debugPrint(
              'Web upload: Failed to read image bytes for ${imageFile.name}. Skipping.',
            );
            continue;
          }
          // Webでの画像サイズ制限チェック
          if (bytes.length > _maxImageSizeBytes) {
            debugPrint(
              'Web upload: Image ${imageFile.name} is too large (${bytes.length} bytes). Skipping.',
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(localizations.imageTooLarge(imageFile.name)),
              ), // ローカライズキーを使用
            );
            continue; // この画像はスキップ
          }
          imageBytesList.add(bytes);
        }
        if (imageBytesList.isEmpty && images.isNotEmpty) {
          // 少なくとも1枚は選択したが、全て読み込みに失敗した場合
          throw Exception(
            'Failed to read any valid image bytes for upload on web.',
          );
        }
      }

      // 選択された各画像をループでアップロード
      // Webとモバイルでループ対象が変わる
      for (int i = 0; i < images.length; i++) {
        final XFile image = images[i];

        // モバイルでの画像サイズ制限チェック
        // kIsWebでなければFileのlengthを確認
        if (!kIsWeb && await image.length() > _maxImageSizeBytes) {
          debugPrint(
            'Mobile upload: Image ${image.name} is too large (${await image.length()} bytes). Skipping.',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizations.imageTooLarge(image.name))),
          ); // ローカライズキーを使用
          continue; // この画像はスキップ
        }

        final String fileName = '${_uuid.v4()}.jpg';
        final Reference ref = _storage
            .ref()
            .child('game_images')
            .child(fileName);

        UploadTask uploadTask;
        if (kIsWeb) {
          // imageBytesList[uploadedCount] は、アップロード済み枚数ではなく、
          // 選択された images リストと imageBytesList のインデックスi を使うべき
          // ただし、continue でスキップされた画像がある場合、imageBytesList のインデックスと images のインデックスがずれる
          // そのため、uploadedCount を使って imageBytesList の正しい要素を参照するロジックに変更
          uploadTask = ref.putData(
            imageBytesList[uploadedCount],
          ); // 事前に読み込んだバイトデータを使用
        } else {
          uploadTask = ref.putFile(File(image.path));
        }

        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();

        setState(() {
          _uploadedImageUrls.add(downloadUrl); // アップロード成功したURLを追加
        });
        uploadedCount++; // 実際にアップロードできた枚数をカウント
      }

      setState(() {
        _isUploading = false;
      });
      if (uploadedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.uploadSuccessWithCount(uploadedCount)),
          ),
        ); // ローカライズキーを使用
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.noImagesUploaded),
          ), // ローカライズキーを使用
        );
      }
    } catch (e) {
      debugPrint('画像のアップロードに失敗しました: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.uploadFailed(e.toString())),
        ), // ローカライズキーを使用
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
          SnackBar(
            content: Text(localizations.customImagesMin(12)),
          ), // ローカライズキーを使用
        );
        return;
      }
      finalImageUrls = _uploadedImageUrls;
    } else {
      finalImageUrls = _defaultCharacterImageFiles;
    }

    try {
      await _firestore.collection('rooms').doc(roomId).set({
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'waiting',
        'players': [],
        'imageUrls': finalImageUrls,
        'deck': [],
        'fieldCards': [],
        'seenImages': [],
        'scores': {},
        'currentCard': null,
        'isFirstAppearance': true,
        'canSelectPlayer': false,
        'turnCount': 0,
        'gameStarted': false,
        'gameMode': _isVoiceMode ? 'voice' : 'text',
        'characterNames': {},
        'playerOrder': [],
        'currentPlayerIndex': 0,
        'readyPlayerIds': [],
      });
      _joinRoom(roomId);
    } catch (e) {
      debugPrint('ルームの作成に失敗しました: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.errorCreatingRoom(e.toString())),
        ), // ローカライズキーを使用
      );
    }
  }

  /// 既存のルームに合言葉で参加します。
  /// ルームが存在し、かつ満員でない場合にのみ参加を許可します。
  Future<void> _joinRoom(String roomId) async {
    final localizations = AppLocalizations.of(context)!;

    DocumentReference roomRef = _firestore.collection('rooms').doc(roomId);

    try {
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot freshSnap = await transaction.get(roomRef);

        if (!freshSnap.exists) {
          throw Exception(localizations.roomNotFoundForPasscode); // ローカライズキーを使用
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

        final String myPlayerId = 'player_${_uuid.v4().substring(0, 8)}';

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
              isVoiceMode: roomData['gameMode'] == 'voice',
            ),
          ),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.errorJoiningRoom(e.toString())),
        ), // ローカライズキーを使用
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(localizations.roomLobby)),
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
