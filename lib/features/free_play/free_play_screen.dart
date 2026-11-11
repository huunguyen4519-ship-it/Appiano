import 'package:flutter/material.dart';

import '../../core/app_feedback.dart';
import '../../core/audio.dart';
import '../../core/orientation.dart';
import '../../core/theme.dart';
import '../../theory/chords.dart';
import '../../widgets/app_route.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/glass_box.dart';
import '../keyboard/piano_keyboard.dart';
import '../settings/eq_panel.dart';
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

  // Bảng chỉnh EQ nhanh, không phải rời màn chơi đàn.
  void _openEq() {
    AppFeedback.tap();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: GlassBox(
            padding: const EdgeInsets.all(16),
            child: EqPanel(
              accent: AppThemeController.instance.accent.value,
              bandHeight: 150,
              showNote: false,
            ),
          ),
        ),
      ),
    );
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
                IconButton(
                  tooltip: 'Bộ chỉnh âm',
                  icon: const Icon(Icons.tune),
                  onPressed: _openEq,
                ),
                IconButton.filledTonal(
                  tooltip: 'Chơi hợp âm',
                  isSelected: _mode == PlayMode.chords,
                  icon: const Icon(Icons.library_music_outlined),
                  selectedIcon: const Icon(Icons.library_music),
                  onPressed: () {
                    AppFeedback.tap();
                    setState(() {
                      _mode = _mode == PlayMode.chords
                          ? PlayMode.single
                          : PlayMode.chords;
                    });
                  },
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
