/// SPEC 3.5 — コンフィグ。変えたらその場で保存する。
library;

import 'package:flutter/material.dart';

import '../engine/config_store.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ConfigStore get _store => ConfigStore.instance;
  AdvConfig get _c => _store.config;

  void _set(AdvConfig next) {
    _store.update(next);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05080F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFFD7E2FF),
        title: const Text('コンフィグ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _slider(
            // 「速さ」で見せる。内側は1文字あたりのミリ秒なので、
            // 数字が小さいほど速い。逆向きなのでそのまま出すと混乱する。
            title: '文字の速さ',
            value: (60 - _c.charMs).clamp(0, 60).toDouble(),
            min: 0,
            max: 60,
            label: _c.charMs <= 0 ? '瞬間表示' : '${60 - _c.charMs}',
            onChanged: (v) => _set(_c.copyWith(charMs: (60 - v).round())),
          ),
          _slider(
            title: 'オートで待つ時間',
            value: _c.autoWaitMs.toDouble(),
            min: 200,
            max: 4000,
            label: '${(_c.autoWaitMs / 1000).toStringAsFixed(1)}秒',
            onChanged: (v) => _set(_c.copyWith(autoWaitMs: v.round())),
          ),
          const Divider(color: Color(0xFF1D2A4A)),
          _slider(
            title: 'BGM',
            value: _c.bgmVolume,
            min: 0,
            max: 1,
            label: '${(_c.bgmVolume * 100).round()}%',
            onChanged: (v) => _set(_c.copyWith(bgmVolume: v)),
          ),
          _slider(
            title: '効果音',
            value: _c.seVolume,
            min: 0,
            max: 1,
            label: '${(_c.seVolume * 100).round()}%',
            onChanged: (v) => _set(_c.copyWith(seVolume: v)),
          ),
          _slider(
            title: 'ボイス',
            value: _c.voiceVolume,
            min: 0,
            max: 1,
            label: '${(_c.voiceVolume * 100).round()}%',
            onChanged: (v) => _set(_c.copyWith(voiceVolume: v)),
          ),
          const Divider(color: Color(0xFF1D2A4A)),
          SwitchListTile(
            value: _c.skipReadOnly,
            onChanged: (v) => _set(_c.copyWith(skipReadOnly: v)),
            title: const Text('既読だけスキップする',
                style: TextStyle(fontSize: 14, color: Color(0xFFE8ECF1))),
            subtitle: const Text('まだ読んでいない話は飛ばしません',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF6A7280))),
          ),
          SwitchListTile(
            value: _c.reduceShake,
            onChanged: (v) => _set(_c.copyWith(reduceShake: v)),
            title: const Text('画面のゆれを弱める',
                style: TextStyle(fontSize: 14, color: Color(0xFFE8ECF1))),
            subtitle: const Text('ゆれで気分が悪くなる場合はこちら',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF6A7280))),
          ),
        ],
      ),
    );
  }

  Widget _slider({
    required String title,
    required double value,
    required double min,
    required double max,
    required String label,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF9FB4D8))),
              const Spacer(),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12.5, color: Color(0xFF7DFFB0))),
            ],
          ),
          Slider(value: value.clamp(min, max), min: min, max: max, onChanged: onChanged),
        ],
      ),
    );
  }
}
