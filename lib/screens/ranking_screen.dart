import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/meta_strings.dart';
import '../services/player_profile.dart';
import '../services/ranking_service.dart';
import '../services/sfx.dart';

/// ランダムマッチの全体ランキング画面。
class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: PlayerProfile.instance.nickname);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveName(MetaStrings m) async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    await PlayerProfile.instance.setNickname(name);
    await RankingService.instance.updateNameOnly(name);
    Sfx.instance.pop();
    if (mounted) {
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(m.nameSaved)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: Text('🏅 ${m.ranking}')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF3D6), Color(0xFFFFE3F0), Color(0xFFEAF7FF)],
          ),
        ),
        child: Column(
          children: [
            // 自分のレーティング＋なまえ設定
            Card(
              margin: const EdgeInsets.all(12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedBuilder(
                      animation: PlayerProfile.instance,
                      builder: (context, _) => Row(
                        children: [
                          const Text('⭐', style: TextStyle(fontSize: 28)),
                          const SizedBox(width: 8),
                          Text(
                            '${m.myRating}: ${PlayerProfile.instance.rankRating}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFB4326E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameCtrl,
                            maxLength: 12,
                            decoration: InputDecoration(
                              isDense: true,
                              labelText: m.nicknameLabel,
                              border: const OutlineInputBorder(),
                              counterText: '',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _saveName(m),
                          child: Text(m.save),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  m.rankingTop50,
                  style: const TextStyle(
                      fontSize: 13, color: Colors.black54),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // ランキング一覧
            Expanded(
              child: StreamBuilder<List<RankingEntry>>(
                stream: RankingService.instance.topPlayers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(m.rankingUnavailable,
                            textAlign: TextAlign.center),
                      ),
                    );
                  }
                  final list = snapshot.data ?? [];
                  if (list.isEmpty) {
                    return Center(child: Text(m.rankingEmpty));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final e = list[i];
                      final isMe = e.uid == myUid;
                      final medal = i == 0
                          ? '🥇'
                          : i == 1
                              ? '🥈'
                              : i == 2
                                  ? '🥉'
                                  : '${i + 1}';
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 3),
                        decoration: BoxDecoration(
                          color: isMe
                              ? const Color(0xFFFFF0B8)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isMe
                                ? const Color(0xFFE6B54A)
                                : Colors.grey.shade200,
                            width: isMe ? 2 : 1,
                          ),
                        ),
                        child: ListTile(
                          leading: SizedBox(
                            width: 34,
                            child: Center(
                              child: Text(
                                medal,
                                style: TextStyle(
                                  fontSize: i < 3 ? 24 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            e.name + (isMe ? ' (${m.you})' : ''),
                            style: TextStyle(
                              fontWeight: isMe
                                  ? FontWeight.w900
                                  : FontWeight.bold,
                            ),
                          ),
                          subtitle: Text('${e.wins}勝 ${e.losses}敗'),
                          trailing: Text(
                            '⭐${e.rating}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFB4326E),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
