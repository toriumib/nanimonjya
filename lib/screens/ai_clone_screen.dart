import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/meta_strings.dart';
import '../models/ai_clone.dart';
import '../models/avatar.dart';
import '../services/custom_roster_service.dart';
import '../services/sfx.dart';
import '../services/speech.dart';
import '../widgets/avatar_view.dart';

/// 🤖 AIクローン作成画面。
///
/// 自撮り→アバター調整→話し方選択→自己紹介入力→名簿登録。
/// あとは RecallTraining で「自分そっくりのAI」に会える。
class AiCloneScreen extends StatefulWidget {
  const AiCloneScreen({super.key});

  @override
  State<AiCloneScreen> createState() => _AiCloneScreenState();
}

class _AiCloneScreenState extends State<AiCloneScreen> {
  final _picker = ImagePicker();
  String? _photoPath;
  Avatar _avatar = Avatar();
  String _style = 'natural';
  final List<String> _catchphrases = [];
  final _greetingCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  int _step = 0; // 0=写真, 1=アバター, 2=話し方, 3=自己紹介, 4=名刺プレビュー

  @override
  void dispose() {
    _greetingCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final img = await _picker.pickImage(
        source: ImageSource.gallery, maxWidth: 800, maxHeight: 800);
    if (img != null && mounted) {
      setState(() => _photoPath = img.path);
      Sfx.instance.pop();
    }
  }

  Future<void> _takePhoto() async {
    final img = await _picker.pickImage(
        source: ImageSource.camera, maxWidth: 800, maxHeight: 800);
    if (img != null && mounted) {
      setState(() => _photoPath = img.path);
      Sfx.instance.pop();
    }
  }

  void _randomizeAvatar() {
    setState(() => _avatar = Avatar.random());
    Sfx.instance.pop();
  }

