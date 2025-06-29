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
import 'package:untitled/l10n/app_localizations.dart'; // ★パス修正済み★

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
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isEmpty) return;

    setState(() {
      _isUploading = true;
    });

    try {
      for (final XFile image in images) {
        final String fileName = '${_uuid.v4()}.jpg';
        final Reference ref = _storage
            .ref()
            .child('game_images')
            .child(fileName);

        UploadTask uploadTask;
        if (kIsWeb) {
          final Uint8List? bytes = await image.readAsBytes();
          if (bytes == null) {
            debugPrint(
              'Web upload: Failed to read image bytes for ${image.name}. Skipping.',
            );
            continue;
          }
          uploadTask = ref.putData(bytes);
        } else {
          uploadTask = ref.putFile(File(image.path));
        }

        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();

        setState(() {
          _uploadedImageUrls.add(downloadUrl);
        });
      }

      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('全ての画像のアップロードに成功しました！')));
    } catch (e) {
      debugPrint('画像のアップロードに失敗しました: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('画像のアップロードに失敗しました: ${e.toString()}')),
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
    final String roomId = _uuid.v4().substring(0, 6).toUpperCase();

    List<String> finalImageUrls;
    if (_uploadedImageUrls.isNotEmpty) {
      if (_uploadedImageUrls.length < 12) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('カスタム画像を使用する場合、12枚以上の画像をアップロードしてください。')),
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
      });
      _joinRoom(roomId);
    } catch (e) {
      debugPrint('ルームの作成に失敗しました: ${e.toString()}');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ルームの作成に失敗しました: ${e.toString()}')));
    }
  }

  /// 既存のルームに合言葉で参加します。
  /// ルームが存在し、かつ満員でない場合にのみ参加を許可します。
  Future<void> _joinRoom(String roomId) async {
    DocumentReference roomRef = _firestore.collection('rooms').doc(roomId);

    try {
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot freshSnap = await transaction.get(roomRef);

        if (!freshSnap.exists) {
          throw Exception('指定された合言葉のルームが見つかりません。');
        }

        Map<String, dynamic> roomData =
            freshSnap.data() as Map<String, dynamic>;
        List<dynamic> players = roomData['players'] ?? [];

        if (players.length >= 6) {
          throw Exception('このルームは満員です。');
        }
        if (roomData['status'] == 'playing') {
          throw Exception('このルームは既にゲーム中です。');
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
        SnackBar(content: Text('ルームへの参加に失敗しました: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!; // 多言語対応のインスタンス

    return Scaffold(
      appBar: AppBar(title: Text(localizations.roomLobby)), // ★修正★
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // ゲームモード選択トグル
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(localizations.textMode), // ★修正★
                Switch(
                  value: _isVoiceMode,
                  onChanged: (bool newValue) {
                    setState(() {
                      _isVoiceMode = newValue;
                    });
                  },
                ),
                Text(localizations.voiceMode), // ★修正★
              ],
            ),
            const SizedBox(height: 20),

            Text(
              localizations.uploadImagesPrompt, // ★修正★
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
              ), // ★修正★
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              localizations.uploadedImagesCount(
                _uploadedImageUrls.length,
              ), // ★修正★
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
              child: Text(localizations.createRoom), // ★修正★
            ),
            const SizedBox(height: 40),

            Text(
              localizations.joinExistingRoom, // ★修正★
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _roomIdController,
              decoration: InputDecoration(
                labelText: localizations.enterPasscode, // ★修正★
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
              child: Text(localizations.joinRoom), // ★修正★
            ),
          ],
        ),
      ),
    );
  }
}
