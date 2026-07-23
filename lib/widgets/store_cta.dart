import 'package:flutter/material.dart';

import '../l10n/meta_strings.dart';
import '../screens/character_shop_screen.dart';
import '../services/sfx.dart';

/// 試合・特訓のあとに出す「新しいキャラを仲間にしよう→ショップ」への誘導カード。
class StoreCtaCard extends StatelessWidget {
  const StoreCtaCard({super.key});

  @override
  Widget build(BuildContext context) {
    final m = MetaStrings.of(context);
    return GestureDetector(
      onTap: () {
        Sfx.instance.pop();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CharacterShopScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFB84D), Color(0xFFFF7DA8)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF7DA8).withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.ctaNewCharTitle,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(m.ctaNewCharDesc,
                      style: const TextStyle(
                          fontSize: 11.5, color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(m.ctaToShop,
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFE8663C))),
            ),
          ],
        ),
      ),
    );
  }
}
