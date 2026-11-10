import 'package:flutter/material.dart';

import '../../core/app_feedback.dart';
import '../../theory/chords.dart';
import '../../widgets/glass_box.dart';

/// Dải nút kính hợp âm. Bấm một nút sẽ phát các nốt của hợp âm cùng lúc.
class ChordBar extends StatelessWidget {
  final ValueChanged<Chord> onChord;
  const ChordBar({super.key, required this.onChord});

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
              child: GlassBox(
                radius: 20,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                onTap: () {
                  AppFeedback.tap();
                  onChord(c);
                },
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
        ],
      ),
    );
  }
}
