import 'package:flutter/material.dart';

import '../../core/app_feedback.dart';
import '../../core/orientation.dart';
import '../../data/progress_store.dart';
import '../../theory/lessons.dart';
import '../../widgets/app_route.dart';
import '../../widgets/glass_app_bar.dart';
import '../../widgets/glass_box.dart';
import '../free_play/free_play_screen.dart';
import '../learn/learn_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _done = 0;

  @override
  void initState() {
    super.initState();
    lockOrientation(kPortrait);
    _refresh();
  }

  Future<void> _refresh() async {
    final stars = await ProgressStore.bestStars([for (final l in lessons) l.id]);
    final done = stars.values.where((s) => s > 0).length;
    if (mounted) setState(() => _done = done);
  }

  Future<void> _open(Widget page) async {
    AppFeedback.tap();
    await Navigator.push(context, appRoute<void>(page));
    // Màn con có thể đã đổi hướng, nên đưa màn chính về dọc.
    lockOrientation(kPortrait);
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
            _ModeCard(
              icon: Icons.piano,
              title: 'Chơi đàn',
              subtitle: 'Bàn phím tự do và hợp âm. Không có bài.',
              onTap: () => _open(const FreePlayScreen()),
            ),
            const SizedBox(height: 16),
            _ModeCard(
              icon: Icons.school_outlined,
              title: 'Học đàn',
              subtitle: 'Đã hoàn thành $_done/${lessons.length} bài',
              onTap: () => _open(const LearnScreen()),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return GlassBox(
      radius: 30,
      padding: const EdgeInsets.all(24),
      onTap: onTap,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withValues(alpha: 0.25),
                border: Border.all(color: primary.withValues(alpha: 0.6)),
              ),
              child: Icon(icon, color: primary, size: 28),
            ),
            const SizedBox(height: 18),
            Text(title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(subtitle, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
