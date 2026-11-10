import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/app_feedback.dart';
import '../../core/orientation.dart';
import '../../data/lesson_store.dart';
import '../../data/progress_store.dart';
import '../../theory/lesson.dart';
import '../../theory/lesson_format.dart';
import '../../theory/lessons.dart';
import '../../theory/lesson.dart';
import '../../theory/midi_reader.dart';
import '../../theory/notes.dart';
import '../../widgets/app_route.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/glass_box.dart';
import 'lesson_detail_screen.dart';

/// Gom mọi chức năng học vào một màn hình: giáo trình, bài nạp từ file, số sao.
class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  Map<String, int> _stars = {};
  List<Lesson> _imported = [];

  @override
  void initState() {
    super.initState();
    lockOrientation(kPortrait);
    _refresh();
  }

  Future<void> _refresh() async {
    final imported = await LessonStore.load();
    final stars = await ProgressStore.bestStars([
      for (final l in lessons) l.id,
      for (final l in imported) l.id,
    ]);
    if (mounted) {
      setState(() {
        _stars = stars;
        _imported = imported;
      });
    }
  }

  Future<void> _open(Lesson lesson) async {
    AppFeedback.tap();
    await Navigator.push(
      context,
      appRoute<void>(LessonDetailScreen(lesson: lesson)),
    );
    lockOrientation(kPortrait);
    _refresh();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _import() async {
    AppFeedback.tap();
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'mid', 'midi'],
      withData: true,
    );
    final file = picked?.files.single;
    if (file == null) return;
    final bytes = file.bytes;
    if (bytes == null) {
      _toast('Không đọc được file này.');
      return;
    }
    final id = 'imp-${DateTime.now().microsecondsSinceEpoch}';
    try {
      final Lesson lesson;
      if (file.name.toLowerCase().endsWith('.json')) {
        lesson = lessonFromJsonText(utf8.decode(bytes), id: id);
      } else {
        final title = file.name.replaceFirst(
          RegExp(r'\.(mid|midi)$', caseSensitive: false),
          '',
        );
        lesson = lessonFromMidi(bytes, id: id, title: title);
      }
      await LessonStore.add(lesson);
      _toast('Đã nạp: ${lesson.title}');
      _refresh();
    } on FormatException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _confirmDelete(Lesson lesson) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa bài này?'),
        content: Text('"${lesson.title}" sẽ bị xóa khỏi máy.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await LessonStore.remove(lesson.id);
    _refresh();
  }

  Widget _card(Lesson lesson, {bool deletable = false}) {
    final stars = _stars[lesson.id] ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassBox(
        padding: EdgeInsets.zero,
        radius: 22,
        onTap: () => _open(lesson),
        child: ListTile(
          leading: Icon(stars > 0 ? Icons.check_circle : Icons.music_note),
          title: Text(lesson.title),
          subtitle: Text(lesson.description),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                starsText(stars),
                style: const TextStyle(fontSize: 16, color: Colors.amber),
              ),
              if (deletable)
                IconButton(
                  tooltip: 'Xóa',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(lesson),
                ),
            ],
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
              title: const Text('Học đàn'),
              actions: [
                IconButton(
                  tooltip: 'Nạp bài từ file',
                  icon: const Icon(Icons.file_open_outlined),
                  onPressed: _import,
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  const _SectionTitle('Giáo trình'),
                  for (final lesson in lessons) _card(lesson),
                  if (_imported.isNotEmpty) ...[
                    const _SectionTitle('Bài nạp từ file'),
                    for (final lesson in _imported)
                      _card(lesson, deletable: true),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
