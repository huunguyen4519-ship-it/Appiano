import 'package:flutter/material.dart';

import '../../core/app_feedback.dart';
import '../../data/progress_store.dart';
import '../../theory/lessons.dart';
import '../../theory/notes.dart';
import '../../widgets/app_route.dart';
import '../../widgets/glass_app_bar.dart';
import '../../widgets/glass_box.dart';
import '../free_play/free_play_screen.dart';
import '../practice/practice_screen.dart';
import '../settings/settings_screen.dart';

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
    final stars = await ProgressStore.bestStars([for (final l in lessons) l.id]);
    if (mounted) setState(() => _stars = stars);
  }

  Future<void> _open(Widget page) async {
    AppFeedback.tap();
    await Navigator.push(context, appRoute<void>(page));
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GlassAppBar(
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
