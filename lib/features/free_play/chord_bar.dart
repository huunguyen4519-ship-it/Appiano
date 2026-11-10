import 'package:flutter/material.dart';

import '../../core/app_feedback.dart';
import '../../theory/chords.dart';
import '../../widgets/glass_box.dart';

/// Dải nút kính hợp âm. Nhấn giữ thì hợp âm ngân, nhấc tay thì hợp âm tắt dần.
class ChordBar extends StatelessWidget {
  final ValueChanged<Chord> onDown;
  final VoidCallback onUp;

  const ChordBar({super.key, required this.onDown, required this.onUp});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        children: [
          for (final c in chordList)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
              child: Listener(
                onPointerDown: (_) {
                  AppFeedback.tap();
                  onDown(c);
                },
                onPointerUp: (_) => onUp(),
                onPointerCancel: (_) => onUp(),
                child: GlassBox(
                  radius: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Center(
                    child: Text(
                      c.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
