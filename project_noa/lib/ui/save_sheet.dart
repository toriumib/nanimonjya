/// SPEC 3.4 — セーブ／ロード。
///
/// 戻り値: ロードで選ばれた [SaveData]（セーブしただけなら null）。
library;

import 'package:flutter/material.dart';

import '../engine/save_manager.dart';
import '../models/save_data.dart';

Future<SaveData?> showSaveSheet(
  BuildContext context, {
  required bool loading,

  /// 書き込むときの中身。null なら「いまはセーブできない」（選択肢の最中）。
  required SaveData? current,
  required String chapter,
  required String memoryRateLabel,
}) {
  return showModalBottomSheet<SaveData?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0B1020),
    showDragHandle: true,
    builder: (ctx) => _SaveSheet(
      loading: loading,
      current: current,
      chapter: chapter,
      rateLabel: memoryRateLabel,
    ),
  );
}

class _SaveSheet extends StatefulWidget {
  final bool loading;
  final SaveData? current;
  final String chapter;
  final String rateLabel;

  const _SaveSheet({
    required this.loading,
    required this.current,
    required this.chapter,
    required this.rateLabel,
  });

  @override
  State<_SaveSheet> createState() => _SaveSheetState();
}

class _SaveSheetState extends State<_SaveSheet> {
  List<SaveData?> _slots = const [];
  SaveData? _auto;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final slots = await SaveManager.instance.listSlots();
    final auto = await SaveManager.instance.read(SaveManager.autoSlot);
    if (!mounted) return;
    setState(() {
      _slots = slots;
      _auto = auto;
      _ready = true;
    });
  }

  Future<void> _writeTo(int slot) async {
    final cur = widget.current;
    if (cur == null) return;
    await SaveManager.instance.write(cur.copyWith(slot: slot, savedAt: DateTime.now()));
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('セーブしました')));
    }
  }

  String _stamp(SaveData s) {
    final t = s.savedAt;
    two(int v) => v.toString().padLeft(2, '0');
    final mins = s.playSec ~/ 60;
    return '${t.year}/${two(t.month)}/${two(t.day)} ${two(t.hour)}:${two(t.minute)}'
        '　プレイ $mins分';
  }

  Widget _row({required String label, required SaveData? data, int? slot}) {
    final canWrite = !widget.loading && widget.current != null && slot != null;
    final canRead = widget.loading && data != null;
    return ListTile(
      enabled: canWrite || canRead,
      leading: Text(label,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Color(0xFF9FB4D8))),
      title: Text(
        data == null ? '— 空き —' : _stamp(data),
        style: TextStyle(
            fontSize: 13,
            color: data == null
                ? const Color(0xFF6A7280)
                : const Color(0xFFE8ECF1)),
      ),
      subtitle: data == null
          ? null
          : Text('${data.sceneId}　覚えた ${data.correctCount}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF6A7280))),
      trailing: canRead
          ? const Icon(Icons.play_arrow_rounded, color: Color(0xFF7DFFB0))
          : (canWrite
              ? const Icon(Icons.save_rounded, color: Color(0xFF5AD1FF))
              : null),
      onTap: () {
        if (canRead) {
          Navigator.pop(context, data);
        } else if (canWrite) {
          _writeTo(slot);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const SizedBox(
          height: 240, child: Center(child: CircularProgressIndicator()));
    }
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (ctx, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              children: [
                Text(widget.loading ? '📂 ロード' : '💾 セーブ',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFD7E2FF))),
                const Spacer(),
                Text(widget.rateLabel,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF7DFFB0))),
              ],
            ),
          ),
          if (!widget.loading && widget.current == null)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('選択肢を選んでいる間はセーブできません。',
                  style: TextStyle(fontSize: 12, color: Color(0xFFE0A44C))),
            ),
          const Divider(height: 1, color: Color(0xFF1D2A4A)),
          Expanded(
            child: ListView(
              controller: controller,
              children: [
                _row(label: 'AUTO', data: _auto),
                const Divider(height: 1, color: Color(0xFF12203C)),
                for (var i = 0; i < _slots.length; i++)
                  _row(
                      label: '${i + 1}'.padLeft(2, '0'),
                      data: _slots[i],
                      slot: i),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
