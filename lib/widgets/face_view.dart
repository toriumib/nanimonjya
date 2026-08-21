import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/avatar.dart';
import '../models/person.dart';
import 'avatar_view.dart';

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
      // 🧑‍🎨 顔メモのアバター。画像ではなくコードで描くので、
      //    Web でもファイルの有無に関係なく必ず表示できる。
      case FaceKind.avatar:
        return AvatarView(
          avatar: Avatar.decode(person.face),
          size: size,
          radius: radius,
        );
      case FaceKind.svg:
        return SvgPicture.asset(person.face, width: size, height: size);
      case FaceKind.asset:
        // Webからアップロードした写真（http/blob URL）はImage.networkで表示
        if (_isWebUrl(person.face)) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Image.network(
              person.face,
              width: size, height: size, fit: BoxFit.cover,
              cacheWidth: _decodePx(context, size),
              errorBuilder: (_, __, ___) => _fallback(),
            ),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.asset(
            person.face,
            width: size,
            height: size,
            fit: BoxFit.cover,
            // 🧠 表示する大きさで復号する。
            //    指定しないと**元の解像度のまま**メモリに展開されるので、
            //    64pxのサムネイルでも1枚あたり数MBを食う。
            //    キャラデッキやショップは顔を数十枚並べるので、
            //    ここが効かないとヒープ上限（192MB）に届く。
            cacheWidth: _decodePx(context, size),
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
            // 顔メモの写真はカメラ由来で大きい（数千px）ことがあるので、
            // アセット以上にここが効く。
            cacheWidth: _decodePx(context, size),
            errorBuilder: (_, __, ___) => _fallback(),
          ),
        );
    }
  }

  bool _isWebUrl(String path) =>
      path.startsWith('http://') || path.startsWith('https://') || path.startsWith('blob:');

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

/// 表示サイズ（論理px）から、復号に使う実ピクセル数を出す。
///
/// 端末の画素密度ぶんは必要なので掛けるが、上限を設けて
/// 「大きい端末だからと原寸に近づく」ことは防ぐ。
int _decodePx(BuildContext context, double logicalSize) {
  final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;
  final px = (logicalSize * dpr).round();
  return px.clamp(64, 640);
}
