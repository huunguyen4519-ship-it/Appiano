import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'audio.dart';
import 'keyboard.dart';
import 'lessons.dart';
import 'progress.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await PianoAudio.instance.load();
  runApp(const AppianoApp());
}

class AppianoApp extends StatelessWidget {
  const AppianoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Appiano',
      theme: ThemeData.dark(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Set<String> _done = {};

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final done = await Progress.completed();
    if (mounted) setState(() => _done = done);
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appiano')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final lesson in lessons)
            Card(
              child: ListTile(
                leading: Icon(
                  _done.contains(lesson.id)
                      ? Icons.check_circle
                      : Icons.music_note,
                ),
                title: Text(lesson.title),
                subtitle: Text(lesson.description),
                onTap: () => _open(PracticeScreen(lesson: lesson)),
              ),
            ),
          const Divider(height: 32),
          Card(
            child: ListTile(
              leading: const Icon(Icons.piano),
              title: const Text('Chơi tự do'),
              subtitle: const Text('Bàn phím, không có bài'),
              onTap: () => _open(const FreePlayScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class FreePlayScreen extends StatelessWidget {
  const FreePlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chơi tự do')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: PianoKeyboard(onNote: (_) {}),
        ),
      ),
    );
  }
}

class PracticeScreen extends StatefulWidget {
  final Lesson lesson;
  const PracticeScreen({super.key, required this.lesson});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  int _index = 0;
  int? _wrong;
  bool _finished = false;

  List<int> get _notes => widget.lesson.notes;
  int get _target => _notes[_index];

  void _onNote(int midi) {
    if (_finished) return;
    if (midi == _target) {
      setState(() {
        _wrong = null;
        _index++;
      });
      if (_index >= _notes.length) _finish();
    } else {
      _flashWrong(midi);
    }
  }

  void _flashWrong(int midi) {
    setState(() => _wrong = midi);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted && _wrong == midi) setState(() => _wrong = null);
    });
  }

  void _finish() {
    setState(() => _finished = true);
    unawaited(Progress.markCompleted(widget.lesson.id));
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hoàn thành!'),
        content: Text('Bạn đã xong "${widget.lesson.title}".'),
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
    setState(() {
      _index = 0;
      _wrong = null;
      _finished = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = _notes.length;
    final statusText = _finished
        ? 'Xong!'
        : 'Nốt tiếp theo: ${noteName(_target)}   ($_index / $total)';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
        actions: [
          IconButton(
            tooltip: 'Làm lại',
            icon: const Icon(Icons.refresh),
            onPressed: _restart,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Text(statusText, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: _index / total),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: PianoKeyboard(
                  onNote: _onNote,
                  highlight: _finished ? const {} : {_target},
                  wrong: _wrong,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
