import 'package:flutter/material.dart';

import '../../core/audio.dart';
import '../../core/orientation.dart';
import '../../theory/chords.dart';
import '../../widgets/app_route.dart';
import '../../widgets/app_top_bar.dart';
import '../keyboard/piano_keyboard.dart';
import '../settings/settings_screen.dart';
import 'chord_bar.dart';

class FreePlayScreen extends StatefulWidget {
  const FreePlayScreen({super.key});

  @override
  State<FreePlayScreen> createState() => _FreePlayScreenState();
}

class _FreePlayScreenState extends State<FreePlayScreen> {
  PlayMode _mode = PlayMode.single;
  Set<int> _chordKeys = {};
  List<int> _chordTokens = [];

  @override
  void initState() {
    super.initState();
    // Bàn phím đầy đủ cần chiều ngang.
    lockOrientation(kLandscape);
  }

  @override
  void dispose() {
    _releaseChord();
    super.dispose();
  }

  void _releaseChord() {
    for (final t in _chordTokens) {
      PianoAudio.instance.noteOff(t);
    }
    _chordTokens = [];
  }

  // Nhấn giữ hợp âm: các nốt ngân cho tới khi nhấc tay.
  void _chordDown(Chord chord) {
    _releaseChord();
    _chordTokens = [for (final n in chord.notes) PianoAudio.instance.noteOn(n)];
    setState(() => _chordKeys = chord.notes.toSet());
  }

  void _chordUp() {
    _releaseChord();
    setState(() => _chordKeys = {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              title: const Text('Chơi đàn'),
              actions: [
                PopupMenuButton<PlayMode>(
                  tooltip: 'Chế độ bàn phím',
                  icon: const Icon(Icons.tune),
                  initialValue: _mode,
                  onSelected: (m) => setState(() => _mode = m),
                  itemBuilder: (_) => [
                    for (final m in PlayMode.values)
                      PopupMenuItem(value: m, child: Text(m.label)),
                  ],
                ),
                IconButton(
                  tooltip: 'Cài đặt',
                  icon: const Icon(Icons.palette_outlined),
                  onPressed: () => Navigator.push(
                    context,
                    appRoute<void>(const SettingsScreen()),
                  ),
                ),
              ],
            ),
            if (_mode == PlayMode.chords)
              ChordBar(onDown: _chordDown, onUp: _chordUp),
            Expanded(
              child: PianoKeyboard(onNote: (_) {}, highlight: _chordKeys),
            ),
          ],
        ),
      ),
    );
  }
}
