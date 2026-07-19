import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/meta_strings.dart';
import '../models/person.dart';
import '../services/custom_roster_service.dart';
import '../services/sfx.dart';
import '../widgets/face_view.dart';
import 'name_call_screen.dart';
import 'study_screen.dart';

/// 「おぼえる」= 自分の名簿の管理画面。
/// 職場・学校などの写真＋名前を登録し、学習・テスト・対戦の起点になる。
class CustomRosterScreen extends StatefulWidget {
  const CustomRosterScreen({super.key});

  @override
  State<CustomRosterScreen> createState() => _CustomRosterScreenState();
}

class _CustomRosterScreenState extends State<CustomRosterScreen> {
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    CustomRosterService.instance.load();
  }

  Future<void> _addPhoto(ImageSource source) async {
    final m = MetaStrings.of(context);
    try {
      final picked =
          await _picker.pickImage(source: source, maxWidth: 800, imageQuality: 80);
      if (picked == null || !mounted) return;
      final name = await _askName(m);
      if (name == null || name.trim().isEmpty) return;
      await CustomRosterService.instance
          .add(sourcePath: picked.path, name: name.trim());
      Sfx.instance.coin();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<String?> _askName(MetaStrings m) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(m.customNameField),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 10,
          decoration: InputDecoration(
            labelText: m.customNameField,
            counterText: '',
          ),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(m.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(m.customSave),
          ),
        ],
      ),
    );
  }

  void _showAddSheet() {
    final m = MetaStrings.of(context);
    Sfx.instance.pop();
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF3A7BD5)),
              title: Text(m.customPickPhoto),
              onTap: () {
                Navigator.pop(sheetContext);
                _addPhoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera, color: Color(0xFFE8663C)),
              title: Text(m.customTakePhoto),
              onTap: () {
                Navigator.pop(sheetContext);
                _addPhoto(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(CustomEntry e) async {
    final m = MetaStrings.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(m.customDeleteConfirm(e.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(m.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(m.customDelete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await CustomRosterService.instance.remove(e.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);

    // Web は写真アップロード（ファイル保存）非対応
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(title: Text(m.tabMemorize)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Text(
              m.customMobileOnly,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(m.tabMemorize)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        icon: const Icon(Icons.add_a_photo),
        label: Text(m.customAddButton),
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
          child: AnimatedBuilder(
            animation: CustomRosterService.instance,
            builder: (context, _) {
              final entries = CustomRosterService.instance.entries;
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: const Color(0xFFD8E4F0), width: 1.5),
                      ),
                      child: Text(m.customDesc,
                          style: const TextStyle(fontSize: 13, height: 1.5)),
                    ),
                    const SizedBox(height: 16),
                    if (entries.length >= 2) _actionButtons(m, entries),
                    const SizedBox(height: 16),
                    if (entries.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          m.customEmpty,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      )
                    else
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.82,
                        children: [
                          for (final e in entries) _entryCard(e),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _actionButtons(MetaStrings m, List<CustomEntry> entries) {
    final people = entries.map((e) => e.toPerson()).toList();
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => StudyScreen(people: people)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ECDC4),
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(m.memorizeStudyButton),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            StudyScreen(people: people, quizMode: true)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3A7BD5),
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(m.memorizeQuizButton),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // オフライン対戦（この名簿でなまえコール）: 2〜4人でみんなで
        ElevatedButton(
          onPressed: () => _startCustomBattle(people),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE8663C),
            minimumSize: const Size.fromHeight(48),
          ),
          child: Text(m.customBattleButton),
        ),
      ],
    );
  }

  void _startCustomBattle(List<Person> people) {
    final m = MetaStrings.of(context);
    Sfx.instance.pop();
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(m.customBattleButton,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (final n in [2, 3, 4]) ...[
                    if (n > 2) const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NameCallScreen(
                                humanPlayers: n,
                                customPeople: people,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE8663C),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text('$n人'),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(m.refereeHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11.5, color: Colors.black45)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _entryCard(CustomEntry e) {
    return GestureDetector(
      onLongPress: () => _confirmDelete(e),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD8E4F0), width: 1.5),
        ),
        child: Column(
          children: [
            Expanded(
              child: FaceView(person: e.toPerson(), size: 90, radius: 10),
            ),
            const SizedBox(height: 4),
            Text(
              e.name,
              style:
                  const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
