import 'package:flutter/material.dart';
import '../l10n/meta_strings.dart';
import '../services/name_album_service.dart';
import '../services/sfx.dart';

/// 📖 みんなの珍名アルバム（今週の爆笑ネーム大賞）
class NameAlbumScreen extends StatelessWidget {
  const NameAlbumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('📖 ${m.nameAlbum}')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF6D8), Color(0xFFFFE3F0), Color(0xFFEAF7FF)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Text(
                '👑 ${m.weeklyAward}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFB4326E),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                m.nameAlbumDesc,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: StreamBuilder<List<FunnyName>>(
                stream: NameAlbumService.instance.weeklyTop(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text(m.rankingUnavailable));
                  }
                  final list = snapshot.data ?? [];
                  if (list.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(m.nameAlbumEmpty,
                            textAlign: TextAlign.center),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final e = list[i];
                      final medal = i == 0
                          ? '🥇'
                          : i == 1
                              ? '🥈'
                              : i == 2
                                  ? '🥉'
                                  : '';
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 3),
                        decoration: BoxDecoration(
                          color: i < 3
                              ? const Color(0xFFFFF0B8)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: i < 3
                                ? const Color(0xFFE6B54A)
                                : Colors.grey.shade200,
                            width: i < 3 ? 2 : 1,
                          ),
                        ),
                        child: ListTile(
                          leading: Text(
                            medal.isEmpty ? '${i + 1}' : medal,
                            style: TextStyle(
                              fontSize: i < 3 ? 24 : 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                          title: Text(
                            e.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          trailing: TextButton.icon(
                            onPressed: () async {
                              final ok = await NameAlbumService.instance
                                  .like(e.id);
                              if (ok) Sfx.instance.pop();
                            },
                            icon: const Text('❤️',
                                style: TextStyle(fontSize: 16)),
                            label: Text(
                              '${e.likes}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB4326E),
                              ),
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
