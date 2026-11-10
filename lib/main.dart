import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'audio.dart';
import 'keyboard.dart';
import 'lessons.dart';
import 'progress.dart';
import 'settings.dart';
import 'ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  // Ẩn thanh trạng thái và thanh điều hướng, để phần chơi đàn chiếm toàn màn hình.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await AppThemeController.instance.load();
  await PianoAudio.instance.load();
  runApp(const AppianoApp());
}

class AppianoApp extends StatelessWidget {
  const AppianoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: AppThemeController.instance.accent,
      builder: (context, accent, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Appiano',
          theme: buildTheme(accent),
          builder: (context, child) =>
              LiquidBackground(child: child ?? const SizedBox.shrink()),
          home: const HomeScreen(),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, int> _stars = {};

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final stars = await Progress.bestStars([for (final l in lessons) l.id]);
    if (mounted) setState(() => _stars = stars);
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appiano'),
        actions: [
          IconButton(
            tooltip: 'Cài đặt',
            icon: const Icon(Icons.palette_outlined),
            onPressed: () => _open(const SettingsScreen()),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final lesson in lessons)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassBox(
                  padding: EdgeInsets.zero,
                  onTap: () => _open(PracticeScreen(lesson: lesson)),
                  child: ListTile(
                    leading: Icon(
                      (_stars[lesson.id] ?? 0) > 0
                          ? Icons.check_circle
                          : Icons.music_note,
                    ),
                    title: Text(lesson.title),
                    subtitle: Text(lesson.description),
                    trailing: Text(
                      starsText(_stars[lesson.id] ?? 0),
                      style: const TextStyle(fontSize: 18, color: Colors.amber),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            GlassBox(
              padding: EdgeInsets.zero,
              onTap: () => _open(const FreePlayScreen()),
              child: const ListTile(
                leading: Icon(Icons.piano),
                title: Text('Chơi tự do'),
                subtitle: Text('Bàn phím, không có bài'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thanh điều khiển mỏng phía trên, dùng chung cho các màn hình chơi đàn.
class _TopBar extends StatelessWidget {
  final Widget title;
  final List<Widget> actions;

  const _TopBar({required this.title, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          IconButton(
            tooltip: 'Quay lại',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: DefaultTextStyle.merge(
              style: Theme.of(context).textTheme.titleMedium!,
              child: title,
            ),
          ),
          ...actions,
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
      body: SafeArea(
        child: Column(
          children: [
            const _TopBar(title: Text('Chơi tự do')),
            Expanded(child: PianoKeyboard(onNote: (_) {})),
          ],
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
  int _mistakes = 0;
  int? _wrong;
  bool _finished = false;

  List<int> get _notes => widget.lesson.notes;
  int get _target => _notes[_index];
  int get _finger => widget.lesson.fingers[_index];

  void _onNote(int midi) {
    if (_finished) return;
    if (midi == _target) {
      setState(() {
        _wrong = null;
        _index++;
      });
      if (_index >= _notes.length) _finish();
    } else {
      setState(() => _mistakes++);
      _flashWrong(midi);
    }
  }

  void _flashWrong(int midi) {
    setState(() => _wrong = midi);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted && _wrong == midi) setState(() => _wrong = null);
    });
  }

  // 0 sai: 3 sao. Sai 1-2 lần: 2 sao. Sai nhiều hơn: 1 sao.
  int get _starsEarned {
    if (_mistakes == 0) return 3;
    if (_mistakes <= 2) return 2;
    return 1;
  }

  void _finish() {
    setState(() => _finished = true);
    final stars = _starsEarned;
    unawaited(Progress.saveStars(widget.lesson.id, stars));
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hoàn thành!'),
        content: Text(
          '"${widget.lesson.title}"\n'
          '${starsText(stars)}   Sai $_mistakes lần',
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
    setState(() {
      _index = 0;
      _mistakes = 0;
      _wrong = null;
      _finished = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = _notes.length;
    final statusText = _finished
        ? '${widget.lesson.title} · Xong, sai $_mistakes lần'
        : '${widget.lesson.title} · ${noteName(_target)} · ngón $_finger · '
            '${_index + 1}/$total';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
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
              value: _finished ? 1 : _index / total,
              minHeight: 3,
            ),
            Expanded(
              child: PianoKeyboard(
                onNote: _onNote,
                highlight: _finished ? const {} : {_target},
                labels: _finished ? const {} : {_target: '$_finger'},
                wrong: _wrong,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
