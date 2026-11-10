import 'package:flutter/material.dart';

import '../../core/app_feedback.dart';
import '../../data/progress_store.dart';
import '../../theory/lessons.dart';
import '../../theory/notes.dart';
import '../../widgets/app_route.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/glass_box.dart';
import '../practice/practice_screen.dart';

/// Gom mọi chức năng học vào một màn hình: danh sách bài, số sao và vào bài tập.
class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  Map<String, int> _stars = {};

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final stars = await ProgressStore.bestStars([for (final l in lessons) l.id]);
    if (mounted) setState(() => _stars = stars);
  }

  Future<void> _open(Lesson lesson) async {
    AppFeedback.tap();
    await Navigator.push(
      context,
      appRoute<void>(PracticeScreen(lesson: lesson)),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(title: Text('Học đàn')),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  for (final lesson in lessons)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassBox(
                        padding: EdgeInsets.zero,
                        radius: 22,
                        onTap: () => _open(lesson),
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
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
