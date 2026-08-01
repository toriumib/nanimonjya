import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:io';

import '../l10n/meta_strings.dart';
import '../models/person.dart';
import '../services/card_ocr_service.dart';
import '../services/custom_roster_service.dart';
import '../services/sfx.dart';
import '../widgets/face_view.dart';
import 'name_call_screen.dart';
import 'recall_training_screen.dart';
import 'study_screen.dart';
import '../widgets/themed_background.dart';
import '../widgets/banner_ad_slot.dart';

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
    try {
      final picked =
          await _picker.pickImage(source: source, maxWidth: 800, imageQuality: 80);
      if (picked == null || !mounted) return;
      final result = await Navigator.push<_FormResult>(
        context,
        MaterialPageRoute(
            builder: (_) => const _EntryFormScreen(facePath: null)),
      );
      if (result == null || result.entry.name.trim().isEmpty) return;
      await CustomRosterService.instance.add(
        sourcePath: picked.path,
        draft: result.entry,
        cardSourcePath: result.cardPath,
      );
      Sfx.instance.coin();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  /// 登録済みの人を開いて、項目を見る／直す。
  Future<void> _openEntry(CustomEntry e) async {
    final result = await Navigator.push<_FormResult>(
      context,
      MaterialPageRoute(
        builder: (_) => _EntryFormScreen(initial: e, facePath: e.imagePath),
      ),
    );
    if (result == null) return;
    if (result.deleted) {
      await CustomRosterService.instance.remove(e.id);
      return;
    }
    if (result.entry.name.trim().isEmpty) return;
    await CustomRosterService.instance.update(
      result.entry,
      newCardSourcePath: result.cardPath,
    );
    Sfx.instance.pop();
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
      bottomNavigationBar: const BannerAdSlot(),
      appBar: AppBar(title: Text(m.tabMemorize)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        icon: const Icon(Icons.add_a_photo),
        label: Text(m.customAddButton),
      ),
      // 買った着せ替えテーマをこの画面にも反映する
      body: ThemedBackground(
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
        // 🧠 名刺で思い出しクイズ（会社名・名前・肩書・連絡先を想起）
        ElevatedButton(
          onPressed: () => _startCustomRecall(people),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2B5CA5),
            minimumSize: const Size.fromHeight(48),
          ),
          child: Text(m.customRecallQuizButton),
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

  /// カスタム名簿で思い出しクイズ。名簿に存在する項目だけを出題する。
  void _startCustomRecall(List<Person> people) {
    Sfx.instance.fanfare();
    final fields = <RecallField>{RecallField.name};
    if (people.any((p) => p.company.isNotEmpty)) fields.add(RecallField.company);
    if (people.any((p) => p.title.isNotEmpty)) fields.add(RecallField.title);
    if (people.any((p) => p.phone.isNotEmpty)) fields.add(RecallField.phone);
    if (people.any((p) => p.email.isNotEmpty)) fields.add(RecallField.email);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecallTrainingScreen(people: people, fields: fields),
      ),
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
      onTap: () => _openEntry(e),
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
            if (e.company.isNotEmpty)
              Text(
                e.company,
                style: const TextStyle(fontSize: 9.5, color: Colors.black54),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            // 何項目メモしてあるかを出す。タップで開いて足せることの合図にもなる。
            Text(
              '📝 ${e.filledFieldsJa().length}項目',
              style: const TextStyle(fontSize: 9, color: Colors.black38),
            ),
          ],
        ),
      ),
    );
  }
}


/// フォームの結果。[deleted] が true なら「この人を削除」を選んだということ。
class _FormResult {
  final CustomEntry entry;
  final String? cardPath; // 新しく選んだ名刺画像（変更していなければ null）
  final bool deleted;
  const _FormResult({required this.entry, this.cardPath, this.deleted = false});
}

