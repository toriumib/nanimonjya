import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/meta_strings.dart';
import '../services/app_analytics.dart';
import '../services/online_match_service.dart';
import '../services/player_profile.dart';
import '../services/sfx.dart';
import '../widgets/memory_tip_ticker.dart';
import 'match_game_screen.dart';
import 'name_call_screen.dart';

/// オンライン対戦の待合室。
/// ランダムマッチ／合言葉での友だち対戦。待ち時間には記憶術Tipsをローテ表示。
/// [game] は 'namecall'（なまえコール）| 'pairs'（ペアさがし）。
class OnlineLobbyScreen extends StatefulWidget {
  final String game;
  const OnlineLobbyScreen({super.key, this.game = 'namecall'});

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
            builder: (_) => session.game == 'namecall'
                ? NameCallScreen(online: session)
                : MatchGameScreen(online: session),
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
      final pending = await OnlineMatchService.instance
          .findRandomMatch(nickname: _nickname, game: widget.game);
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
      final pending = await OnlineMatchService.instance
          .createRoom(random: false, nickname: _nickname, game: widget.game);
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

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${m.onlineMatchTitle}｜${widget.game == 'namecall' ? m.tabNameCall : m.tabPairs}'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF3FF), Color(0xFFFFF9EC)],
          ),
        ),
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
      // ランダムマッチ
      _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🎲 ${m.randomMatch}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(widget.game == 'namecall' ? m.nameCallCatch : m.onlineRaceDesc,
                style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
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
      _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🤝 ${m.friendMatchTitle}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
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
