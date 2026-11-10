import 'package:flutter/material.dart';

import '../../core/app_feedback.dart';
import '../../theory/chords.dart';

/// Dải nút hợp âm. Bấm một nút sẽ phát các nốt của hợp âm cùng lúc.
class ChordBar extends StatelessWidget {
  final ValueChanged<Chord> onChord;
  const ChordBar({super.key, required this.onChord});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          for (final c in chordList)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: FilledButton.tonal(
                onPressed: () {
                  AppFeedback.tap();
                  onChord(c);
                },
                child: Text(c.name),
              ),
            ),
        ],
      ),
    );
  }
}
