import 'package:flutter/material.dart';

/// Chế độ bàn phím. Hai hàng và hai người chơi sẽ làm sau.
enum PlayMode {
  single('Một hàng'),
  chords('Hợp âm');

  final String label;
  const PlayMode(this.label);
}

class Chord {
  final String name;
  final List<int> notes;
  const Chord(this.name, this.notes);
}

/// Bảy hợp âm trong điệu Đô trưởng, quãng tám 4 (C4 = 60).
const List<Chord> chordList = [
  Chord('C', [60, 64, 67]),
  Chord('Dm', [62, 65, 69]),
  Chord('Em', [64, 67, 71]),
  Chord('F', [65, 69, 72]),
  Chord('G', [67, 71, 74]),
  Chord('Am', [69, 72, 76]),
  Chord('Bdim', [71, 74, 77]),
];

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
                onPressed: () => onChord(c),
                child: Text(c.name),
              ),
            ),
        ],
      ),
    );
  }
}
