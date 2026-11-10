import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_feedback.dart';
import '../../data/progress_store.dart';
import '../../theory/lessons.dart';
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
    setState(() {});
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

  @override
  Widget build(BuildContext context) {
    final finished = _session.finished;
    final statusText = finished
        ? '${widget.lesson.title} · Xong, sai ${_session.mistakes} lần'
        : '${widget.lesson.title} · ${noteName(_session.target)} · '
            'ngón ${_session.finger} · ${_session.index + 1}/${_session.total}';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              title: Text(statusText, overflow: TextOverflow.ellipsis),
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
                highlight: finished ? const {} : {_session.target},
                labels: finished
                    ? const {}
                    : {_session.target: '${_session.finger}'},
                wrong: _wrong,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
