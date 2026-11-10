import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/audio.dart';
import '../../core/settings_store.dart';
import '../../theory/chords.dart';
import '../../widgets/app_route.dart';
import '../../widgets/app_top_bar.dart';
import '../keyboard/keyboard_palette.dart';
import '../keyboard/piano_keyboard.dart';
import '../settings/settings_screen.dart';
import 'chord_bar.dart';

/// Nền than đậm của màn Chơi tự do.
const Color _charcoal = Color(0xFF111114);

class FreePlayScreen extends StatefulWidget {
  const FreePlayScreen({super.key});

  @override
  State<FreePlayScreen> createState() => _FreePlayScreenState();
}

class _FreePlayScreenState extends State<FreePlayScreen> {
  PlayMode _mode = PlayMode.single;
  Set<int> _chordKeys = {};
  Timer? _chordTimer;

  @override
  void dispose() {
    _chordTimer?.cancel();
    super.dispose();
  }

  void _playChord(Chord chord) {
    for (final n in chord.notes) {
      PianoAudio.instance.playNote(n);
    }
    _chordTimer?.cancel();
    setState(() => _chordKeys = chord.notes.toSet());
    _chordTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _chordKeys = {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = SettingsStore.instance;
    return Scaffold(
      body: ColoredBox(
        color: _charcoal,
        child: SafeArea(
          child: Column(
            children: [
              AppTopBar(
                title: const Text('Chơi tự do'),
                actions: [
                  ValueListenableBuilder<bool>(
                    valueListenable: store.labelsVisible,
                    builder: (context, shown, _) => IconButton(
                      tooltip: shown ? 'Ẩn nhãn nốt' : 'Hiện nhãn nốt',
                      icon: Icon(
                        shown ? Icons.visibility : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => store.setLabelsVisible(!shown),
                    ),
                  ),
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
              if (_mode == PlayMode.chords) ChordBar(onChord: _playChord),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: PianoKeyboard(
                    onNote: (_) {},
                    highlight: _chordKeys,
                    palette: charcoalPalette,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
