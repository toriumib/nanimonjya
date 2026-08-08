import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/meta_strings.dart';
import '../models/name_call.dart';
import '../services/app_analytics.dart';
import '../services/online_match_service.dart';
import '../services/player_profile.dart';
import '../services/sfx.dart';
import '../widgets/memory_tip_ticker.dart';
import 'match_game_screen.dart';
import 'name_call_screen.dart';
import 'rank_match_screen.dart';
import 'ranking_screen.dart';
import 'rulebook_screen.dart';
import 'turn_pairs_screen.dart';
import '../widgets/themed_background.dart';
import '../widgets/banner_ad_slot.dart';

/// オンライン対戦の待合室。待ち時間には記憶術Tipsをローテ表示。
///
/// [game] で遊び方が変わる。
/// - `namecall` … なまえがお（フレンド＝**1台で遊ぶときと同じルール**）
/// - `pairs` … ペアさがしの同時レース
/// - `rank` … 🏆 ランクマッチ（知らない人との早押し。設定は選ばせない）
/// - `turnpairs` … 🔁 記憶術トレーニングのターン制対戦
class OnlineLobbyScreen extends StatefulWidget {
  final String game;

  /// ホームのスライダーで選んでいた人数。オンラインに来たときに
  /// 選び直させないよう、そのまま初期値として引き継ぐ。
  final int? initialPeople;

  const OnlineLobbyScreen({
    super.key,
    this.game = 'namecall',
    this.initialPeople,
  });

  @override
  State<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends State<OnlineLobbyScreen> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController(
      text: PlayerProfile.instance.nickname);

  PendingRoom? _pending;
  StreamSubscription? _roomSub;
  bool _busy = false;
  String? _friendCode; // 自分が作った合言葉部屋のコード

  /// 👥 出てくる人数。1台で遊ぶときのスライダーと同じ設定で、
  /// 部屋をつくるときに相手へも配られる。
  late int _people = (widget.initialPeople ??
          OnlineMatchService.defaultOnlinePeople)
      .clamp(NameCallGame.minSelectableCount, NameCallGame.maxSelectableCount);

  /// なまえがおだけが人数を選べる（ペアさがし系はペア数固定、
  /// ランクは条件をそろえない相手と当たるため固定）。
  bool get _peopleSelectable => widget.game == 'namecall';

  /// 🏆 ランクマッチは合言葉での身内対戦を用意しない。
  /// 身内で回してポイントを稼げるとランキングの意味が無くなるため。
  bool get _friendAllowed => widget.game != 'rank';

  @override
  void initState() {
    super.initState();
    AppAnalytics.screen('online_lobby');
  }

