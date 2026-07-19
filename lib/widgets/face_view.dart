import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/person.dart';

/// 人物の顔を種類（SVG/画像アセット/アップロード写真）に応じて描画するウィジェット。
/// 写真は角丸でクロップして表示する。
class FaceView extends StatelessWidget {
  final Person person;
  final double size;
  final double radius;

  const FaceView({
    super.key,
    required this.person,
    required this.size,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    switch (person.kind) {
      case FaceKind.svg:
        return SvgPicture.asset(person.face, width: size, height: size);
      case FaceKind.asset:
        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.asset(
            person.face,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallback(),
          ),
        );
      case FaceKind.file:
        if (kIsWeb) return _fallback();
        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.file(
            File(person.face),
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallback(),
          ),
        );
    }
  }

  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(Icons.person, size: size * 0.6, color: const Color(0xFF8FB4DC)),
    );
  }
}