/// 📇 人物1人の入力フォーム（新規登録／編集の共用）。
///
/// 項目が18個あるのでダイアログには入りきらない。1画面にして、
/// 「基本 / 仕事 / プロフィール / 連絡先 / メモ」に分けて折りたたむ。
/// 全部埋める必要はなく、**名前だけで登録できる**（他は任意）。
class _EntryFormScreen extends StatefulWidget {
  final CustomEntry? initial;
  final String? facePath; // 顔写真のプレビュー（新規のときは null）
  const _EntryFormScreen({this.initial, required this.facePath});

  @override
  State<_EntryFormScreen> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends State<_EntryFormScreen> {
  final _picker = ImagePicker();

  static const List<String> _keys = [
    'name', 'reading', 'nickname', 'gender', 'birthday',
    'company', 'title', 'occupation',
    'origin', 'address', 'relation',
    'phone', 'email', 'x', 'instagram', 'line', 'facebook',
    'memo',
  ];

  late final Map<String, TextEditingController> _c = {
    for (final k in _keys) k: TextEditingController(text: _initialValue(k)),
  };

  String? _cardPath;
  bool _ocrBusy = false;
  bool _ocrDone = false;
  bool _ocrFailed = false;

  String _initialValue(String key) {
    final e = widget.initial;
    if (e == null) return '';
    return switch (key) {
      'name' => e.name,
      'reading' => e.reading,
      'nickname' => e.nickname,
      'gender' => e.gender,
      'birthday' => e.birthday,
      'company' => e.company,
      'title' => e.title,
      'occupation' => e.occupation,
      'origin' => e.origin,
      'address' => e.address,
      'relation' => e.relation,
      'phone' => e.phone,
      'email' => e.email,
      'x' => e.x,
      'instagram' => e.instagram,
      'line' => e.line,
      'facebook' => e.facebook,
      'memo' => e.memo,
      _ => '',
    };
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _t(String key) => _c[key]!.text.trim();

  CustomEntry _build() => CustomEntry(
        id: widget.initial?.id ?? '',
        imagePath: widget.initial?.imagePath ?? '',
        cardImagePath: widget.initial?.cardImagePath ?? '',
        name: _t('name'),
        reading: _t('reading'),
        nickname: _t('nickname'),
        gender: _t('gender'),
        birthday: _t('birthday'),
        company: _t('company'),
        title: _t('title'),
        occupation: _t('occupation'),
        origin: _t('origin'),
        address: _t('address'),
        relation: _t('relation'),
        phone: _t('phone'),
        email: _t('email'),
        x: _t('x'),
        instagram: _t('instagram'),
        line: _t('line'),
        facebook: _t('facebook'),
        memo: _t('memo'),
      );

  Future<void> _pickCard() async {
    final c = await _picker.pickImage(
        source: ImageSource.gallery,
        // OCRにかけるので、解像度は落としすぎない
        maxWidth: 1600,
        imageQuality: 92);
    if (c == null) return;
    setState(() {
      _cardPath = c.path;
      _ocrBusy = CardOcrService.available;
      _ocrDone = false;
      _ocrFailed = false;
    });
    if (!CardOcrService.available) return;
    // 📇 名刺を読み取って空欄だけ自動で埋める。
    // 端末内で処理されるので、名刺の内容は外部に送られない。
    final r = await CardOcrService.instance.scan(c.path);
    if (!mounted) return;
    setState(() {
      _ocrBusy = false;
      // すでに手で入れた項目は上書きしない
      void fill(String key, String v) {
        if (_c[key]!.text.isEmpty) _c[key]!.text = v;
      }

      fill('name', r.name);
      fill('company', r.company);
      fill('title', r.title);
      fill('phone', r.phone);
      fill('email', r.email);
      _ocrDone = !r.isEmpty;
      _ocrFailed = r.isEmpty;
    });
  }

  Future<void> _confirmDeleteFromForm(MetaStrings m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: Text(m.customDeleteConfirm(widget.initial!.name)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false), child: Text(m.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(m.customDelete)),
        ],
      ),
    );
    if (ok == true && mounted) {
      Navigator.pop(context, _FormResult(entry: _build(), deleted: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    final isEdit = widget.initial != null;
    final hasCard =
        _cardPath != null || (widget.initial?.cardImagePath ?? '').isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? '編集' : m.customDetailsTitle),
        actions: [
          if (isEdit)
            IconButton(
              tooltip: m.customDelete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDeleteFromForm(m),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (widget.facePath != null)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(File(widget.facePath!),
                      width: 110, height: 110, fit: BoxFit.cover),
                ),
              ),
            const SizedBox(height: 12),
            // 名前だけ必須。ほかは覚えるための手がかりなので、
            // 書きたい人だけ開いて書けばいい形にしている。
            _field('name', '名前 *', maxLen: 24),
            _field('reading', '読み方', maxLen: 24),
            _field('nickname', 'ニックネーム', maxLen: 24),
            const SizedBox(height: 8),
            _section('🏢 仕事', [
              _field('company', '会社名', maxLen: 40),
              _field('title', '役職', maxLen: 24),
              _field('occupation', '職業', maxLen: 24),
            ]),
            _section('🧑 プロフィール', [
              _field('gender', '性別', maxLen: 12),
              _field('birthday', '誕生日', maxLen: 20),
              _field('origin', '出身', maxLen: 30),
              _field('address', '住所', maxLen: 60),
              _field('relation', '自分との関係', maxLen: 30),
            ]),
            _section('📞 連絡先', [
              _field('phone', '電話番号',
                  keyboard: TextInputType.phone, maxLen: 20),
              _field('email', 'メール',
                  keyboard: TextInputType.emailAddress, maxLen: 60),
              _field('x', 'X', maxLen: 30),
              _field('instagram', 'Instagram', maxLen: 30),
              _field('line', 'LINE ID', maxLen: 30),
              _field('facebook', 'Facebook', maxLen: 40),
            ]),
            _section('📝 メモ', [
              _field('memo', '自由記入メモ', maxLen: 300, lines: 4),
            ]),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.badge_outlined, size: 18),
              label: Text(
                hasCard ? m.customCardSelected : m.customPickCardImage,
                style: const TextStyle(fontSize: 12.5),
              ),
              onPressed: _pickCard,
            ),
            if (_ocrBusy)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(width: 8),
                    Text(m.ocrReading, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              )
            else if (_ocrDone)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(m.ocrFilled,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 11.5, color: Color(0xFF1E7BA6))),
              )
            else if (_ocrFailed)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(m.ocrFailed,
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(fontSize: 11.5, color: Colors.black54)),
              ),
            if (_cardPath != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(File(_cardPath!),
                      height: 90, fit: BoxFit.cover),
                ),
              )
            else if ((widget.initial?.cardImagePath ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(File(widget.initial!.cardImagePath),
                      height: 90, fit: BoxFit.cover),
                ),
              ),
            const SizedBox(height: 20),
            const Text(
              'ここに入れた情報はこの端末の中だけに保存され、外部へは送信されません。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _t('name').isEmpty
                  ? null
                  : () => Navigator.pop(
                        context,
                        _FormResult(entry: _build(), cardPath: _cardPath),
                      ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: const Color(0xFF3A7BD5),
                foregroundColor: Colors.white,
              ),
              child: Text(m.customSave),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: ExpansionTile(
          title: Text(title,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 8),
          children: children,
        ),
      );

  Widget _field(String key, String label,
      {TextInputType? keyboard, int? maxLen, int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: TextField(
        controller: _c[key],
        keyboardType: lines > 1 ? TextInputType.multiline : keyboard,
        maxLines: lines,
        maxLength: maxLen,
        // 「名前」が空だと保存できないので、入力に合わせて保存ボタンを出し直す
        onChanged: key == 'name' ? (_) => setState(() {}) : null,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          counterText: '',
        ),
      ),
    );
  }
}
