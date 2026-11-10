import 'package:flutter/material.dart';

import '../../core/app_feedback.dart';
import '../../core/orientation.dart';
import '../../theory/lesson.dart';
import '../../widgets/app_route.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/glass_box.dart';
import '../practice/practice_screen.dart';

/// Màn chi tiết bài: mô tả, lý thuyết, lỗi thường gặp, rồi nút bắt đầu luyện.
class LessonDetailScreen extends StatelessWidget {
  final Lesson lesson;
  const LessonDetailScreen({super.key, required this.lesson});

  Future<void> _start(BuildContext context) async {
    AppFeedback.tap();
    await Navigator.push(
      context,
      appRoute<void>(PracticeScreen(lesson: lesson)),
    );
    // Màn luyện đã đổi sang ngang, nên trả về dọc khi quay lại.
    lockOrientation(kPortrait);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              title: Text(lesson.title, overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  if (lesson.description.isNotEmpty)
                    Text(lesson.description, style: theme.textTheme.bodyLarge),
                  if (lesson.theory.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _Section(title: 'Lý thuyết', items: lesson.theory),
                  ],
                  if (lesson.tips.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _Section(title: 'Lỗi thường gặp', items: lesson.tips),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    '${lesson.steps.length} bước luyện',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _start(context),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Bắt đầu luyện'),
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

class _Section extends StatelessWidget {
  final String title;
  final List<String> items;

  const _Section({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassBox(
      padding: const EdgeInsets.all(18),
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('• $item', style: theme.textTheme.bodyMedium),
            ),
        ],
      ),
    );
  }
}