  @override
  void dispose() {
    _roomSub?.cancel();
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String get _nickname {
    final n = _nameController.text.trim();
    return n.isEmpty ? 'Player' : n;
  }

  Future<void> _saveNickname() async {
    if (_nameController.text.trim().isNotEmpty) {
      await PlayerProfile.instance.setNickname(_nameController.text.trim());
    }
  }

  /// 部屋のスナップショットを監視し、対戦成立したらゲーム画面へ。
  void _watch(PendingRoom pending) {
    _pending = pending;
    _roomSub?.cancel();
    _roomSub = pending.snapshots.listen((snap) {
      final session = pending.toSession(snap);
      if (session != null && mounted) {
        _roomSub?.cancel();
        Sfx.instance.fanfare();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => switch (session.game) {
              'namecall' => NameCallScreen(online: session),
              'rank' => RankMatchScreen(session: session),
              'turnpairs' => TurnPairsScreen(session: session),
              _ => MatchGameScreen(online: session),
            },
          ),
        );
      }
    });
  }

  Future<void> _randomMatch() async {
    if (_busy) return;
    setState(() => _busy = true);
    await _saveNickname();
    try {
      final pending = await OnlineMatchService.instance.findRandomMatch(
        nickname: _nickname,
        game: widget.game,
        people: _people,
      );
      if (!mounted) return;
      setState(() => _friendCode = null);
      _watch(pending);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _createFriendRoom() async {
    if (_busy) return;
    setState(() => _busy = true);
    await _saveNickname();
    try {
      final pending = await OnlineMatchService.instance.createRoom(
        random: false,
        nickname: _nickname,
        game: widget.game,
        people: _people,
      );
      if (!mounted) return;
      setState(() => _friendCode = pending.roomId);
      _watch(pending);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _joinByCode() async {
    final m = MetaStrings.of(context);
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6 || _busy) return;
    setState(() => _busy = true);
    await _saveNickname();
    final pending = await OnlineMatchService.instance
        .joinByCode(code: code, nickname: _nickname);
    if (!mounted) return;
    if (pending == null) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(m.roomNotFound)));
      return;
    }
    _watch(pending);
  }

  Future<void> _cancelWaiting() async {
    _roomSub?.cancel();
    await _pending?.cancel();
    if (mounted) {
      setState(() {
        _busy = false;
        _pending = null;
        _friendCode = null;
      });
    }
  }

  String _titleFor(MetaStrings m) => switch (widget.game) {
        'rank' => m.rankMatchTitle,
        'turnpairs' => m.turnPairsTitle,
        'namecall' => '${m.onlineMatchTitle}｜${m.tabNameCall}',
        _ => '${m.onlineMatchTitle}｜${m.tabPairs}',
      };

  RuleTopic get _ruleTopic => switch (widget.game) {
        'rank' => RuleTopic.rank,
        'turnpairs' => RuleTopic.turnPairs,
        _ => RuleTopic.onlineFriend,
      };

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    return Scaffold(
      bottomNavigationBar: const BannerAdSlot(),
      appBar: AppBar(
        title: Text(_titleFor(m)),
        actions: [
          RulebookButton(focus: _ruleTopic, onDark: true),
          const SizedBox(width: 10),
        ],
      ),
      // 買った着せ替えテーマをこの画面にも反映する
      body: ThemedBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const MemoryTipTicker(rotate: true),
                const SizedBox(height: 16),
                if (_busy) _waitingCard(m) else ..._menuCards(m),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _menuCards(MetaStrings m) {
    return [
      // ニックネーム
      _card(
        child: Row(
          children: [
            const Text('😀', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _nameController,
                maxLength: 10,
                decoration: InputDecoration(
                  labelText: m.nicknameLabel,
                  counterText: '',
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      // 🏆 ランクマッチは説明を先に読ませる（何が起きるか分からないまま
      //    知らない人と当たると、途中で抜けられて相手にも迷惑がかかる）
      if (widget.game == 'rank') ...[
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.rankMatchTitle,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(m.rankMatchDesc,
                  style: const TextStyle(
                      fontSize: 12.5, height: 1.5, color: Colors.black54)),
              const SizedBox(height: 8),
              Text(m.rankRatingLine(PlayerProfile.instance.rankRating),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2B5CA5))),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _randomMatch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8A400),
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(m.rankMatchButton),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () {
                  Sfx.instance.pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RankingScreen()),
                  );
                },
                child: Text(m.rankSeeRanking),
              ),
            ],
          ),
        ),
      ] else ...[
        // 👥 1台で遊ぶときと同じ「出てくる人数」をここでも決める
        if (_peopleSelectable) ...[
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.onlinePeopleLabel,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w900)),
                Row(
                  children: [
                    Text('$_people',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2B5CA5))),
                    Expanded(
                      child: Slider(
                        value: _people.toDouble(),
                        min: NameCallGame.minSelectableCount.toDouble(),
                        max: NameCallGame.maxSelectableCount.toDouble(),
                        divisions: NameCallGame.maxSelectableCount -
                            NameCallGame.minSelectableCount,
                        label: '$_people',
                        onChanged: (v) =>
                            setState(() => _people = v.round()),
                      ),
                    ),
                  ],
                ),
                Text(m.onlinePeopleHint,
                    style: const TextStyle(
                        fontSize: 11.5, color: Colors.black54)),
                const SizedBox(height: 6),
                Text(m.onlineRoomRule(_people),
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2B5CA5))),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        // ランダムマッチ
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🎲 ${m.randomMatch}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(
                  widget.game == 'turnpairs'
                      ? m.turnPairsDesc
                      : widget.game == 'namecall'
                          ? m.nameCallCatch
                          : m.onlineRaceDesc,
                  style: const TextStyle(
                      fontSize: 12.5, height: 1.4, color: Colors.black54)),
              if (_peopleSelectable) ...[
                const SizedBox(height: 4),
                Text(m.randomMatchPeopleNote,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.black45)),
              ],
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _randomMatch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  minimumSize: const Size.fromHeight(46),
                ),
                child: Text(m.randomMatch),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // 友だちと対戦
        if (_friendAllowed)
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🤝 ${m.friendMatchTitle}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(m.friendMatchDesc,
                    style: const TextStyle(
                        fontSize: 12.5, height: 1.4, color: Colors.black54)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _createFriendRoom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4ECDC4),
                    minimumSize: const Size.fromHeight(46),
                  ),
                  child: Text(m.createRoomButton),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeController,
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 6,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9]')),
                        ],
                        decoration: InputDecoration(
                          labelText: m.enterCodeLabel,
                          counterText: '',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _joinByCode,
                      child: Text(m.joinButton),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    ];
  }

  Widget _waitingCard(MetaStrings m) {
    return _card(
      child: Column(
        children: [
          const SizedBox(height: 6),
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            m.matching,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
          if (_peopleSelectable) ...[
            const SizedBox(height: 8),
            Text(m.onlineRoomRule(_people),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
          if (_friendCode != null) ...[
            const SizedBox(height: 14),
            Text(m.shareCodePrompt,
                style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF3A7BD5), width: 2),
              ),
              child: Text(
                _friendCode!,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                  color: Color(0xFF2B5CA5),
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                Share.share(m.shareCodeText(_friendCode!));
              },
              icon: const Icon(Icons.share, size: 18),
              label: Text(m.shareInvite),
            ),
          ],
          const SizedBox(height: 16),
          TextButton(
            onPressed: _cancelWaiting,
            child: Text(m.cancel),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD8E4F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}
