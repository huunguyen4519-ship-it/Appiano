import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_feedback.dart';
import '../../core/orientation.dart';
import '../../data/progress_store.dart';
import '../../theory/lesson.dart';
import '../../theory/notes.dart';
import '../../widgets/app_top_bar.dart';
import '../keyboard/piano_keyboard.dart';
import 'practice_session.dart';

class PracticeScreen extends StatefulWidget {
  final Lesson lesson;
  const PracticeScreen({super.key, required this.lesson});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  late final PracticeSession _session = PracticeSession(widget.lesson);
  int? _wrong;

  @override
  void initState() {
    super.initState();
    // Bài tập có bàn phím, dùng chiều ngang như màn chơi đàn.
    lockOrientation(kLandscape);
  }

  void _onNote(int midi) {
    final result = _session.press(midi);
    switch (result) {
      case PressResult.ignored:
        return;
      case PressResult.wrong:
        AppFeedback.wrong();
        setState(() => _wrong = midi);
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted && _wrong == midi) setState(() => _wrong = null);
        });
      case PressResult.correct:
        AppFeedback.correct();
        setState(() => _wrong = null);
        if (_session.finished) _finish();
    }
  }

  void _finish() {
    AppFeedback.done();
    final stars = _session.stars;
    unawaited(ProgressStore.saveStars(widget.lesson.id, stars));
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hoàn thành!'),
        content: Text(
          '"${widget.lesson.title}"\n'
          '${starsText(stars)}   Sai ${_session.mistakes} lần',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Quay lại'),
          ),
        ],
      ),
    );
  }

  void _restart() {
    AppFeedback.tap();
    setState(() {
      _session.restart();
      _wrong = null;
    });
  }

  String _statusText() {
    final title = widget.lesson.title;
    if (_session.finished) {
      return '$title · Xong, sai ${_session.mistakes} lần';
    }
    final names = (_session.targets.toList()..sort()).map(noteName).join(' + ');
    return '$title · $names · ${_session.index + 1}/${_session.total}';
  }

  @override
  Widget build(BuildContext context) {
    final finished = _session.finished;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              title: Text(_statusText(), overflow: TextOverflow.ellipsis),
              actions: [
                IconButton(
                  tooltip: 'Làm lại',
                  icon: const Icon(Icons.refresh),
                  onPressed: _restart,
                ),
              ],
            ),
            LinearProgressIndicator(
              value: finished ? 1 : _session.index / _session.total,
              minHeight: 3,
            ),
            Expanded(
              child: PianoKeyboard(
                onNote: _onNote,
                highlight: finished ? const <int>{} : _session.targets,
                labels: finished
                    ? const <int, String>{}
                    : _session.fingerLabels,
                wrong: _wrong,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