  Future<void> _save() async {
    final m = MetaStrings.of(context);
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(m.ja ? '名前を入力してください' : 'Please enter a name')),
      );
      return;
    }

    final persona = AiClonePersona(
      style: _style,
      catchphrases: _catchphrases,
      greeting: _greetingCtrl.text.trim(),
      avatar: _avatar,
    );

    final entry = CustomEntry(
      id: '',
      imagePath: _photoPath ?? '',
      name: name,
      company: m.ja ? 'AIクローン' : 'AI Clone',
      title: m.ja
          ? '話し方: ${kAiStyles[_style]!['ja']}'
          : 'Style: ${kAiStyles[_style]!['en']}',
      avatar: _avatar.encode(),
      memo: jsonEncode(persona.toJson()),
    );

    await CustomRosterService.instance.add(
      sourcePath: _photoPath,
      draft: entry,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m.ja ? '🤖 AIクローンを登録しました！名刺覚えで会えます' : '🤖 AI Clone registered! Meet them in Biz Training')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    final ja = m.ja;
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: Text(ja ? '🤖 AIクローンをつくる' : '🤖 Create AI Clone'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_step == 4)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save, size: 16),
                label: Text(ja ? '保存' : 'Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5AD1FF),
                  foregroundColor: const Color(0xFF0D1117),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [
              _stepIndicator(ja),
              const SizedBox(height: 16),
              Expanded(
                child: switch (_step) {
                  0 => _photoStep(ja, m),
                  1 => _avatarStep(ja, m),
                  2 => _styleStep(ja, m),
                  3 => _greetingStep(ja, m),
                  4 => _previewStep(ja, m),
                  _ => const SizedBox.shrink(),
                },
              ),
              _navButtons(ja),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepIndicator(bool ja) {
    final labels = ja
        ? ['📸 写真', '🧑‍🎨 見た目', '🎤 話し方', '💬 自己紹介', '👀 確認']
        : ['📸 Photo', '🧑‍🎨 Look', '🎤 Voice', '💬 Greeting', '👀 Preview'];
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= _step
                        ? const Color(0xFF5AD1FF)
                        : const Color(0xFF1D2A4A),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 4),
                Text(labels[i],
                    style: TextStyle(
                      fontSize: 10,
                      color: i == _step
                          ? const Color(0xFF5AD1FF)
                          : const Color(0xFF556688),
                      fontWeight: i == _step ? FontWeight.w900 : FontWeight.normal,
                    )),
              ],
            ),
          ),
      ],
    );
  }

  Widget _navButtons(bool ja) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_step > 0)
          OutlinedButton(
            onPressed: () => setState(() => _step -= 1),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF5AD1FF),
              side: const BorderSide(color: Color(0xFF5AD1FF)),
            ),
            child: Text(ja ? '← もどる' : '← Back'),
          )
        else
          const SizedBox.shrink(),
        if (_step < 4)
          ElevatedButton(
            onPressed: () {
              Sfx.instance.pop();
              setState(() => _step += 1);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5AD1FF),
              foregroundColor: const Color(0xFF0D1117),
            ),
            child: Text(ja ? 'つぎへ →' : 'Next →'),
          ),
      ],
    );
  }

  // ── Step 0: 写真 ──

  Widget _photoStep(bool ja, MetaStrings m) {
    return ListView(
      children: [
        const SizedBox(height: 20),
        Center(
          child: _photoPath != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    _photoPath!,
                    width: 220, height: 220, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 220, height: 220,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D2A4A),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: Icon(Icons.person, size: 80, color: Color(0xFF556688)),
                      ),
                    ),
                  ),
                )
              : Container(
                  width: 220, height: 220,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D2A4A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF334466), width: 2),
                  ),
                  child: const Center(
                    child: Icon(Icons.person, size: 80, color: Color(0xFF556688)),
                  ),
                ),
        ),
        const SizedBox(height: 24),
        Text(
          ja ? 'AIクローンにするあなたの写真を選んでください' : 'Choose a photo of yourself for the AI clone',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.5),
        ),
        const SizedBox(height: 6),
        Text(
          ja ? '写りのいい自撮り1枚でOK。後からアバターで調整できます。' : 'One good selfie is all you need. You can fine-tune with the avatar editor.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Color(0xFF8899BB), height: 1.4),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: Text(ja ? '撮影する' : 'Take photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5AD1FF),
                  foregroundColor: const Color(0xFF0D1117),
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.photo_library),
                label: Text(ja ? 'アルバムから' : 'From album'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF5AD1FF),
                  side: const BorderSide(color: Color(0xFF5AD1FF)),
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            _randomizeAvatar();
            setState(() => _step = 1);
          },
          child: Text(ja
              ? '📱 写真が無い → アバターだけで作る'
              : '📱 No photo → Use avatar only'),
        ),
      ],
    );
  }

  // ── Step 1: アバター調整 ──

  Widget _avatarStep(bool ja, MetaStrings m) {
    return ListView(
      children: [
        Center(
          child: AvatarView(avatar: _avatar, size: 200, radius: 20),
        ),
        const SizedBox(height: 16),
        Text(
          ja ? 'アバターの特徴を選んで——AIクローンの「顔」になります。' : 'Choose your avatar features — this becomes your AI clone\'s face.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: Color(0xFF8899BB)),
        ),
        const SizedBox(height: 16),
        _pickerRow(
          ja ? '👓 メガネ' : '👓 Glasses',
          kGlassesEn, kGlassesJa, _avatar.glasses,
          (v) => setState(() => _avatar = _avatar.copyWith(glasses: v)),
        ),
        _pickerRow(
          ja ? '💇 髪型' : '💇 Hair',
          kHairEn, kHairJa, _avatar.hair.clamp(0, kHairJa.length - 1),
          (v) => setState(() => _avatar = _avatar.copyWith(hair: v)),
        ),
        _pickerRow(
          ja ? '🧔 ひげ' : '🧔 Beard',
          kBeardEn, kBeardJa, _avatar.beard,
          (v) => setState(() => _avatar = _avatar.copyWith(beard: v)),
        ),
        _pickerRow(
          ja ? '🖐 肌の色' : '🖐 Skin',
          kSkinEn, kSkinJa, _avatar.skin,
          (v) => setState(() => _avatar = _avatar.copyWith(skin: v)),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _randomizeAvatar,
          icon: const Icon(Icons.shuffle),
          label: Text(ja ? 'ランダムで変える' : 'Randomize'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFFF9A3C),
            side: const BorderSide(color: Color(0xFFFF9A3C)),
          ),
        ),
      ],
    );
  }

  Widget _pickerRow(String title, List<String> labelsEn, List<String> labelsJa,
      int value, ValueChanged<int> onChanged) {
    final ja = MetaStrings.of(context).ja;
    final labels = ja ? labelsJa : labelsEn;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF8899BB))),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < labels.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(labels[i], style: const TextStyle(fontSize: 11)),
                      selected: value == i,
                      onSelected: (_) => onChanged(i),
                      selectedColor: const Color(0xFF5AD1FF),
                      backgroundColor: const Color(0xFF1D2A4A),
                      labelStyle: TextStyle(
                        color: value == i ? const Color(0xFF0D1117) : const Color(0xFF8899BB),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 2: 話し方 ──

  Widget _styleStep(bool ja, MetaStrings m) {
    return ListView(
      children: [
        const SizedBox(height: 20),
        Text(
          ja ? 'AIクローンの「話し方」を選んでください。' : 'Choose your AI clone\'s speaking style.',
          style: const TextStyle(fontSize: 15, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          ja ? '声のトーンや口癖が変わります（TTS音声 + ピッチ調整）' : 'Voice tone and catchphrases will match (TTS + pitch tuning)',
          style: const TextStyle(fontSize: 12, color: Color(0xFF8899BB)),
        ),
        const SizedBox(height: 18),
        ...kAiStyles.entries.map((e) {
          final selected = _style == e.key;
          return Card(
            color: selected ? const Color(0xFF1A3355) : const Color(0xFF0D1117),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: selected ? const Color(0xFF5AD1FF) : const Color(0xFF1D2A4A),
                width: selected ? 2 : 1,
              ),
            ),
            child: ListTile(
              title: Text(
                ja ? e.value['ja']! : e.value['en']!,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: selected ? const Color(0xFF5AD1FF) : const Color(0xFFD0D8E8),
                ),
              ),
              subtitle: Text(
                _styleCatchphrase(e.key, ja),
                style: const TextStyle(fontSize: 11, color: Color(0xFF8899BB)),
              ),
              trailing: selected
                  ? const Icon(Icons.check_circle, color: Color(0xFF5AD1FF))
                  : const Icon(Icons.circle_outlined, color: Color(0xFF44506B)),
              onTap: () {
                Sfx.instance.pop();
                setState(() => _style = e.key);
              },
            ),
          );
        }),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            Speech.instance.speak(
              buildAiIntroduction(
                name: ja ? 'AIの自分' : 'AI me',
                style: _style,
                greeting: '',
                ja: ja,
              ),
              ja: ja,
            );
          },
          icon: const Icon(Icons.volume_up, size: 16),
          label: Text(ja ? '🔊 話し方を試聴する' : '🔊 Preview voice'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF5AD1FF),
          ),
        ),
      ],
    );
  }

  String _styleCatchphrase(String key, bool ja) {
    final options = kCatchphraseOptions[key] ?? kCatchphraseOptions['natural']!;
    return options.take(3).join('  ');
  }

  // ── Step 3: 自己紹介 ──

  Widget _greetingStep(bool ja, MetaStrings m) {
    return ListView(
      children: [
        const SizedBox(height: 20),
        Text(
          ja ? 'AIクローンの自己紹介を入力してください' : 'Write your AI clone\'s self-introduction',
          style: const TextStyle(fontSize: 15, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          ja ? '名刺を差し出すときにこの言葉を読み上げます。' : 'This is what they\'ll say when handing over their business card.',
          style: const TextStyle(fontSize: 12, color: Color(0xFF8899BB)),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameCtrl,
          maxLength: 20,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            labelText: ja ? 'AIの名前（例: トオルくん）' : 'AI Name (e.g. Toru)',
            labelStyle: const TextStyle(color: Color(0xFF8899BB)),
            filled: true,
            fillColor: const Color(0xFF1D2A4A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            counterStyle: const TextStyle(color: Color(0xFF556688)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _greetingCtrl,
          maxLines: 3,
          maxLength: 120,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            labelText: ja
                ? '自己紹介（例: 毎朝ラーメンを食べてから出社します）'
                : 'Greeting (e.g. I love hiking on weekends)',
            labelStyle: const TextStyle(color: Color(0xFF8899BB)),
            hintText: ja ? '空欄でもOK。名前だけ読み上げます。' : 'Optional. Just the name is fine.',
            hintStyle: const TextStyle(color: Color(0xFF44506B), fontSize: 12),
            filled: true,
            fillColor: const Color(0xFF1D2A4A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            counterStyle: const TextStyle(color: Color(0xFF556688)),
          ),
        ),
      ],
    );
  }

  // ── Step 4: プレビュー ──

  Widget _previewStep(bool ja, MetaStrings m) {
    final name = _nameCtrl.text.trim().isEmpty
        ? (ja ? 'AIの自分' : 'AI Me')
        : _nameCtrl.text.trim();

    return ListView(
      children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF5AD1FF), width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5AD1FF).withValues(alpha: 0.3),
                  blurRadius: 24,
                ),
              ],
            ),
            child: ClipOval(
              child: _photoPath != null
                  ? Image.network(_photoPath!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          AvatarView(avatar: _avatar, size: 180, radius: 0))
                  : AvatarView(avatar: _avatar, size: 180, radius: 0),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // 名刺プレビュー
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF7FAFF), Color(0xFFDDE7F5)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF5AD1FF), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ja ? 'AIクローン' : 'AI Clone',
                  style: const TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w900,
                      color: Color(0xFF2B5CA5))),
              const SizedBox(height: 6),
              Text(kAiStyles[_style]![ja ? 'ja' : 'en']!,
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF6A7A93))),
              Text(name,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900,
                      color: Color(0xFF10182A), letterSpacing: 2)),
              const SizedBox(height: 8),
              Container(height: 1, color: const Color(0x332B5CA5)),
              const SizedBox(height: 8),
              if (_greetingCtrl.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('"${_greetingCtrl.text}"',
                      style: const TextStyle(
                          fontSize: 12.5, color: Color(0xFF10182A),
                          fontStyle: FontStyle.italic)),
                ),
              Text(ja ? 'ペタネーム AIクローン名刺' : 'PetaName AI Clone Card',
                  style: const TextStyle(fontSize: 9.5, color: Color(0xFF8899AD))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            Speech.instance.speak(
              buildAiIntroduction(
                name: name,
                style: _style,
                greeting: _greetingCtrl.text.trim(),
                ja: ja,
              ),
              ja: ja,
            );
          },
          icon: const Icon(Icons.volume_up, size: 16),
          label: Text(ja ? '🔊 自己紹介を試聴する' : '🔊 Preview introduction'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF5AD1FF),
            minimumSize: const Size.fromHeight(44),
          ),
        ),
      ],
    );
  }
}
